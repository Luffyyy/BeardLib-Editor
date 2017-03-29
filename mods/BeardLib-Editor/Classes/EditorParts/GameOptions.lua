GameOptions = GameOptions or class(EditorPart)
function GameOptions:init(parent, menu)
    self.super.init(self, parent, menu, "Options")    
    self._wanted_elements = {}
end

function GameOptions:build_default_menu()
    self.super.build_default_menu(self)
    local level =  "/" .. (Global.game_settings.level_id or "")
    self:Divider("Basic", self._menu.highlight_color)
    self._current_continent = self:ComboBox("CurrentContinent", callback(self, self, "set_current_continent"))
    self._current_script = self:ComboBox("CurrentScript", callback(self, self, "set_current_continent"))
    self:Slider("CameraSpeed", callback(self, self, "update_option_value"), self:Value("CameraSpeed"), {max = 10, min = 0, step = 0.1})
    self:Slider("GridSize", callback(self._parent, self._parent, "update_grid_size"), 1, {max = 10000, min = 0.1, help = "Sets the amount(in centimeters) that the unit will move"})
    self:Slider("SnapRotation", callback(self._parent, self._parent, "update_snap_rotation"), 90, {max = 360, min = 1, help = "Sets the amount(in degrees) that the unit will rotate"})
    
    self:Divider("Map", self._menu.highlight_color)
    if not BeardLib.current_level then
        self:TextBox("MapSavePath", nil, BeardLib.config.maps_dir .. level)
    end
    self:Toggle("EditorUnits", callback(self, self, "set_editor_units_visible"), self:Value("EditorUnits"))
    self:Toggle("HighlightUnits", callback(self, self, "update_option_value"), self:Value("HighlightUnits"))
    self:Toggle("ShowElements", callback(self, self, "update_option_value"), self:Value("ShowElements"))
    self:Toggle("DrawPortals", nil, false, {text = "Draw Portals"})
    self:Divider("NavigationDebug", {text = "Navigation Debug[Toggle what to draw]"})
    local group = self:Group("Draw", {use_as_menu = true, align_method = "grid"})
    local items = { 
        quads = false,
        doors = false,
        blockers = false,
        vis_graph = false,
        coarse_graph = false,
        nav_links = false,
        covers = false,
    }
    self._draw_options = {}
    for k, v in pairs(items) do
        self._draw_options[k] = self:Toggle(k, callback(self, self, "draw_nav_segments"), v, {size_by_text = true, items_size = 14, group = group})
    end
    self:Divider("Other", self._menu.highlight_color)
    self:Button("TeleportPlayer", callback(self, self, "drop_player"))
    self:Button("LogPosition", callback(self, self, "position_debug"))
    self:Button("ClearMassUnit", callback(self, self, "clear_massunit"))
    self:Button("BuildNavigationData", callback(self, self, "build_nav_segments"), {enabled = self._parent._has_fix})
    self:Button("SaveNavigationData", callback(self, self, "save_nav_data"), {enabled = self._parent._has_fix})
    self:Button("SaveCoverData", callback(self, self, "save_cover_data"))
    self:Toggle("PauseGame", callback(self, self, "pause_game"), false)  
end

function GameOptions:loaded_continents(continents, current_continent)
    self._current_continent:SetItems(continents)
    self._current_continent:SetSelectedItem(current_continent)   
    self._current_script:SetItems(table.map_keys(managers.mission._scripts))
    self._current_script:SetValue(1)
end

function GameOptions:update_option_value(menu, item)
    BeardLibEditor.Options:SetValue("Map/"..item.name, item:Value())
    if item.name == "ShowElements" then
        self:Manager("mission"):set_elements_vis()
    end
end

function GameOptions:pause_game(menu, item)
    Application:set_pause(item.value)
end

function GameOptions:set_current_continent(menu, item)
    self._parent._current_continent = item:SelectedItem()
end

function GameOptions:set_current_script(menu, item)
    self._parent._current_script = item:SelectedItem()
end

function GameOptions:set_editor_units_visible(menu, item)
    self:update_option_value(meun, item)
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
			unit:set_visible(self._menu:GetItem("EditorUnits"):Value())
		end
	end
