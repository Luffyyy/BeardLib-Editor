InEditorOptions = InEditorOptions or class(EditorPart)
local Options = InEditorOptions
function Options:init(parent, menu)
    self.super.init(self, parent, menu, "Options")    
    self._wanted_elements = {}
end

--TODO: cleanup
function Options:build_default()
    local groups_opt = {offset = {8, 4}}

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
    main:numberbox("AutoSaveMinutes", ClassClbk(self, "update_option_value"), self:Val("AutoSaveMinutes"), {help = "Set the time for auto saving"})
    main:tickbox("AutoSave", ClassClbk(self, "update_option_value"), self:Val("AutoSave"), {help = "Saves your map automatically, unrecommended for large maps."})
    main:tickbox("SaveMapFilesInBinary", ClassClbk(self, "update_option_value"), self:Val("SaveMapFilesInBinary"), {help = "Saving your map files in binary cuts down in map file size which is highly recommended for release!"})
    main:tickbox("BackupMaps", ClassClbk(self, "update_option_value"), self:Val("BackupMaps"))
    main:tickbox("RemoveOldLinks", ClassClbk(self, "update_option_value"), self:Val("RemoveOldLinks"), {
        text = "Remove Old Links Of Copied Elements",
        help = "Should the editor remove old links(ex: elements inside the copied element's on_executed list that are not part of the copy) when copy pasting elements"
    })
    main:tickbox("KeepMouseActiveWhileFlying", ClassClbk(self, "update_option_value"), self:Val("KeepMouseActiveWhileFlying"))

    local camera = self:group("Camera", groups_opt)
    local cam_speed = self:Val("CameraSpeed")
    local fov = self:Val("CameraFOV")
    local far_clip = self:Val("CameraFarClip")
    camera:numberbox("CameraSpeed", ClassClbk(self, "update_option_value"), cam_speed, {max = 10, min = 0, step = 0.1})
    camera:numberbox("CameraFOV", ClassClbk(self, "update_option_value"), fov, {max = 170, min = 40, step = 1})
    camera:numberbox("CameraFarClip", ClassClbk(self, "update_option_value"), far_clip, {max = 500000, min = 1000, step = 100})
    camera:tickbox("Orthographic", ClassClbk(self._parent, "toggle_orthographic"), false)
    camera:numberbox("OrthographicScale", ClassClbk(self._parent, "set_orthographic_scale"), 80)

    local map = self:group("Map", groups_opt)
    map:tickbox("EditorUnits", ClassClbk(self, "update_option_value"), self:Val("EditorUnits"), {help = "Draw editor units"})
    map:tickbox("HighlightUnits", ClassClbk(self, "update_option_value"), self:Val("HighlightUnits"))
    map:tickbox("HighlightOccluders", nil, false)
    map:tickbox("HighlightInstances", ClassClbk(self, "update_option_value"), self:Val("HighlightInstances"))
    map:tickbox("ShowElements", ClassClbk(self, "update_option_value"), self:Val("ShowElements"))
    map:tickbox("DrawOnlyElementsOfCurrentScript", ClassClbk(self, "update_option_value"), self:Val("DrawOnlyElementsOfCurrentScript"))
    map:tickbox("DrawBodies", ClassClbk(self, "update_option_value"), self:Val("DrawBodies"))
    map:tickbox("DrawPortals", nil, false)
    map:numberbox("InstanceIndexSize", ClassClbk(self, "update_option_value"), self:Val("InstanceIndexSize"), {max = 100000, floats = 0, min = 1, help = "Sets the default index size for instances."})

    local raycast = self:group("Raycast/Selecting", groups_opt)
    raycast:tickbox("SelectAndGoToMenu", ClassClbk(self, "update_option_value"), self:Val("SelectAndGoToMenu"), {text = "Go to selection menu when selecting"})
    raycast:tickbox("SurfaceMove", ClassClbk(self, "toggle_surfacemove"), self:Val("SurfaceMove"))
    raycast:tickbox("IgnoreFirstRaycast", nil, false)
    raycast:tickbox("SelectEditorGroups", ClassClbk(self, "update_option_value"), self:Val("SelectEditorGroups"))
    raycast:tickbox("SelectInstances", ClassClbk(self, "update_option_value"), self:Val("SelectInstances"))
    raycast:tickbox("SelectAllRaycast", nil, false)
    raycast:tickbox("EndlessSelection", ClassClbk(self, "update_option_value"), self:Val("EndlessSelection"), {help = "Pressing a unit again will select the unit behind(raycast wise)"})
    raycast:numberbox("EndlessSelectionReset", ClassClbk(self, "update_option_value"), self:Val("EndlessSelectionReset"), {
        help = "How much seconds should the editor wait before reseting the endless selection",
        control_slice = 0.25,
    })
    raycast:numberbox("RaycastDistance", nil, 200000)

    local mission = self:group("Mission", groups_opt)
	mission:tickbox("UniqueElementIcons", ClassClbk(self, "update_option_value"), self:Val("UniqueElementIcons"))
    mission:tickbox("RandomizedElementsColor", ClassClbk(self, "update_option_value"), self:Val("RandomizedElementsColor"))
    mission:colorbox("ElementsColor", ClassClbk(self, "update_option_value"), self:Val("ElementsColor"))
    mission:slider("ElementsSize", ClassClbk(self, "update_option_value"), self:Val("ElementsSize"), {max = 64, min = 16, floats = 0})

    --Can't find a place for these
    local fixes = self:group("Fixes", groups_opt)
    fixes:button("Remove brush(massunits) layer", ClassClbk(self, "remove_brush_layer"), {
        help = "Brushes/Mass units are small decals in the map such as garbage on floor and such, sadly the editor has no way of editing it, the best you can do is remove it."
    })

    local world = self:GetPart("world")
    if world._assets_manager then
        fixes:button("Clean add.xml", ClassClbk(world._assets_manager, "clean_add_xml"), {help = "This removes unused files from the add.xml and cleans duplicates"})
    end

    local other = self:group("Other", groups_opt)
    other:button("TeleportPlayer", ClassClbk(self, "drop_player"))
    other:button("LogPosition", ClassClbk(self, "position_debug"))
    if BeardLib.current_level then
        other:button("OpenMapInExplorer", ClassClbk(self, "open_in_explorer"))
    end
    other:button("OpenWorldInExplorer", ClassClbk(self, "open_in_explorer", true))
    other:tickbox("PauseGame", ClassClbk(self, "pause_game"), false)

    self:toggle_autosaving()
