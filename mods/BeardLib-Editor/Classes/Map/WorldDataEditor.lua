WorldDataEditor = WorldDataEditor or class(EditorPart)
local WData = WorldDataEditor
function WData:init(parent, menu) 
    if BeardLib.current_level then
        self._continent_settings = ContinentSettingsDialog:new(BLE._dialogs_opt)
        self._assets_manager = AssetsManagerDialog:new(BLE._dialogs_opt)
        self._objectives_manager = ObjectivesManagerDialog:new(BLE._dialogs_opt)
    end
    self._opened = {}
    WData.super.init(self, parent, menu, "World", {make_tabs = ClassClbk(self, "make_tabs")})
end

function WData:data() return managers.worlddefinition and managers.worlddefinition._world_data end

function WData:enable()
    self:bind_opt("SpawnUnit", callback(self, self, "OpenSpawnUnitDialog"))
    self:bind_opt("SpawnElement", callback(self, self, "OpenSpawnElementDialog"))
    self:bind_opt("SelectUnit", callback(self, self, "OpenSelectUnitDialog"))
    self:bind_opt("SelectElement", callback(self, self, "OpenSelectElementDialog"))
end

function WData:loaded_continents()
    self:build_default_menu()
    for _, manager in pairs(self.layers) do
        if manager.loaded_continents then
            manager:loaded_continents()
        end
    end
    self._loaded = true
end

function WData:unit_spawned(unit)
    for _, manager in pairs(self.layers) do
        if manager.unit_spawned then
            manager:unit_spawned(unit)
        end
	end
end

function WData:unit_deleted(unit)
    for _, manager in pairs(self.layers) do
        if manager.unit_deleted then
            manager:unit_deleted(unit)
        end
    end
end

function WData:do_spawn_unit(unit, data)
    for _, manager in pairs(self.layers) do
        if manager.is_my_unit and manager:is_my_unit(unit:id())  then
            return manager:do_spawn_unit(unit, data)
        end
    end
end

function WData:is_world_unit(unit)
    unit = unit:id()
    for _, manager in pairs(self.layers) do
        if manager.is_my_unit and manager:is_my_unit(unit) then
            return true
        end
    end
    return false
end

function WData:build_unit_menu()
    local selected_unit = self:selected_unit()
    for _, manager in pairs(self.layers) do
        if manager.build_unit_menu and manager:is_my_unit(selected_unit:name():id()) then
            manager:build_unit_menu()
        end
    end
end

function WData:update_positions()
    local selected_unit = self:selected_unit()
    if selected_unit then
        for _, manager in pairs(self.layers) do
            if manager.save and manager:is_my_unit(selected_unit:name():id()) then
                manager:save()
            end
        end
    end
end

function WData:make_tabs(tabs)
    local managers = {"main", "environment", "sound", "wires", "portal", "groups"}
    self._current_layer = "main"
    for i, name in pairs(managers) do
        self._tabs:SButton(name, ClassClbk(self, "build_menu", name:lower()), {
            enabled = not Global.editor_safe_mode,
            text = string.capitalize(name),
            border_bottom = i == 1
        })
    end
end