end

function GameOptions:draw_nav_segments(menu, item)
    if managers.navigation then
        managers.navigation:set_debug_draw_state(self._draw_options)
    end
end

function GameOptions:drop_player()
	game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0))
end

function GameOptions:position_debug()
    BeardLibEditor:log("Camera Position: %s", tostring(self._parent._camera_pos))
	BeardLibEditor:log("Camera Rotation: %s", tostring(self._parent._camera_rot))
end

function GameOptions:clear_massunit()
    BeardLibEditor.Utils:YesNoQuestion("This will clear the MassUnits in the world", function()
        MassUnitManager:delete_all_units()
    end)
end

function GameOptions:update(t, dt)
    if self:Value("HighlightUnits") and managers.viewport:get_current_camera() then
        for _, body in ipairs(World:find_bodies("intersect", "sphere", self._parent._camera_pos, 2500)) do
            if self._parent:_should_draw_body(body) then
                self._pen:set(Color.white)
                self._pen:body(body)
            end
        end
	end
    local draw_portals = self._menu:GetItem("draw_portals")
	if draw_portals and draw_portals.value then
		for _, portal in pairs(managers.portal:unit_groups()) do
			portal:draw(t, dt, 0.5, false, true)
		end
	end
end

function GameOptions:map_path()
    return BeardLibEditor.managers.MapProject:current_path() or self._menu:GetItem("MapSavePath"):Value():gsub("\\" , "/") 
end

function GameOptions:map_world_path()    
    local map_path = BeardLibEditor.managers.MapProject:current_level_path() or BeardLib.Utils.Path:Combine(self:map_path(), Global.game_settings.level_id)
    if not FileIO:Exists(map_path) then
        FileIO:MakeDir(path)
    end
    return map_path
end

function GameOptions:save()
    local xml = "generic_xml"
    local cusxml = "custom_xml"
    local include = {
        {_meta = "file", file = "world.world", type = xml},
        {_meta = "file", file = "continents.continents", type = cusxml},
        {_meta = "file", file = "mission.mission", type = cusxml},
        {_meta = "file", file = "nav_manager_data.nav_data", type = xml},
        {_meta = "file", file = "cover_data.cover_data", type = cusxml},
        {_meta = "file", file = "world_sounds.world_sounds", type = cusxml},
    }
    local worlddef = managers.worlddefinition
    local path = self:map_path()
    if FileIO:Exists(path) then
        local backups_dir = BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, "backups")
        if not FileIO:Exists(backups_dir) then
            FileIO:MakeDir(backups_dir)
        end
        local backup_dir = BeardLib.Utils.Path:Combine(backups_dir, table.remove(string.split(path, "/")))
        if FileIO:Exists(backup_dir) then
            FileIO:Delete(backup_dir)
        end
        FileIO:CopyTo(path, backup_dir)
    else
        FileIO:MakeDir(path)
    end
    local map_path = self:map_world_path()
    self:SaveData(map_path, "world.world", FileIO:ConvertToScriptData(worlddef._world_data, xml))
    local continents = {}
    local missions = {}
    for name, data in pairs(worlddef._continent_definitions) do
        local dir = BeardLib.Utils.Path:Combine(map_path, name)
        local continent_file = name .. ".continent"
        local mission_file = name .. ".mission"
        table.insert(include, {_meta = "file", file = name.."/"..continent_file, type = cusxml})
        table.insert(include, {_meta = "file", file = name.."/"..mission_file, type = xml})
        self:SaveData(dir, continent_file, FileIO:ConvertToScriptData(data, cusxml))
        self:SaveData(dir, mission_file, FileIO:ConvertToScriptData(managers.mission._missions[name], xml))
        continents[name] = {name = name, editor_only = (name == "editor_only")} --later make an option
        missions[name] = {file = BeardLib.Utils.Path:Combine(name, name)}
    end
    self:SaveData(map_path, "continents.continents", FileIO:ConvertToScriptData(continents, cusxml))
    self:SaveData(map_path, "mission.mission", FileIO:ConvertToScriptData(missions, cusxml))
    self:SaveData(map_path, "world_sounds.world_sounds", FileIO:ConvertToScriptData(worlddef._sound_data, cusxml))
    self:save_cover_data()    
    for _, folder in pairs(FileIO:GetFolders(map_path)) do
        if not worlddef._continent_definitions[folder] then
            FileIO:Delete(BeardLib.Utils.Path:Combine(map_path, folder))
        end
    end
    local proj = BeardLibEditor.managers.MapProject
    local map_mod = proj:current_mod()
    local data = map_mod and proj:get_clean_data(map_mod._clean_config)
    if data then
        local level = proj:get_level_by_id(data, Global.game_settings.level_id)
        include.directory = level.include.directory
        level.include = include
        FileIO:WriteScriptDataTo(map_mod:GetRealFilePath(BeardLib.Utils.Path:Combine(path, "main.xml")), data, "custom_xml")
    end
