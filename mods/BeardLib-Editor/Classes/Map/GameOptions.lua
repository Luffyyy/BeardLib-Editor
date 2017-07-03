GameOptions = GameOptions or class(EditorPart)
function GameOptions:init(parent, menu)
    self.super.init(self, parent, menu, "Options")    
    self._wanted_elements = {}
end

function GameOptions:build_default_menu()
    self.super.build_default_menu(self)
    local groups_opt = {offset = {8, 4}}
    local main = self:DivGroup("Main", groups_opt)
    self._current_continent = self:ComboBox("CurrentContinent", callback(self, self, "set_current_continent"), nil, nil, {group = main})
    self._current_script = self:ComboBox("CurrentScript", callback(self, self, "set_current_continent"), nil, nil, {group = main})
    self:Button("AccentColor", callback(self, self, "open_set_color_dialog", "AccentColor"), {group = main})
    local grid_size = self:Value("GridSize")
    local snap_rotation = self:Value("SnapRotation")
    self:Slider("CameraSpeed", callback(self, self, "update_option_value"), self:Value("CameraSpeed"), {max = 10, min = 0, step = 0.1, group = main})
    self:Slider("GridSize", callback(self, self, "update_option_value"), grid_size, {max = 10000, min = 0.1, help = "Sets the amount(in centimeters) that the unit will move", group = main})
    self:Slider("SnapRotation", callback(self, self, "update_option_value"), snap_rotation, {max = 360, min = 1, help = "Sets the amount(in degrees) that the unit will rotate", group = main})
    self._parent:update_grid_size(grid_size)
    self._parent:update_snap_rotation(snap_rotation)
    local map = self:DivGroup("Map", groups_opt)
    if not BeardLib.current_level then
        self:TextBox("MapSavePath", nil, BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, Global.game_settings.level_id or ""), {group = main})
    end
    self:Toggle("SaveMapFilesInBinary", callback(self, self, "update_option_value"), self:Value("SaveMapFilesInBinary"), {group = map, help = "Saving your map files in binary cuts down in map file size which is highly recommended for release!"})
    self:Toggle("EditorUnits", callback(self, self, "update_option_value"), self:Value("EditorUnits"), {group = map, help = "Draw editro units"})
    self:Toggle("EnvironmentUnits", callback(self, self, "update_option_value"), self:Value("EnvironmentUnits"), {group = map, help = "Draw environment units"})
    self:Toggle("HighlightUnits", callback(self, self, "update_option_value"), self:Value("HighlightUnits"), {group = map})
    self:Toggle("ShowElements", callback(self, self, "update_option_value"), self:Value("ShowElements"), {group = map})
    self:Toggle("DrawOnlyElementsOfCurrentScript", callback(self, self, "update_option_value"), self:Value("DrawOnlyElementsOfCurrentScript"), {group = map})
    self:Toggle("DrawBodies", callback(self, self, "update_option_value"), self:Value("DrawBodies"), {group = map})
    self:Toggle("DrawPortals", nil, false, {text = "Draw Portals", group = map})

    local navigation_debug = self:DivGroup("NavigationDebug", {text = "Navigation Debug[Toggle what to draw]", offset = groups_opt.offset})
    local group = self:Menu("Draw", {align_method = "grid", group = navigation_debug})
    self._draw_options = {}
    local w = group.w / 3
    for _, opt in pairs({"quads", "doors", "blockers", "vis_graph", "coarse_graph", "nav_links", "covers"}) do
        self._draw_options[opt] = self:Toggle(opt, callback(self, self, "draw_nav_segments"), false, {w = w, items_size = 15, offset = 0, group = group})
    end
    local raycast = self:DivGroup("Raycast", groups_opt)
    self:Toggle("IgnoreFirstRaycast", nil, false, {group = raycast})
    self:Toggle("SelectEditorGroups", nil, false, {group = raycast})
    self:Toggle("SelectInstances", self:Value("SelectInstances"), false, {group = raycast})

    local mission = self:DivGroup("Mission", groups_opt)
    self:Toggle("RandomizedElementsColor", callback(self, self, "update_option_value"), self:Value("RandomizedElementsColor"), {group = mission})
    self:Button("ElementsColor", callback(self, self, "open_set_color_dialog", "Map/ElementsColor"), {group = mission})

    local other = self:DivGroup("Other", groups_opt)
    self:Button("TeleportPlayer", callback(self, self, "drop_player"), {group = other})
    self:Button("LogPosition", callback(self, self, "position_debug"), {group = other})
    self:Button("BuildNavigationData", callback(self, self, "build_nav_segments"), {enabled = self._parent._has_fix, group = other})
    self:Button("SaveNavigationData", callback(self, self, "save_nav_data", false), {enabled = self._parent._has_fix, group = other})
    self:Button("SaveCoverData", callback(self, self, "save_cover_data", false), {group = other})
    self:Toggle("PauseGame", callback(self, self, "pause_game"), false, {group = other})
