InEditorOptions = InEditorOptions or class(EditorPart)
local Options = InEditorOptions
function Options:init(parent, menu)
    self.super.init(self, parent, menu, "Options")
    self._wanted_elements = {}
    self._save_callbacks = {}
end

--TODO: cleanup
function Options:build_default()
    local groups_opt = {align_method = "grid", control_slice = 0.5}

    local main = self:group("Editor", groups_opt)
    local grid_size = self:Val("GridSize")
    local snap_rotation = self:Val("SnapRotation")
    main:numberbox("GridSize", ClassClbk(self, "update_option_value"), grid_size, {max = 10000, min = 0.1, help = "Sets the amount(in centimeters) that the unit will move"})
    main:numberbox("SnapRotation", ClassClbk(self, "update_option_value"), snap_rotation, {max = 360, min = 1, help = "Sets the amount(in degrees) that the unit will rotate"})
    main:numberbox("RotateSpawnDummy", ClassClbk(self, "update_option_value"), self:Val("RotateSpawnDummy"), {
        max = 360, min = 1, help = "Sets the amount(in degrees) that the dummy unit will rotate when one of the rotate keybinds are pressed"
    })

    self._parent:update_grid_size(grid_size)
    self._parent:update_snap_rotation(snap_rotation)
    if not BeardLib.current_level then
        main:textbox("MapSavePath", nil, Path:Combine(BeardLib.config.maps_dir, Global.current_level_id or ""))
    end

    local cam_speed = self:Val("CameraSpeed")
    local fov = self:Val("CameraFOV")
    local far_clip = self:Val("CameraFarClip")
    main:numberbox("CameraSpeed", ClassClbk(self, "update_option_value"), cam_speed, {max = 10, min = 0, step = 0.1})
    main:numberbox("CameraFOV", ClassClbk(self, "update_option_value"), fov, {max = 170, min = 40, step = 1})
    main:numberbox("CameraFarClip", ClassClbk(self, "update_option_value"), far_clip, {max = 500000, min = 1000, step = 100})
    local ort = main:numberbox("Orthographic", ClassClbk(self._parent, "set_orthographic_scale"), 80, {textbox_offset = 32})
    ort:tickbox("Orthographic", ClassClbk(self._parent, "toggle_orthographic"), false, {position = function(item)
        item:SetPositionByString("RightCentery")
        item:Move(-4)
    end, size_by_text = true, text = ""})

    local render_modes = {
        "deferred_lighting",
        "albedo_visualization",
        "normal_visualization",
        "specular_visualization",
        "glossiness_visualization",
        "depth_visualization"
	}

    local map = self:group("Draw/Show", groups_opt)
    map:tickbox("EditorUnits", ClassClbk(self, "update_option_value"), self:Val("EditorUnits"), {help = "Draw editor units", size_by_text = true})
    map:tickbox("HighlightUnits", ClassClbk(self, "update_option_value"), self:Val("HighlightUnits"), {size_by_text = true})
    map:tickbox("HighlightOccluders", nil, false, {size_by_text = true})
    map:tickbox("HighlightInstances", ClassClbk(self, "update_option_value"), self:Val("HighlightInstances"), {size_by_text = true})
    map:tickbox("ShowElements", ClassClbk(self, "update_option_value"), self:Val("ShowElements"), {size_by_text = true})
    map:tickbox("VisualizeDisabledElements", ClassClbk(self, "update_option_value"), self:Val("VisualizeDisabledElements"), {size_by_text = true})
    map:tickbox("DrawBodies", ClassClbk(self, "update_option_value"), self:Val("DrawBodies"), {size_by_text = true})
    map:tickbox("DrawOnlyElementsOfCurrentScript", ClassClbk(self, "update_option_value"), self:Val("DrawOnlyElementsOfCurrentScript"), {size_by_text = true})
    map:combobox("VisualizationMode", ClassClbk(self, "update_visualization"), render_modes, 1)

    local raycast = self:group("Raycast/Selecting", groups_opt)
    raycast:tickbox("SelectAndGoToMenu", ClassClbk(self, "update_option_value"), self:Val("SelectAndGoToMenu"), {
        text = "Auto Switch To Selection", help = "Automatically switches to the selection menu when selecting something"
    })
    local surface_key = BLE.Options:GetValue("Input/ToggleSurfaceMove")
    raycast:tickbox("SurfaceMove", ClassClbk(self, "toggle_surfacemove"), self:Val("SurfaceMove"), {help = "Snap grabbed objects to the grid on the X and Y axis.".. (string.len(surface_key) > 0 and " ("..utf8.to_upper(surface_key)..")" or "")})
    raycast:tickbox("IgnoreFirstRaycast", nil, false)
    raycast:tickbox("SelectEditorGroups", ClassClbk(self, "update_option_value"), self:Val("SelectEditorGroups"))
    raycast:tickbox("SelectInstances", ClassClbk(self, "update_option_value"), self:Val("SelectInstances"))
    raycast:tickbox("SelectAllRaycast", nil, false)
    local snappoint_key = BLE.Options:GetValue("Input/ToggleSnappoints")
    raycast:tickbox("UseSnappoints", nil, false, {help = "Snap the grabbed unit onto pre-defined points on other units."..(string.len(snappoint_key) > 0 and " ("..utf8.to_upper(snappoint_key)..")" or "")})
    raycast:tickbox("EndlessSelection", ClassClbk(self, "update_option_value"), self:Val("EndlessSelection"), {help = "Pressing a unit again will select the unit behind(raycast wise)"})
    raycast:numberbox("EndlessSelectionReset", ClassClbk(self, "update_option_value"), self:Val("EndlessSelectionReset"), {
        help = "How much seconds should the editor wait before reseting the endless selection",
    })
    raycast:numberbox("SnappointRange", nil, 800, {text = "Snappoint Search Range"})
    raycast:numberbox("RaycastDistance", nil, 200000)

    self:toggle_autosaving()