end

function GameOptions:SaveData(path, file_name, data)
    if not FileIO:Exists(path) then
        FileIO:MakeDir(path)
    end
    self._parent:Log("Saving script data '%s' in %s", file_name, path)
    FileIO:WriteTo(BeardLib.Utils.Path:Combine(path, file_name), data)
end

function GameOptions:save_nav_data()    
    local path = self:map_world_path()
    if managers.navigation:get_save_data() and managers.navigation._load_data then
        self:SaveData(path, "nav_manager_data.nav_data", managers.navigation._load_data)
    else
        self._parent:Log("Save data is not ready!")
    end
end

function GameOptions:save_cover_data()
    local path = self:map_world_path()
    local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))
    local covers = {
        positions = {},
        rotations = {}
    }
    for i, unit in pairs(all_cover_units) do
        local pos = Vector3()
        unit:m_position(pos)
        mvector3.set_static(pos, math.round(pos.x), math.round(pos.y), math.round(pos.z))
        table.insert(covers.positions, pos)
        local rot = unit:rotation()
        table.insert(covers.rotations, math.round(rot:yaw()))
    end
    self:SaveData(path, "cover_data.cover_data", FileIO:ConvertToScriptData(covers, "custom_xml"))
end

function GameOptions:build_nav_segments() -- Add later the options to the menu
    BeardLibEditor.Utils:YesNoQuestion("This will disable the player and AI and build the nav data proceed?", function()
        local settings = {}
        local units = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                table.insert(units, unit)
            end
        end
        for _, unit in ipairs(units) do
            local ray = World:raycast(unit:position() + Vector3(0, 0, 50), unit:position() - Vector3(0, 0, 150), nil, managers.slot:get_mask("all"))
            if ray and ray.position then
                table.insert(settings, {
                    position = unit:position(),
                    id = unit:editor_id(),
                    color = Color(),
                    location_id = unit:ai_editor_data().location_id
                })
            end
        end
        if #settings > 0 then
            local SE = self:Manager("static")
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:in_slot(managers.slot:get_mask("persons"))   then
                    unit:set_enabled(false)
                    if unit:brain() then
                       unit:brain()._current_logic.update = nil
                    end
                    if SE._disabled_units then
                        table.insert(SE._disabled_units, unit)
                    end
                    for _, extension in pairs(unit:extensions()) do
                        unit:set_extension_update_enabled(Idstring(extension), false)
                    end
                end
            end
            managers.navigation:clear()
            managers.navigation:build_nav_segments(settings, callback(self, self, "build_visibility_graph"))
        else
            self._parent:Log("No nav surface found.")
        end       
    end)
end

function GameOptions:build_visibility_graph()
    local all_visible = true
    local exclude, include
    if not all_visible then
        exclude = {}
        include = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                exclude[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_exlude_filter
                include[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_include_filter
            end
        end
    end
    local ray_lenght = 150
    managers.navigation:build_visibility_graph(callback(self, self, "_finish_visibility_graph"), all_visible, exclude, include, ray_lenght)
end

function GameOptions:_finish_visibility_graph(menu, item)
    managers.groupai:set_state("none")
end