end

function GameOptions:enable()
    self:bind_opt("SaveMap", callback(self, self, "KeySPressed"))
end

function GameOptions:KeySPressed()
    if ctrl() then
        self:save()
    end
end

function GameOptions:open_set_color_dialog(option)
    BeardLibEditor.managers.ColorDialog:Show({color = BeardLibEditor.Options:GetValue(option), callback = function(color)
        BeardLibEditor.Options:SetValue(option, color)
        BeardLibEditor.Options:Save()
    end})
end

function GameOptions:loaded_continents(continents, current_continent)
    self._current_continent:SetItems(continents)
    self._current_continent:SetSelectedItem(current_continent)   
    self._current_script:SetItems(table.map_keys(managers.mission._scripts))
    self._current_script:SetValue(1)
end

function GameOptions:update_option_value(menu, item)
    local name = item.name
    BeardLibEditor.Options:SetValue("Map/"..name, item:Value())
    if item.name == "ShowElements" then
        self:Manager("mission"):set_elements_vis()
    end
    if name == "EditorUnits" then
        for _, unit in pairs(World:find_units_quick("all")) do
            if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
                unit:set_visible(self._menu:GetItem("EditorUnits"):Value())
            end
        end
    elseif name == "GridSize" then
        self._parent:update_grid_size(item:Value())
    elseif name == "SnapRotation" then
        self._parent:update_snap_rotation(item:Value())
    elseif name == "DrawOnlyElementsOfCurrentScript" then
        self:Manager("mission"):set_elements_vis()
    end
end

function GameOptions:get_value(opt)
    local item = self:GetItem(opt)
    return item and item:Value()
end

function GameOptions:pause_game(menu, item)
    Application:set_pause(item.value)
end

function GameOptions:set_current_continent(menu, item)
    self._parent._current_continent = item:SelectedItem()
end

function GameOptions:set_current_script(menu, item)
    self._parent._current_script = item:SelectedItem()
    self:Manager("mission"):set_elements_vis()
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

function GameOptions:update(t, dt)
    self.super.update(self, t, dt)
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
    local map_path = BeardLibEditor.managers.MapProject:current_level_path() or self:map_path()
    if not FileIO:Exists(map_path) then
        FileIO:MakeDir(map_path)
    end
    return map_path
end

function GameOptions:save()
    if self._saving then
        return
    end
    self._saving = true
    local save_in_binary = self:Value("SaveMapFilesInBinary")
    local xml = save_in_binary and "binary" or "generic_xml"
    local cusxml = save_in_binary and "binary" or "custom_xml"
    local include = {
        {_meta = "file", file = "world.world", type = xml},
        {_meta = "file", file = "continents.continents", type = cusxml},
        {_meta = "file", file = "mission.mission", type = cusxml},
        {_meta = "file", file = "nav_manager_data.nav_data", type = xml},
        {_meta = "file", file = "world_sounds.world_sounds", type = cusxml},
        {_meta = "file", file = "world_cameras.world_cameras", type = cusxml}
    }
    local worlddef = managers.worlddefinition
    local path = self:map_path()
    local function save()
        local map_path = self:map_world_path()
        self:SaveData(map_path, "world.world", FileIO:ConvertToScriptData(worlddef._world_data, xml))
        local missions = {}
        for name, data in pairs(worlddef._continent_definitions) do
            local dir = BeardLib.Utils.Path:Combine(map_path, name)
            local continent_file = name .. ".continent"
            local mission_file = name .. ".mission"
            table.insert(include, {_meta = "file", file = name.."/"..continent_file, type = cusxml})
            table.insert(include, {_meta = "file", file = name.."/"..mission_file, type = xml})
            self:SaveData(dir, continent_file, FileIO:ConvertToScriptData(data, cusxml))
            self:SaveData(dir, mission_file, FileIO:ConvertToScriptData(managers.mission._missions[name], xml))
            missions[name] = {file = BeardLib.Utils.Path:Combine(name, name)}
        end
        self:SaveData(map_path, "continents.continents", FileIO:ConvertToScriptData(worlddef._continents, cusxml))
        self:SaveData(map_path, "mission.mission", FileIO:ConvertToScriptData(missions, cusxml))
        self:SaveData(map_path, "world_sounds.world_sounds", FileIO:ConvertToScriptData(worlddef._sound_data or {}, cusxml))
        self:SaveData(map_path, "world_cameras.world_cameras", FileIO:ConvertToScriptData(worlddef._world_cameras_data or {}, cusxml))
        self:save_cover_data(include)
        self:save_nav_data(include)
        for _, folder in pairs(FileIO:GetFolders(map_path)) do
            if not worlddef._continent_definitions[folder] then
                FileIO:Delete(BeardLib.Utils.Path:Combine(map_path, folder))
            end
        end
        self:save_main_xml(include)
        self._saving = false
    end
    if FileIO:Exists(path) then
        local backups_dir = BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, "backups")
        FileIO:MakeDir(backups_dir)
        local backup_dir = BeardLib.Utils.Path:Combine(backups_dir, table.remove(string.split(path, "/")))
        if FileIO:Exists(backup_dir) then
            FileIO:Delete(backup_dir)
        end
        FileIO:CopyToAsync(path, backup_dir, save)
    else
        FileIO:MakeDir(path)
        save()
    end