end

function Options:enable()
    Options.super.enable(self)
    self:bind_opt("SaveMap", ClassClbk(self, "KeySPressed"))
    self:bind_opt("IncreaseCameraSpeed", ClassClbk(self, "ChangeCameraSpeed"))
    self:bind_opt("DecreaseCameraSpeed", ClassClbk(self, "ChangeCameraSpeed", true))
    self:bind_opt("ToggleGUI", ClassClbk(self, "ToggleEditorGUI"), nil, true)
    self:bind_opt("ToggleRuler", ClassClbk(self, "ToggleEditorRuler"))
    self:bind_opt("ToggleLight", ClassClbk(self, "toggle_light"))
    self:bind_opt("ToggleEditorUnits", ClassClbk(self, "toggle_item", "EditorUnits"))
    self:bind_opt("ToggleElements", ClassClbk(self, "toggle_item", "ShowElements"))
    self:bind_opt("ToggleSurfaceMove", ClassClbk(self, "toggle_item", "SurfaceMove"))
    self:bind_opt("ToggleSnappoints", ClassClbk(self, "toggle_item", "UseSnappoints"))
    self:bind_opt("IncreaseGridSize", ClassClbk(self, "IncreaseGridSize"))
    self:bind_opt("DecreaseGridSize", ClassClbk(self, "DecreaseGridSize"))
end

function Options:drop_player() game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0)) end
function Options:ToggleEditorGUI() self._parent._menu:Toggle() end
function Options:ToggleEditorRuler() self._parent:SetRulerPoints() end

function Options:toggle_light(item) 
    if not item then
        item = self:GetPart("tools"):get_tool("general")._holder:GetItem("UseLight")
        item:SetValue(not item:Value())
        self._parent:status_message("Head Light "..(item:Value() and "Enabled" or "Disabled"))
    end
    self._parent:toggle_light(item:Value())
end

function Options:toggle_item(item_name) 
    local item = self:GetItem(item_name)
    item:SetValue(not item:Value(), true)
    self._parent:status_message(string.pretty2(item_name)..(item:Value() and " Enabled" or " Disabled"))
end

