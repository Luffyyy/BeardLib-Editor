InEditorOptions = InEditorOptions or class(EditorPart)
local Options = InEditorOptions
function Options:init(parent, menu)
    self.super.init(self, parent, menu, "Options")    
    self._wanted_elements = {}
end

function Options:build_default_menu()
    self.super.build_default_menu(self)
    local groups_opt = {offset = {8, 4}}
    local main = self:DivGroup("Main", groups_opt)
    self._current_continent = self:ComboBox("CurrentContinent", callback(self, self, "set_current_continent"), nil, nil, {group = main})
    self._current_script = self:ComboBox("CurrentScript", callback(self, self, "set_current_continent"), nil, nil, {group = main})
    local grid_size = self:Value("GridSize")
    local snap_rotation = self:Value("SnapRotation")
    self:Slider("CameraSpeed", callback(self, self, "update_option_value"), self:Value("CameraSpeed"), {max = 10, min = 0, step = 0.1, group = main})
    self:Slider("GridSize", callback(self, self, "update_option_value"), grid_size, {max = 10000, min = 0.1, help = "Sets the amount(in centimeters) that the unit will move", group = main})
    self:Slider("SnapRotation", callback(self, self, "update_option_value"), snap_rotation, {max = 360, min = 1, help = "Sets the amount(in degrees) that the unit will rotate", group = main})    
    self._parent:update_grid_size(grid_size)
    self._parent:update_snap_rotation(snap_rotation)
    if not BeardLib.current_level then
        self:TextBox("MapSavePath", nil, BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, Global.game_settings.level_id or ""), {group = main})
    end
    self:Toggle("SaveMapFilesInBinary", callback(self, self, "update_option_value"), self:Value("SaveMapFilesInBinary"), {group = main, help = "Saving your map files in binary cuts down in map file size which is highly recommended for release!"})
    self:Toggle("BackupMaps", callback(self, self, "update_option_value"), self:Value("BackupMaps"), {group = main})
    self:Toggle("RemoveOldLinks", callback(self, self, "update_option_value"), self:Value("RemoveOldLinks"), {
        group = main,
        text = "Remove Old Links Of Copied Elements",
        help = "Should the editor remove old links(ex: elements inside the copied element's on_executed list that are not part of the copy) when copy pasting elements"
    })

    local map = self:DivGroup("Map", groups_opt)
    self:Toggle("EditorUnits", callback(self, self, "update_option_value"), self:Value("EditorUnits"), {group = map, help = "Draw editor units"})
    self:Toggle("EnvironmentUnits", callback(self, self, "update_option_value"), self:Value("EnvironmentUnits"), {group = map, help = "Draw environment units"})
    self:Toggle("SoundUnits", callback(self, self, "update_option_value"), self:Value("SoundUnits"), {group = map, help = "Draw sound units"})
    self:Toggle("HighlightUnits", callback(self, self, "update_option_value"), self:Value("HighlightUnits"), {group = map})
    self:Toggle("HighlightOccluders", nil, false, {group = map})
    self:Toggle("ShowElements", callback(self, self, "update_option_value"), self:Value("ShowElements"), {group = map})
    self:Toggle("DrawOnlyElementsOfCurrentScript", callback(self, self, "update_option_value"), self:Value("DrawOnlyElementsOfCurrentScript"), {group = map})
    self:Toggle("DrawBodies", callback(self, self, "update_option_value"), self:Value("DrawBodies"), {group = map})
    self:Toggle("DrawPortals", nil, false, {group = map})

    local navigation_debug = self:DivGroup("NavigationDebug", {text = "Navigation Debug[Toggle what to draw]", offset = groups_opt.offset})
    local group = self:Menu("Draw", {align_method = "grid", group = navigation_debug})
    self._draw_options = {}
    local w = group.w / 3
    for _, opt in pairs({"quads", "doors", "blockers", "vis_graph", "coarse_graph", "nav_links", "covers"}) do
        self._draw_options[opt] = self:Toggle(opt, callback(self, self, "draw_nav_segments"), false, {w = w, items_size = 15, offset = 0, group = group})
    end
    local raycast = self:DivGroup("Raycast/Selecting", groups_opt)
    self:Toggle("SelectAndGoToMenu", callback(self, self, "update_option_value"), self:Value("SelectAndGoToMenu"), {text = "Go to selection menu when selecting", group = raycast})
    self:Toggle("IgnoreFirstRaycast", nil, false, {group = raycast})
    self:Toggle("SelectEditorGroups", nil, false, {group = raycast})
    self:Toggle("SelectInstances", nil, self:Value("SelectInstances"), {group = raycast})
    self:Toggle("SelectAllRaycast", nil, false, {group = raycast})
    self:Toggle("KeepMouseActiveWhileFlying", callback(self, self, "update_option_value"), self:Value("KeepMouseActiveWhileFlying"), {group = raycast})
    self:Toggle("EndlessSelection", callback(self, self, "update_option_value"), self:Value("EndlessSelection"), {help = "Pressing a unit again will select the unit behind(raycast wise)", group = raycast})
    self:NumberBox("EndlessSelectionReset", callback(self, self, "update_option_value"), self:Value("EndlessSelectionReset"), {
        help = "How much seconds should the editor wait before reseting the endless selection", group = raycast,
        control_slice = 0.25,
    })
    self:NumberBox("RaycastDistance", nil, 200000, {group = raycast})

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