end

function GameOptions:save_main_xml(include)
    local proj = BeardLibEditor.managers.MapProject
    local mod = proj:current_mod()
    local data = mod and proj:get_clean_data(mod._clean_config)
    if data then
        local level = proj:get_level_by_id(data, Global.game_settings.level_id)
        local temp = table.list_add(include, clone(level.include))        
        level.include = {directory = level.include.directory}
        for i, include_data in ipairs(temp) do
            include_data.type = include_data.type or "binary"           
            if type(include_data) == "table" and include_data.file and FileIO:Exists(BeardLib.Utils.Path:Combine(mod.ModPath, level.include.directory, include_data.file)) then
                local exists
                for _, inc_data in ipairs(level.include) do
                    if type(inc_data) == "table" and inc_data.file == include_data.file then
                        exists = true
                    end
                end
                if not exists then
                    table.insert(level.include, include_data)
                end
            end
        end
        proj:map_editor_save_main_xml(data)
    end
end

function GameOptions:SaveData(path, file_name, data)
    if not FileIO:Exists(path) then
        FileIO:MakeDir(path)
    end
    self._parent:Log("Saving script data '%s' in %s", file_name, path)
    FileIO:WriteTo(BeardLib.Utils.Path:Combine(path, file_name), data)
end

function GameOptions:save_nav_data(include)    
    local path = self:map_world_path()
    local had_include = not not include
    include = include or {}
    local save_data = managers.navigation:get_save_data()
    local save_in_binary = self:Value("SaveMapFilesInBinary")
    local typ = save_in_binary and "binary" or "generic_xml"
    if save_data then
        table.insert(include, {_meta = "file", file = "nav_manager_data.nav_data", type = typ})
        --This sucks
        self:SaveData(path, "nav_manager_data.nav_data", save_in_binary and FileIO:ConvertToScriptData(FileIO:ConvertScriptData(save_data, "generic_xml"), typ) or save_data)
    else
        BeardLibEditor.Utils:Notify("Save data is not ready yet")
        return
    end
    if not had_include then
        self:save_main_xml(include)
    end
end

function GameOptions:save_cover_data(include)
    local path = self:map_world_path()
    local had_include = not not include
    include = include or {}
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
    local typ = self:Value("SaveMapFilesInBinary") and "binary" or "custom_xml"
    table.insert(include, {_meta = "file", file = "cover_data.cover_data", type = typ})
    self:SaveData(path, "cover_data.cover_data", FileIO:ConvertToScriptData(covers, typ))
    if not had_include then
        self:save_main_xml(include)
    end
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
            BeardLibEditor.Utils:Notify("Error!", "There are no nav surfaces in the map to begin building the navigation data, please spawn one from world menu > AI layer > Add Nav surface")
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
    managers.navigation:build_visibility_graph(function()
        managers.groupai:set_state("none")
    end, all_visible, exclude, include, ray_lenght)
end