function WData:build_default_menu()
    self.super.build_default_menu(self)
    self.layers = self.layers or {environment = EnvironmentLayerEditor:new(self), sound = SoundLayerEditor:new(self), portal = PortalLayerEditor:new(self)}

    local alert_opt = {divider_type = true, position = "RightTop", w = 24, h = 24}
    local function make_alert(text)
        local div = self:Divider(text, {border_color = Color.yellow, border_lock_height = false})
        div:ImgButton("Alert", nil, nil, {30, 190, 72, 72}, {divider_type = true, w = 24, h = 24})
    end

    if not BeardLib.current_level then
        local s = "Preview mode"
        s = s .. "\nSaving the map will not clone the map, it'll just save it."
        s = s .. "\nIf you wish to clone it please use the 'Clone Existing Heist' feature in projects menu."
        make_alert(s)
    end
    if Global.editor_safe_mode then
        make_alert("Safe mode\nSome features are disabled")
    end
    if not self._parent._has_fix then
        make_alert("Physics settings fix was not installed\nsome features are disabled.")
    end


    local spawn = self:DivGroup("Spawn", {enabled = not Global.editor_safe_mode, align_method = "centered_grid"})
    local spawn_unit = BLE.Options:GetValue("Input/SpawnUnit")
    local spawn_element = BLE.Options:GetValue("Input/SpawnElement")
    local select_unit = BLE.Options:GetValue("Input/SelectUnit")
    local select_element = BLE.Options:GetValue("Input/SelectElement")
    spawn:SButton("Unit", callback(self, self, "OpenSpawnUnitDialog"), {text = "Unit("..spawn_unit..")"})
    spawn:SButton("Element", callback(self, self, "OpenSpawnElementDialog"), {text = "Element("..spawn_element..")"})
    spawn:SButton("Instance", callback(self, self, "OpenSpawnInstanceDialog"))
    spawn:SButton("Prefab", callback(self, self, "OpenSpawnPrefabDialog"))

    local select = self:DivGroup("Select", {enabled = not Global.editor_safe_mode, align_method = "centered_grid"})
    select:SButton("Unit", callback(self, self, "OpenSelectUnitDialog", {}), {text = "Unit("..select_unit..")"})
    select:SButton("Element", callback(self, self, "OpenSelectElementDialog"), {text = "Element("..select_element..")"})
    select:SButton("Instance", callback(self, self, "OpenSelectInstanceDialog", {}))

    if BeardLib.current_level then
        local load = self:DivGroup("Load", {align_method = "centered_grid"})
		local load_extract = FileIO:Exists(BLE.ExtractDirectory) and self:DivGroup("LoadFromExtract", {align_method = "centered_grid"}) or nil
		for _, ext in pairs(BLE.UsableAssets) do
			load:SButton(ext, callback(self, self, "OpenLoadDialog", {ext = ext}))
			if load_extract then
				load_extract:SButton(ext, callback(self, self, "OpenLoadDialog", {on_click = ClassClbk(self, "LoadFromExtract", ext), ext = ext}))
			end
		end
    end

    local mng = self:DivGroup("Managers", {align_method = "centered_grid", enabled = BeardLib.current_level ~= nil})
    mng:SButton("Assets", self._assets_manager and ClassClbk(self._assets_manager, "Show") or nil)
    mng:SButton("Objectives", self._objectives_manager and ClassClbk(self._objectives_manager, "Show") or nil)

	self:reset()
    self:build_continents()
end

function WData:LoadFromExtract(ext, asset)
    self._assets_manager:load_from_extract_dialog({[ext] = {[asset] = true}}) 
end

function WData:button_pos(near, item)
	if alive(near) then
		item:Panel():set_righttop(near:Panel():left(), 0)
	else
		item:SetPositionByString("RightTop")
	end
end

--Continents
function WData:build_continents()
    local tx = "textures/editor_icons_df"
    if managers.worlddefinition then
        local continents = self:Group("Continents")
        local toolbar = continents:GetToolbar()
        toolbar:SqButton("NewContinent", ClassClbk(self, "new_continent"), {text = "+", help = "Add continent"})
        for name, data in pairs(managers.worlddefinition._continent_definitions) do
            local continent = self:Group(name, {group = continents, text = name})
            local ctoolbar = continent:GetToolbar()
            ctoolbar:ImgButton("Remove", ClassClbk(self, "remove_continent", name), tx, {184, 2, 48, 48}, {highlight_color = Color.red})
            ctoolbar:ImgButton("ClearUnits", ClassClbk(self, "clear_all_units_from_continent", name), tx, {7, 2, 48, 48}, {highlight_color = Color.red})
            ctoolbar:ImgButton("Settings", ClassClbk(self, "open_continent_settings", name), tx, {385, 385, 115, 115})
            ctoolbar:ImgButton("SelectUnits", ClassClbk(self, "select_all_units_from_continent", name), tx, {122, 1, 48, 48})
            ctoolbar:SqButton("AddScript", ClassClbk(self, "add_new_mission_script", name), {text = "+", help = "Add mission script"})
            ctoolbar:ImgButton("SetVisible", function(item) 
                local alpha = self:toggle_unit_visibility(name) and 1 or 0.5
                item.enabled_alpha = alpha
                item:SetEnabled(item.enabled) 
            end, tx, {155, 95, 64, 64})

            for sname, data in pairs(managers.mission._missions[name]) do
                local script = self:Divider(sname, {continent = name, align_method = "grid_from_right", border_color = Color.green, group = continent, text = sname, offset = {8, 4}})
                script:ImgButton("RemoveScript", ClassClbk(self, "remove_script", sname), tx, {184, 2, 48, 48}, {highlight_color = Color.red})
                script:ImgButton("ClearElements", ClassClbk(self, "clear_all_elements_from_script", sname), tx, {7, 2, 48, 48}, {highlight_color = Color.red})
                script:ImgButton("Rename", ClassClbk(self, "rename_script", sname), tx, {66, 1, 48, 48})
                script:ImgButton("Rename", ClassClbk(self, "select_all_units_from_script", sname), tx, {122, 1, 48, 48})
            end
        end
    end