function Options:enable() 
    self:bind_opt("SaveMap", callback(self, self, "KeySPressed"))
    self:bind_opt("IncreaseCameraSpeed", callback(self, self, "ChangeCameraSpeed"))
    self:bind_opt("DecreaseCameraSpeed", callback(self, self, "ChangeCameraSpeed", true))
    self:bind_opt("ToggleGUI", callback(self, self, "ToggleEditorGUI"))
end

function Options:pause_game(menu, item) Application:set_pause(item.value) end
function Options:drop_player() game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0)) end
function Options:set_current_continent(menu, item) self._parent._current_continent = item:SelectedItem() end
function Options:ToggleEditorGUI() self._parent._menu:Toggle() end

function Options:ChangeCameraSpeed(decrease)
    local cam_speed = self:GetItem("CameraSpeed")
    cam_speed:SetValue(cam_speed:Value() + (decrease == true and -1 or 1), true)
end

function Options:KeySPressed()
    if ctrl() then
        self:save()
    end
end

function Options:open_set_color_dialog(option)
    BeardLibEditor.ColorDialog:Show({color = BeardLibEditor.Options:GetValue(option), callback = function(color)
        BeardLibEditor.Options:SetValue(option, color)
        BeardLibEditor.Options:Save()
    end})
end

function Options:loaded_continents(continents, current_continent)
    self._current_continent:SetItems(continents)
    self._current_continent:SetSelectedItem(current_continent)   
    self._current_script:SetItems(table.map_keys(managers.mission._scripts))
    self._current_script:SetValue(1)
    self:GetPart("mission"):set_elements_vis()
end

function Options:update_option_value(menu, item)
    local name = item.name
    BeardLibEditor.Options:SetValue("Map/"..name, item:Value())
    if item.name == "ShowElements" then
        self:GetPart("mission"):set_elements_vis()
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
        self:GetPart("mission"):set_elements_vis()
    end
end

function Options:get_value(opt)
    local item = self:GetItem(opt)
    return item and item:Value()
end

function Options:set_current_script(menu, item)
    self._parent._current_script = item:SelectedItem()
    self:GetPart("mission"):set_elements_vis()
end

function Options:draw_nav_segments(menu, item)
    if managers.navigation then
        managers.navigation:set_debug_draw_state(self._draw_options)
    end
end


function Options:position_debug()
    BeardLibEditor:log("Camera Position: %s", tostring(self._parent._camera_pos))
	BeardLibEditor:log("Camera Rotation: %s", tostring(self._parent._camera_rot))
end

function Options:update(t, dt)
    Options.super.update(self, t, dt)
    if self:Value("HighlightUnits") and managers.viewport:get_current_camera() then
        for _, body in ipairs(World:find_bodies("intersect", "sphere", self._parent._camera_pos, 2500)) do
            if self._parent:_should_draw_body(body) then
                self._pen:set(Color.white)
                self._pen:body(body)
            end
        end
    end
    if self:get_value("HighlightOccluders") then
        for _, unit in pairs(managers.worlddefinition._all_units) do
            local ud = alive(unit) and unit:unit_data()
            if ud and (ud.only_visible_in_editor or ud.only_exists_in_editor) and ud.name:match("occluder_") then
                Application:draw(unit, 1, 0.25, 1)
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

function Options:map_path()
    return BeardLibEditor.MapProject:current_path() or self._menu:GetItem("MapSavePath"):Value():gsub("\\" , "/") 
end

function Options:map_world_path()    
    local map_path = BeardLibEditor.MapProject:current_level_path() or self:map_path()
    if not FileIO:Exists(map_path) then
        FileIO:MakeDir(map_path)
    end
    return map_path
end