function Options:ChangeCameraSpeed(decrease, incremental)
    local cam_speed = self:GetItem("CameraSpeed")
    local change = incremental and math.max(cam_speed:Value() * 0.3, 0.1) or ctrl() and 0.1 or 1
    cam_speed:SetValue(cam_speed:Value() + (decrease == true and -change or change), true)
    self._parent:status_message("Camera speed changed to: "..cam_speed:Value())
end

function Options:KeySPressed()
    if ctrl() then
        self:save()
    end
end

function Options:update_option_value(item)
    local name, value = item:Name(), item:Value()
    BLE.Options:SetValue("Map/"..name, value)
    --Clean this too
    if name == "EditorUnits" then
        local continents = managers.worlddefinition._continents
        for _, unit in pairs(World:find_units_quick("all")) do
            local ud = unit:unit_data()
            if type(ud) == "table" and (ud.only_visible_in_editor or ud.only_exists_in_editor) and not ud.projection_lights and (ud.continent and continents[ud.continent].visible ~= false) then
                unit:set_visible(value)
            end
        end
        self:GetPart("quick"):UpdateToggle(name, value)
    elseif name == "GridSize" then
        self._parent:update_grid_size(value)
    elseif name == "SnapRotation" then
        self._parent:update_snap_rotation(value)
    elseif name == "DrawOnlyElementsOfCurrentScript" or name == "ShowElements" then
        self:GetPart("mission"):set_elements_vis()
        self:GetPart("quick"):UpdateToggle(name, value)
    elseif name == "CameraFOV" then
        self._parent:set_camera_fov(value)
    elseif name == "CameraFarClip" then
        self._parent:set_camera_far_range(value)
    elseif name == "SurfaceMove" then
        self._parent:set_use_surface_move(value)
    end
end

function Options:IncreaseGridSize()
    local current_size = self:Val("GridSize")
    for _, size in ipairs(self._parent._grid_sizes) do
        if size > current_size then
            current_size = size
            break
        end
    end
    self:GetItem("GridSize"):SetValue(current_size, true)
end

function Options:DecreaseGridSize()
    local current_size = self:Val("GridSize")
    for _, size in table.reverse_ipairs(self._parent._grid_sizes) do
        if size < current_size then
            current_size = size
            break
        end
    end
    self:GetItem("GridSize"):SetValue(current_size, true)
end

function Options:update_visualization(item)
    local visualization = item:SelectedItem()
    self._parent:change_visualization(visualization)
end

function Options:get_value(opt)
    local item = self:GetItem(opt)
    return item and item:Value()
end

function Options:update(t, dt)
    Options.super.update(self, t, dt)

    if self._auto_save and t >= self._auto_save then
        self:save()
    end

    if self:Val("HighlightUnits") and managers.viewport:get_current_camera() then
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
            if ud and (ud.only_visible_in_editor or ud.only_exists_in_editor) and ud.name:find("occluder_") then
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
    return BLE.MapProject:current_path() or self._menu:GetItem("MapSavePath"):Value():gsub("\\" , "/") 
end

function Options:map_world_path()    
    local map_path = BLE.MapProject:current_level_path() or self:map_path()
    if not FileIO:Exists(map_path) then
        FileIO:MakeDir(map_path)
    end
    return map_path
end

function Options:add_save_callback(id, func)
    self._save_callbacks[id] = func
end