end

function WData:open_continent_settings(continent)
    self._continent_settings:Show({continent = continent, callback = callback(self, self, "build_default_menu")})
end

function WData:remove_continent(continent)
    BLE.Utils:YesNoQuestion("This will remove the continent!", function()
        self:clear_all_units_from_continent(continent, true, true)
        managers.mission._missions[continent] = nil
        managers.worlddefinition._continents[continent] = nil
        managers.worlddefinition._continent_definitions[continent] = nil
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
        self:build_default_menu()
    end)
end

function WData:toggle_unit_visibility(units)
    local visible
    for _, unit in pairs(self:get_all_units_from_continent(units)) do
        if alive(unit) then unit:set_visible(not unit:visible()) visible = unit:visible() end
    end
    return visible
end

function WData:select_all_units_from_continent(continent)
    local selected_units = {}
    for _, unit in pairs(self:get_all_units_from_continent(continent)) do
        table.insert(selected_units, unit)
    end
    self:GetPart("mission"):remove_script()
    self:GetPart("static")._selected_units = selected_units
    self:GetPart("static"):set_selected_unit()
end

function WData:get_all_units_from_continent(continent)
    local units = {}
    for _, static in pairs(managers.worlddefinition._continent_definitions[continent].statics) do
        if static.unit_data and static.unit_data.unit_id then
            local unit = managers.worlddefinition:get_unit_on_load(static.unit_data.unit_id)
            if alive(unit) then
                table.insert(units, unit)
            end
        end
    end
    return units
end

function WData:clear_all_units_from_continent(continent, no_refresh, no_dialog)
    function delete_all()
        local worlddef = managers.worlddefinition
        for _, static in pairs(self:get_all_units_from_continent(continent)) do
            worlddef:delete_unit(static)
            World:delete_unit(static)
        end
        worlddef._continent_definitions[continent].editor_groups = {}
        worlddef._continent_definitions[continent].statics = {}
        if no_refresh ~= true then
            self._parent:load_continents(managers.worlddefinition._continent_definitions)
            self:build_default_menu()
        end
        worlddef:check_names()
    end
    if no_dialog == true then
        delete_all()
    else
        BLE.Utils:YesNoQuestion("This will delete all units in the continent!", delete_all)
    end
end

function WData:new_continent()
    local worlddef = managers.worlddefinition
    BLE.InputDialog:Show({title = "Continent name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
                self:new_continent()
            end})
            return
        elseif name == "environments" or string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:new_continent()
            end})
            return
        elseif worlddef._continent_definitions[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Continent name already taken!", callback = function()
                self:new_continent()
            end})
            return
        end
        managers.mission._missions[name] = managers.mission._missions[name] or {}
        worlddef._continent_definitions[name] = managers.worlddefinition._continent_definitions[name] or {
            editor_groups = {},
            statics = {},
            values = {workviews = {}}
        }            
        worlddef._continents[name] = {base_id = worlddef._start_id  * table.size(worlddef._continent_definitions), name = name}
        self._parent:load_continents(worlddef._continent_definitions)
        self:build_default_menu()
    end})
end

function WData:add_new_mission_script(cname)
    local mission = managers.mission
    BLE.InputDialog:Show({title = "Mission script name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        elseif string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        elseif mission._scripts[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name already taken!", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        end

        if cname == "world" and name ~= "default" then
            BLE.Dialog:Show({
                title = "WARNING!", 
                message = "Mission script name for the world continent must always be named 'default'"
            })

            name = "default"
        end

        mission._missions[cname][name] = mission._missions[cname][name] or {
            activate_on_parsed = true,
            elements = {},
            instances = {}   
        }
        local data = clone(mission._missions[cname][name])
        data.name = name
        data.continent = cname
        if not mission._scripts[name] then
            mission:_add_script(data)
        end
        self._parent:load_continents(managers.worlddefinition._continent_definitions)
    end})