function Options:save()
    if self._saving then
        return
    end
    self:GetPart("static"):set_units()
    local panel = self:GetPart("menu"):GetItem("save").panel
    local bg = alive(panel) and panel:child("bg_save") or panel:rect({
        name = "bg_save",
		color = self._holder.accent_color,
		halign = "grow",
		valign = "grow",
    })
    local h = bg and bg:parent():h()
    self._saving = true
    local save_in_binary = self:Value("SaveMapFilesInBinary")
    local xml = save_in_binary and "binary" or "generic_xml"
    local cusxml = save_in_binary and "binary" or "custom_xml"
    local include = {
        {_meta = "file", file = "world.world", type = xml},
        {_meta = "file", file = "continents.continents", type = cusxml},
        {_meta = "file", file = "mission.mission", type = cusxml},
        {_meta = "file", file = "nav_manager_data.nav_data", type = xml},
        {_meta = "file", file = "world_sounds.world_sounds", type = xml},
        {_meta = "file", file = "world_cameras.world_cameras", type = cusxml}
    }
    local worlddef = managers.worlddefinition
    local path = self:map_path()
    local function save()
        local map_path = self:map_world_path()
    
        local world_data = deep_clone(worlddef._world_data)
        if BeardLib.current_level then
            local map_dbpath = Path:Combine("levels/mods/", BeardLib.current_level._config.id)
            local environment_values = world_data.environment.environment_values
            if string.begins(environment_values.environment, map_dbpath) then
                environment_values.environment = string.gsub(environment_values.environment, map_dbpath, ".map")
            end
            for _, area in pairs(world_data.environment.environment_areas) do
                if type(area) == "table" and area.environment then
                    area.environment = string.gsub(area.environment, map_dbpath, ".map")
                end
            end
        end
        self:SaveData(map_path, "world.world", FileIO:ConvertToScriptData(world_data, xml))

        for _, mission in pairs(managers.mission._missions) do
            for _, script in pairs(mission) do
                if type(script) == "table" and script.elements then
                    local temp = deep_clone(script.elements)
                    script.elements = {}
                    for _, element in pairs(temp) do
                        table.insert(script.elements, element)
                    end
                end
            end
        end
        
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

        self:SaveData(map_path, "continents.continents", FileIO:ConvertToScriptData(BeardLib.Utils:RemoveMetas(worlddef._continents), cusxml))
        self:SaveData(map_path, "mission.mission", FileIO:ConvertToScriptData(missions, cusxml))
        self:SaveData(map_path, "world_sounds.world_sounds", FileIO:ConvertToScriptData(worlddef._sound_data or {}, xml))

        local wcd = deep_clone(worlddef._world_cameras_data)
        if wcd.sequences and #wcd.sequences == 0 then
            wcd.sequences = nil
        end
        if wcd.worldcameras and #wcd.worldcameras == 0 then
            wcd.worldcameras = nil
        end
        self:SaveData(map_path, "world_cameras.world_cameras", FileIO:ConvertToScriptData(wcd, cusxml))

        self:save_cover_data(include)
        self:save_nav_data(include)
        for _, folder in pairs(FileIO:GetFolders(map_path)) do
            if folder ~= "environments" and not worlddef._continent_definitions[folder] then
                FileIO:Delete(BeardLib.Utils.Path:Combine(map_path, folder))
            end
        end
        if bg then
            play_anim(bg, {stop = false, wait = 0.5, set = {alpha = 0}})
        end
        self:save_main_xml(include)
        self._saving = false
    end
    if FileIO:Exists(path) and self:Value("BackupMaps") then
        local backups_dir = BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, "backups")
        FileIO:MakeDir(backups_dir)
        local backup_dir = BeardLib.Utils.Path:Combine(backups_dir, table.remove(string.split(path, "/")))
        if FileIO:Exists(backup_dir) then
            FileIO:Delete(backup_dir)
        end
        if bg then
            bg:set_alpha(0)
            play_anim(bg, {set = {alpha = 1}})
        end
        FileIO:CopyToAsync(path, backup_dir, save)
    else
        FileIO:MakeDir(path)
        save()
    end
end

function Options:save_main_xml(include)
    local project = BeardLibEditor.MapProject
    local mod = project:current_mod()
    local data = mod and project:get_clean_data(project:get_clean_mod_config(mod), true)
    if data then
        local level = project:get_level_by_id(data, Global.game_settings.level_id)
        local temp = include and table.list_add(include, clone(level.include)) or level.include
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
        project:map_editor_save_main_xml(data)
    end
end

function Options:SaveData(path, file_name, data)
    if not FileIO:Exists(path) then
        FileIO:MakeDir(path)
    end
    self._parent:Log("Saving script data '%s' in %s", file_name, path)
    FileIO:WriteTo(BeardLib.Utils.Path:Combine(path, file_name), data)
end

function Options:save_nav_data(include)    
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

function Options:save_cover_data(include)
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

function Options:build_nav_segments() -- Add later the options to the menu
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
            local SE = self:GetPart("static")
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
            if #units > 0 then
                BeardLibEditor.Utils:Notify("Error!", "at least one nav surface has to touch a surface for navigation to be built")
            else
                BeardLibEditor.Utils:Notify("Error!", "There are no nav surfaces in the map to begin building the navigation data, please spawn one")
                local W = self:GetPart("world")
                W:Switch()
                if W._current_layer ~= "ai" then
                    W:build_menu("ai")
                end
            end
        end       
    end)
end

function Options:build_visibility_graph()
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