function Options:save(force_backup, old_include, skip_warning)
    if self._saving then
        return
    end

    if not skip_warning and self:Val("SaveWarningAfterGameStarted") and self._parent._before_state then
        if self._playtest_saving_allowed == false then
            self._parent:status_message("Saving is disabled for this session")
            return
        elseif self._playtest_saving_allowed == nil then
            self._playtest_saving_allowed = false
            BLE.Utils:YesNoQuestion("Saving while the heist is running can lead to unintended side effects. Do you want to allow saving for this session?", function() 
                self._playtest_saving_allowed = true 
                self:save(force_backup, old_include)
            end)
            return
        end
    end

    if BeardLib.current_level and BeardLib.current_level._config.include then
        BLE.Utils:YesNoQuestion([[
In order to handle files better and not clutter the main.xml, the level module will now have the include section in a separate file.

This file (LEVEL/add_local.xml) looks very similar to add.xml. 
And essentially will be used to load things that load from the level itself and not from the assets folder that is shared with all levels. 

This allows us to declutter the main.xml when loading things such as cube lights.

The editor will now use this format and any old map will need to be converted. Clicking 'Yes' will backup your map into 'Maps/backups' and then convert it.
            ]]
            , function()
                local project = BLE.MapProject
                BeardLib.current_level._config.include = nil
                local _, data = project:get_mod_and_config()
                local level = project:get_current_level_node(data)
                local include = level.include
                level.include = nil
                project:save_main_xml(data)
                self:save(true, include, true)
            end)
        return
    end

    for _, clbk in pairs(self._save_callbacks) do
        clbk()
    end

    self:GetPart("static"):set_units()
    local panel = self:GetPart("menu"):GetItem("save").panel
    local bg = alive(panel) and panel:child("bg_save") or panel:rect({
        name = "bg_save",
		color = self._holder.accent_color,
		halign = "grow",
		valign = "grow",
    })
    local w = bg and bg:parent():w()
    self._saving = true
    local save_in_binary = self:Val("SaveMapFilesInBinary")
    local xml = save_in_binary and "binary" or "generic_xml"
    local cusxml = save_in_binary and "binary" or "custom_xml"
    local include = {
        {_meta = "world", path = "world", script_data_type = xml},
        {_meta = "continents", path = "continents", script_data_type = cusxml},
        {_meta = "mission", path = "mission", script_data_type = cusxml},
        {_meta = "nav_data", path = "nav_manager_data", script_data_type = xml},
        {_meta = "world_sounds", path = "world_sounds", script_data_type = xml},
        {_meta = "world_cameras", path = "world_cameras", script_data_type = xml},
        {_meta = "massunit", path = "massunit", reload = true},
    }
    local worlddef = managers.worlddefinition
    local path = self:map_path()
	local function save()
        local map_path = self:map_world_path()

        local world_data = deep_clone(worlddef._world_data)
        if BeardLib.current_level then
            local map_dbpath = BeardLib.current_level._inner_dir
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
        BLE.Utils:SaveUnitDataTable(world_data.ai, xml)
        BLE.Utils:SaveUnitDataTable(world_data.wires, xml)
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
        local continent_definitions = BeardLib.Utils.XML:Clean(deep_clone(worlddef._continent_definitions))
        for name, data in pairs(continent_definitions) do
            BLE.Utils:SaveUnitDataTable(data.statics, cusxml)

            local dir = Path:Combine(map_path, name)
            local continent_file = name .. ".continent"
            local mission_file = name .. ".mission"
            table.insert(include, {_meta = "continent", path = name.."/"..name, script_data_type = cusxml})
            table.insert(include, {_meta = "mission", path = name.."/"..name, script_data_type = xml})
            self:SaveData(dir, continent_file, FileIO:ConvertToScriptData(data, cusxml))
            self:SaveData(dir, mission_file, FileIO:ConvertToScriptData(managers.mission._missions[name], xml))
            missions[name] = {file = Path:Combine(name, name)}
        end

        local continents = BeardLib.Utils:RemoveMetas(deep_clone(worlddef._continents))
        if cusxml == "custom_xml" then --Fix for custom xml ruining the id if its higher than 1000000
            for _, data in pairs(continents) do
                data.base_id = tostring(data.base_id)
            end
        end
        self:SaveData(map_path, "continents.continents", FileIO:ConvertToScriptData(continents, cusxml))
        self:SaveData(map_path, "mission.mission", FileIO:ConvertToScriptData(missions, cusxml))
        self:SaveData(map_path, "world_sounds.world_sounds", FileIO:ConvertToScriptData(worlddef._sound_data or {}, xml))

        managers.worldcamera:save()
        self:SaveData(map_path, "world_cameras.world_cameras", FileIO:ConvertToScriptData(worlddef._world_cameras_data, xml))

        if worlddef._world_settings then
            for name, data in pairs(worlddef._world_settings) do 
                local setting_file = name .. ".world_setting"
                table.insert(include, {_meta = "world_setting", path = name, script_data_type = xml})
                self:SaveData(map_path, setting_file, FileIO:ConvertToScriptData(data, xml))
            end
        end

        self:save_cover_data(include)
        self:save_nav_data(include)

        if old_include then
            -- This should get filtered by the save XML function, if there are any copies of the same file.
            for _, file in pairs(old_include) do
                if type(file) == "table" and file.file then
                    table.insert(include, {path = Path:GetFilePathNoExt(file.file), _meta = Path:GetFileExtension(file.file), script_data_type = file.type})
                end
            end
        end

        self:save_local_add_xml(include)
        self._saving = false
        self:toggle_autosaving()

        if bg then
            play_value(bg, "w", w, {time = 0.25})
			play_value(bg, "alpha", 0, {wait = 0.5, stop = false})
        end
    end
	if bg then
		bg:set_w(0)
		bg:set_alpha(1)
		bg:set_h(100)
		bg:set_bottom(bg:parent():bottom())
		play_value(bg, "w", w, {time = 15})
	end
    if FileIO:Exists(path) and self:Val("BackupMaps") or force_backup then
        local backups_dir = Path:Combine(BeardLib.config.maps_dir, "backups")
        FileIO:MakeDir(backups_dir)
        local backup_dir = Path:Combine(backups_dir, table.remove(string.split(path, "/")))
        if FileIO:Exists(backup_dir) then
            FileIO:Delete(backup_dir)
        end
        FileIO:CopyToAsync(path, backup_dir, save)
    else
        FileIO:MakeDir(path)
        save()
    end