end

function WData:remove_script(script, item)
    BLE.Utils:YesNoQuestion("This will delete the mission script including all elements inside it!", function()
        local mission = managers.mission
        self:_clear_all_elements_from_script(script, item.parent.continent, true, true)
        mission._missions[item.parent.continent][script] = nil
        mission._scripts[script] = nil
        self:build_default_menu()  
    end)
end

function WData:rename_script(script, item)
    local mission = managers.mission
    BLE.InputDialog:Show({title = "Rename Mission script to", text = script, callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:rename_script(script, item)
            end})
            return
        elseif string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_script(script, item)
            end})
            return
        elseif mission._scripts[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name already taken", callback = function()
                self:rename_script(script, item)
            end})
            return
        end
        mission._scripts[script]._name = name
        mission._scripts[name] = mission._scripts[script]
        mission._scripts[script] = nil
        mission._missions[item.parent.continent][name] = deep_clone(mission._missions[item.parent.continent][script])
        mission._missions[item.parent.continent][script] = nil
        self._parent:load_continents(managers.worlddefinition._continent_definitions)
    end})
end

function WData:clear_all_elements_from_script(script, item)
    self:_clear_all_elements_from_script(script, item.parent.continent)
end

function WData:_clear_all_elements_from_script(script, continent, no_refresh, no_dialog)
    function delete_all()
        local mission = managers.mission
        for _, element in pairs(mission._missions[continent][script].elements) do
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:mission_element() and unit:mission_element().element.id == element.id then
                    mission._scripts[script]:delete_element(element)
                    element = nil
                    World:delete_unit(unit)
                    break
                end
            end
        end
        mission._missions[continent][script].elements = {}
        if no_refresh ~= true then
            self._parent:load_continents(managers.worlddefinition._continent_definitions)
        end
    end
    if no_dialog == true then
        delete_all()
    else
        BLE.Utils:YesNoQuestion("This will delete all elements in the mission script!", delete_all)
    end
end

function WData:select_all_units_from_script(script, item)
    local selected_units = {}
    for _, unit in pairs(self:GetPart("mission")._units) do
        if unit:mission_element() then
            local element = unit:mission_element().element
            if element.script == script then
                table.insert(selected_units, unit)
            end
        end
    end
    self:GetPart("mission"):remove_script()
    self:GetPart("static")._selected_units = selected_units
    self:GetPart("static"):set_selected_unit()    
end

function WData:build_menu(name, item)
    if self._current_layer == name then
        return
    end
    self.super.build_default_menu(self)
    self._current_layer = name
    local layer = self.layers[name]
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = false})
    end
    item:SetBorder({bottom = true})
    if type(layer) == "table" then
        layer:build_menu()
    else
        self["build_"..name.."_layer_menu"](self)
    end
end

function WData:build_main_layer_menu()
    self:build_default_menu()
end

function WData:build_wires_layer_menu()
    local existing_wires = self:Group("Existing")
    managers.worlddefinition._world_data.wires = managers.worlddefinition._world_data.wires or {}
    for _, wire in pairs(managers.worlddefinition._world_data.wires) do
        local ud = wire.unit_data
        self:Button(ud.name_id, callback(self._parent, self._parent, "select_unit", managers.worlddefinition:get_unit(ud.unit_id)), {group = existing_wires})
    end
    local loaded_wires = self:Group("Spawn")
    for _, wire in pairs(BLE.Utils:GetUnits({type = "wire", packages = self._assets_manager:get_level_packages()})) do
        self:Button(wire, function()
            self:BeginSpawning(wire)
        end, {group = loaded_wires})
    end
end