end

function Options:enable()
    Options.super.enable(self)
    self:bind_opt("SaveMap", ClassClbk(self, "KeySPressed"))
    self:bind_opt("IncreaseCameraSpeed", ClassClbk(self, "ChangeCameraSpeed"))
    self:bind_opt("DecreaseCameraSpeed", ClassClbk(self, "ChangeCameraSpeed", true))
    self:bind_opt("ToggleGUI", ClassClbk(self, "ToggleEditorGUI"))
    self:bind_opt("ToggleRuler", ClassClbk(self, "ToggleEditorRuler"))
end

function Options:pause_game(item) Application:set_pause(item.value) end
function Options:drop_player() game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0)) end
function Options:ToggleEditorGUI() self._parent._menu:Toggle() end
function Options:ToggleEditorRuler() self._parent:SetRulerPoints() end

function Options:ChangeCameraSpeed(decrease)
    local cam_speed = self:GetItem("CameraSpeed")
    cam_speed:SetValue(cam_speed:Value() + (decrease == true and -1 or 1), true)
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
        for _, unit in pairs(World:find_units_quick("all")) do
            if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
                unit:set_visible(value)
            end
        end
    elseif name == "GridSize" then
        self._parent:update_grid_size(value)
    elseif name == "SnapRotation" then
        self._parent:update_snap_rotation(value)
    elseif name == "DrawOnlyElementsOfCurrentScript" or name == "ShowElements" then
        self:GetPart("mission"):set_elements_vis()
    elseif name == "AutoSave" or name == "AutoSaveMinutes" then
        self:toggle_autosaving()
    elseif name == "CameraFOV" then
        self._parent:set_camera_fov(value)
    elseif name == "CameraFarClip" then
        self._parent:set_camera_far_range(value)
    elseif name == "SurfaceMove" then
        self._parent:set_use_surface_move(value)
    end
end

function Options:get_value(opt)
    local item = self:GetItem(opt)
    return item and item:Value()
end

function Options:position_debug()
    BLE:log("Camera Position: %s", tostring(self._parent._camera_pos))
	BLE:log("Camera Rotation: %s", tostring(self._parent._camera_rot))
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

function Options:save(force_backup, old_include)
    if self._saving then
        return
    end

    if BeardLib.current_level._config.include then
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
                self:save(true, level.include)
                level.include = nil
                project:save_main_xml(data)
            end)
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
    local save_in_binary = self:Val("SaveMapFilesInBinary")
    local xml = save_in_binary and "binary" or "generic_xml"
    local cusxml = save_in_binary and "binary" or "custom_xml"
    local include = {
        {_meta = "world", path = "world", script_data_type = xml},
        {_meta = "continents", path = "continents", script_data_type = cusxml},
        {_meta = "mission", path = "mission", script_data_type = cusxml},
        {_meta = "nav_data", path = "nav_manager_data", script_data_type = xml},
        {_meta = "world_sounds", path = "world_sounds", script_data_type = xml},
        {_meta = "world_cameras", path = "world_cameras", script_data_type = cusxml}
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
            local dir = Path:Combine(map_path, name)
            local continent_file = name .. ".continent"
            local mission_file = name .. ".mission"
            table.insert(include, {_meta = "continent", path = name.."/"..name, script_data_type = cusxml})
            table.insert(include, {_meta = "mission", path = name.."/"..name, script_data_type = xml})
            self:SaveData(dir, continent_file, FileIO:ConvertToScriptData(data, cusxml))
            self:SaveData(dir, mission_file, FileIO:ConvertToScriptData(managers.mission._missions[name], xml))
            missions[name] = {file = Path:Combine(name, name)}
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

		if bg then
			play_value(bg, "alpha", 0, {wait = 0.5, stop = false})
        end

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
    end
	if bg then
		bg:set_alpha(0)
		play_value(bg, "alpha", 1)
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
    if self:get_value("AutoSave") and BeardLib.current_level then
        self._auto_save = TimerManager:main():time() + (self:get_value("AutoSaveMinutes") * 60)
    else
        self._auto_save = nil
    end
end

function Options:save_local_add_xml(include)
    local project = BLE.MapProject
    local level = BeardLib.current_level
    if level then
        local add = project:read_xml(level._local_add_path, false)
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

function Options:save_nav_data(include)
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
	    managers.game_play_central:restart_the_game()
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


function Options:open_in_explorer(world_path)
    Application:shell_explore_to_folder(string.gsub(world_path == true and self:map_world_path() or self:map_path(), "/", "\\"))
end

function Options:remove_brush_layer()
    BLE.Utils:YesNoQuestion("This will remove the brush layer from your level, this cannot be undone from the editor.", function()
        self:part("world"):data().brush = nil
        MassUnitManager:delete_all_units()
    end)
end

function Options:toggle_surfacemove(item)
    self:update_option_value(item)
    self._parent:set_use_surface_move(item:Value())
end