end

function Options:toggle_autosaving()
    if self:Val("AutoSave") and BeardLib.current_level then
        self._auto_save = TimerManager:main():time() + (self:Val("AutoSaveMinutes") * 60)
    else
        self._auto_save = nil
    end
end

function Options:save_local_add_xml(include)
    local project = BLE.MapProject
    local level = BeardLib.current_level
    if level then
        local add = project:read_xml(level._local_add_path, false) or {}
        local temp = include and table.list_add(include, clone(add)) or add
        local level_dir = project:current_level_path()
        local new_add = {_meta = "add"}
        for i, child in pairs(temp) do
            if type(child) == "table" and child.path and FileIO:Exists(Path:Combine(level_dir, child.path.."."..child._meta)) then
                local exists
                for _, _child in ipairs(new_add) do
                    if type(child) == "table" and child.path == _child.path and child._meta == _child._meta then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(new_add, child)
                end
            end
        end
        project:save_xml(level._local_add_path, new_add)
    end
end

function Options:SaveData(path, file_name, data)
    if not FileIO:Exists(path) then
        FileIO:MakeDir(path)
    end
    self._parent:Log("Saving script data '%s' in %s", file_name, path)
    FileIO:WriteTo(Path:Combine(path, file_name), data)
end

function Options:save_nav_data(include, skip_restart)
    local path = self:map_world_path()
    local had_include = not not include
    include = include or {}
    local save_data = managers.navigation:get_save_data()
    local save_in_binary = self:Val("SaveMapFilesInBinary")
    local typ = save_in_binary and "binary" or "generic_xml"
    if save_data then
        table.insert(include, {_meta = "nav_data", path = "nav_manager_data", script_data_type = typ})
        --This sucks
        self:SaveData(path, "nav_manager_data.nav_data", save_in_binary and FileIO:ConvertToScriptData(FileIO:ConvertScriptData(save_data, "generic_xml"), typ) or save_data)
    else
        BLE.Utils:Notify("Save data is not ready yet")
        return
    end
    if not had_include then
        self:save_local_add_xml(include)
        if not skip_restart then
	        managers.game_play_central:restart_the_game()
        end
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
    local typ = self:Val("SaveMapFilesInBinary") and "binary" or "custom_xml"
    table.insert(include, {_meta = "cover_data", path = "cover_data", script_data_type = typ})
    self:SaveData(path, "cover_data.cover_data", FileIO:ConvertToScriptData(covers, typ))
    if not had_include then
        self:save_local_add_xml(include)
    end
end

function Options:toggle_surfacemove(item)
    self:update_option_value(item)
    self._parent:set_use_surface_move(item:Value())
end