function WData:build_groups_layer_menu()
    local tx  = "textures/editor_icons_df"

    local groups = self:Menu("Groups", {offset = 2, auto_align = false})
    local continents = managers.worlddefinition._continent_definitions
    for _, continent in pairs(self._parent._continents) do
        if continents[continent].editor_groups then
            for _, editor_group in pairs(continents[continent].editor_groups) do
                if editor_group.units then
                    local group = self:Group(editor_group.name, {group = groups, text = editor_group.name, auto_align = false, closed = true})
                    local toolbar = group:GetToolbar()
                    toolbar:ImgButton("Remove", function() 
                        BLE.Utils:YesNoQuestion("This will delete the group", function()
                            self:GetPart("static"):remove_group(nil, editor_group)
                            self:build_menu("groups", nil)
                        end)
                    end, tx, {184, 2, 48, 48}, {highlight_color = Color.red})
                    toolbar:ImgButton("Rename", function() 
                        BLE.InputDialog:Show({title = "Group Name", text = group.name, callback = function(name)
                            self:GetPart("static"):set_group_name(nil, editor_group, name)
                            self:build_menu("groups", nil)
                        end})
                    end, tx, {66, 1, 48, 48})
                    toolbar:ImgButton("SelectGroup", ClassClbk(self:GetPart("static"), "select_group", editor_group), tx, {122, 1, 48, 48})
                    toolbar:ImgButton("SetVisible", function(item) 
                        self:GetPart("static"):toggle_group_visibility(editor_group) 
                        item.enabled_alpha = editor_group.visible and 1 or 0.5
                        item:SetEnabled(item.enabled) 
                    end, tx, {155, 95, 64, 64}, {enabled_alpha = editor_group.visible ~= nil and (editor_group.visible and 1 or 0.5) or 1})

                    for _, unit_id in pairs(editor_group.units) do
                        local unit = managers.worlddefinition:get_unit(unit_id)
                        if alive(unit) then 
                            self:Button(tostring(unit_id), callback(self._parent, self._parent, "select_unit", unit), {group = group})
                        end
                    end
                end
            end
        else
            continents[continent].editor_groups = {}
        end
    end
    groups:AlignItems(true)
    if #groups:Items() == 0 then
        self:Divider("No groups found in the map.")
    end
end

function WData:build_ai_layer_menu()    
    local states = {
        "empty",
        "airport",
        "besiege",
        "street",
        "zombie_apocalypse"
    }
    self:ComboBox("GroupState", function(item)
        self:data().ai_settings.ai_settings.group_state = item:SelectedItem()
    end, states, table.get_key(states, self:data().ai_settings.ai_settings.group_state))
    self:Button("SpawnNavSurface", callback(self, self, "BeginSpawning", "core/units/nav_surface/nav_surface"))
    self:Button("SpawnCoverPoint", callback(self, self, "BeginSpawning", "units/dev_tools/level_tools/ai_coverpoint"))
end

function WData:reset()
    for _, editor in pairs(self.layers) do
        if editor.reset then
            editor:reset()
        end
    end
end

function WData:reset_selected_units()
    if self._loaded then
        for _, editor in pairs(self.layers) do
            if editor.reset_selected_units then
                editor:reset_selected_units()
            end
        end
    end
end

function WData:set_selected_unit()
    for _, editor in pairs(self.layers) do
        if editor.set_selected_unit then
            editor:set_selected_unit()
        end
    end
end

function WData:remove_dummy_unit()
    local unit = self._dummy_spawn_unit
    if alive(unit) then
        unit:set_enabled(false)
        unit:set_slot(0)
        World:delete_unit(unit)
    end
end

function WData:is_spawning()
    return self._currently_spawning_element or self._currently_spawning
end

function WData:mouse_pressed(button, x, y)
    if button == Idstring("0") then
        if self._currently_spawning_element then
            self._do_switch = true
            self._parent:add_element(self._currently_spawning_element)
            return true
        elseif self._currently_spawning then
            self._do_switch = true
            local unit = self._parent:SpawnUnit(self._currently_spawning)
            self:GetPart("undo_handler"):SaveUnitValues({unit}, "spawn")
            return true
        end
    elseif button == Idstring("1") and (self._currently_spawning or self._currently_spawning_element) then
        self:remove_dummy_unit()
        self._currently_spawning = nil
        self._currently_spawning_element = nil
        self:SetTitle()
        self:GetPart("menu"):set_tabs_enabled(true)
        if self._do_switch and self:Value("SelectAndGoToMenu") then
            self:GetPart("static"):Switch()
            self._do_switch = false
        end
        return true
    end
    return false
end

function WData:update(t, dt)
    self.super.update(self, t, dt)

    for _, editor in pairs(self.layers) do
        if editor.update then
            editor:update(t, dt)
        end
    end

    if alive(self._dummy_spawn_unit) then
        self._dummy_spawn_unit:set_position(self._parent._spawn_position)
        Application:draw_line(self._parent._spawn_position - Vector3(0, 0, 2000), self._parent._spawn_position + Vector3(0, 0, 2000), 0, 1, 0)
        Application:draw_sphere(self._parent._spawn_position, 30, 0, 1, 0)
    end
end

function WData:OpenSpawnPrefabDialog()
    local prefabs = {}
    for name, prefab in pairs(BLE.Prefabs) do
        table.insert(prefabs, {name = name, prefab = prefab})
    end
    BLE.ListDialog:Show({
        list = prefabs,
        force = true,
        callback = function(item)
            self:GetPart("static"):SpawnPrefab(item.prefab)
            BLE.ListDialog:hide()
        end
    }) 
end

function WData:OpenSpawnInstanceDialog()
    local instances = table.map_keys(BeardLib.managers.MapFramework._loaded_instances)
    for _, path in pairs(BLE.Utils:GetEntries({type = "world"})) do
        if path:match("levels/instances") then
            table.insert(instances, path)
        end
    end
    BLE.ListDialog:Show({
        list = instances,
        force = true,
        callback = function(item)
            local continent = managers.worlddefinition._continent_definitions[self._parent._current_continent]
            if continent then
                continent.instances = continent.instances or {}
                local instance_name = Path:GetFileName(Path:GetDirectory(item)).."_"
                local instances = managers.world_instance:instance_names()
                local i = 1
                while(table.contains(instances, instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i)) do
                    i = i + 1
                end
                instance_name = instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i
                local instance = {
                    continent = self._parent._current_continent,
                    name = instance_name,
                    folder = item,
                    position = self._parent:cam_spawn_pos(),
                    rotation = Rotation(),
                    script = self._parent._current_script,
                    index_size = 1000,
                    start_index = managers.world_instance:get_safe_start_index(1000, self._parent._current_continent)
                }
                table.insert(continent.instances, instance)
                for _, mission in pairs(managers.mission._missions) do
                    if mission[instance.script] then
                        table.insert(mission[instance.script].instances, instance_name)
                        break
                    end
                end
                managers.world_instance:add_instance_data(instance)
                managers.worlddefinition:prepare_for_spawn_instance(instance)
                local instance_data = managers.world_instance:get_instance_data_by_name(instance_name)
                local prepare_mission_data = managers.world_instance:prepare_mission_data_by_name(instance_name)
                local script = managers.mission._scripts[instance.script]
                if not instance_data.mission_placed then
                    script:create_instance_elements(prepare_mission_data)
                else
                    script:_preload_instance_class_elements(prepare_mission_data)
                end
            end
            BLE.ListDialog:hide()
        end
    })
end

function WData:OpenSpawnElementDialog()
    if not self:CanOpenDialog("SpawnElement") then
        return
    end

    local held_ctrl
    local elements = {}
    for _, element in pairs(BLE._config.MissionElements) do
        local name = element:gsub("Element", "")
        table.insert(elements, {name = name, element = element})
    end
    table.sort(elements, function(a,b) return b.name > a.name end)
	BLE.ListDialog:Show({
	    list = elements,
        force = true,
        no_callback = ClassClbk(self, "CloseDialog"),
        callback = function(item)
            self:BeginSpawningElements(item.element)
            self:CloseDialog()
	    end
	}) 
end

function WData:OpenSelectUnitDialog(params)
    if not self:CanOpenDialog("SelectUnit") then
        return
    end

    params = params or {}
    local units = {}
    for k, unit in pairs(World:find_units_quick("disabled", "all")) do
        local ud = unit:unit_data()
        if ud and ud.name and not ud.instance then
            if unit:enabled() or (ud.name_id and ud.continent) then
                table.insert(units, table.merge({
                    name = tostring(unit:unit_data().name_id) .. " [" .. (ud.environment_unit and "environment" or ud.sound_unit and "sound" or tostring(ud.unit_id)) .."]",
                    unit = unit,
                    color = not unit:enabled() and Color.grey,
                }, params))
            end
        end
    end
    BLE.ListDialog:Show({
        list = units,
        force = true,
        no_callback = ClassClbk(self, "CloseDialog"),
        callback = params.on_click or function(item)
            self._parent:select_unit(item.unit)         
            self:CloseDialog()
        end
    })
end

function WData:OpenSelectInstanceDialog(params)
	params = params or {}
	BLE.ListDialog:Show({
	    list = managers.world_instance:instance_names(),
        force = true,
	    callback = params.on_click or function(name)
	    	self._parent:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(name)))	        
	    	BLE.ListDialog:hide()
	    end
	})
end

function WData:OpenSelectElementDialog(params)
    if not self:CanOpenDialog("SelectElement") then
        return
    end

    params = params or {}
	local elements = {}
    local held_ctrl
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                	table.insert(elements, {
                        create_group = string.pretty2(element.class:gsub("Element", "")),
                		name = tostring(element.editor_name) .. " [" .. tostring(element.id) .."]",
                		element = element,
                	})
                end
            end
        end
    end
	BLE.ListDialog:Show({
	    list = elements,
        force = true,
        no_callback = ClassClbk(self, "CloseDialog"),        
	    callback = params.on_click or function(item)
            self._parent:select_element(item.element, held_ctrl)
            held_ctrl = ctrl()
            if not held_ctrl then
                self:CloseDialog()
            end
	    end
	}) 
end

function WData:BeginSpawningElements(element)
    self._currently_spawning_element = element
    self:BeginSpawning()
end

function WData:BeginSpawning(unit)
    self:Switch()
    self._currently_spawning = unit
    self:remove_dummy_unit()
    if self._parent._spawn_position then
        self._dummy_spawn_unit = World:spawn_unit(Idstring(unit or "units/mission_element/element"), self._parent._spawn_position)
    end
    self:GetPart("menu"):set_tabs_enabled(false)
    self:SetTitle("Press: LMB to spawn, RMB to cancel")
end

function WData:CloseDialog()
    BLE.ListDialog:hide()
    self._opened = {}
end

function WData:CanOpenDialog(name)
    if self._opened[name] then
        self:CloseDialog()
        return false
    end
    self:CloseDialog()
    self._opened[name] = true
    return true
end

function WData:OpenSpawnUnitDialog(params)
    if not self:CanOpenDialog("SpawnUnit") then
        return
    end

	params = params or {}
    local pkgs = self._assets_manager and self._assets_manager:get_level_packages()
	BLE.ListDialog:Show({
	    list = BLE.Utils:GetUnits({
			not_loaded = params.not_loaded,
			packages = pkgs,
			slot = params.slot,
			type = params.type,
			not_types = {Idstring("being"), Idstring("brush"), Idstring("wpn"), Idstring("item")},
			not_in_slot = "brushes"
		}),
        force = true,
        no_callback = ClassClbk(self, "CloseDialog"),
        callback = function(unit)
            self:CloseDialog()
	    	if type(params.on_click) == "function" then
	    		params.on_click(unit)
	    	else
                if not self._assets_manager or self._assets_manager:is_asset_loaded(unit, "unit") or not params.not_loaded then
                    if PackageManager:has(Idstring("unit"), unit:id()) then
                        self:BeginSpawning(unit)
                    else
                        BLE.Utils:Notify("Error", "Cannot spawn the unit")
                    end
                else
                    BLE.Utils:QuickDialog({title = "Well that's annoying..", no = "No", message = "This unit is not loaded and if you want to spawn it you have to load a package for it, search packages for the unit?"}, {{"Yes", function()
                        self._assets_manager:find_package(unit, true)
                    end}})
                end
			end
	    end
	}) 
end

function WData:OpenLoadDialog(params)
    local units = {}
	local ext = params.ext
    for unit in pairs(BLE.DBPaths[ext]) do
        if not unit:match("wpn_") and not unit:match("msk_") then
            table.insert(units, unit)
        end
    end
	BLE.ListDialog:Show({
	    list = units,
		force = true,
		not_loaded = true,
	    callback = params.on_click or function(asset)
            self._assets_manager:find_package(asset, ext, true)
	    end
	})
end
