--CLEAN THIS
WorldDataEditor = WorldDataEditor or class(EditorPart)
local WData = WorldDataEditor
function WData:init(parent, menu) 
    if BeardLib.current_level then
        self._continent_settings = ContinentSettingsDialog:new(BeardLibEditor._dialogs_opt)
        self._assets_manager = AssetsManagerDialog:new(BeardLibEditor._dialogs_opt)
        self._objectives_manager = ObjectivesManagerDialog:new(BeardLibEditor._dialogs_opt)
    end
    self._opened = {}
    WData.super.init(self, parent, menu, "World")
end
function WData:button_pos(near, item) item:Panel():set_righttop(near:Panel():left(), 0) end
function WData:data() return managers.worlddefinition and managers.worlddefinition._world_data end

function WData:enable()
    self:bind_opt("SpawnUnit", callback(self, self, "OpenSpawnUnitDialog"), true)
    self:bind_opt("SpawnElement", callback(self, self, "OpenSpawnElementDialog"), true)
    self:bind_opt("SelectUnit", callback(self, self, "OpenSelectUnitDialog"), true)
    self:bind_opt("SelectElement", callback(self, self, "OpenSelectElementDialog"), true)
end

function WData:loaded_continents()
    self:build_default_menu()
    for _, manager in pairs(self.layers) do
        if manager.loaded_continents then
            manager:loaded_continents()
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

function WData:build_default_menu()
    self.super.build_default_menu(self)
    self:destroy_back_button()
    local alert_opt = {divider_type = true, position = "RightTop", w = 24, h = 24}
    local function make_alert(text)
        local div = self:Divider(text, {border_color = Color.yellow, border_lock_height = false})
        self:SmallImageButton("Alert", nil, "textures/editor_icons_df", {30, 190, 72, 72}, div, {
            divider_type = true, position = "RightTop", w = 24, h = 24
        })
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

    local spawn = self:DivGroup("Spawn", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    local spawn_unit = BeardLibEditor.Options:GetValue("Input/SpawnUnit")
    local spawn_element = BeardLibEditor.Options:GetValue("Input/SpawnElement")
    local select_unit = BeardLibEditor.Options:GetValue("Input/SelectUnit")
    local select_element = BeardLibEditor.Options:GetValue("Input/SelectElement")
    self:Button("Unit", callback(self, self, "OpenSpawnUnitDialog"), {group = spawn, text = "Unit("..spawn_unit..")", size_by_text = true})
    self:Button("Element", callback(self, self, "OpenSpawnElementDialog"), {group = spawn, text = "Element("..spawn_element..")", size_by_text = true})
    self:Button("Instance", callback(self, self, "OpenSpawnInstanceDialog"), {group = spawn, size_by_text = true})
    self:Button("Prefab", callback(self, self, "OpenSpawnPrefabDialog"), {group = spawn, size_by_text = true})

    local select = self:DivGroup("Select", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    self:Button("Unit", callback(self, self, "OpenSelectUnitDialog", {}), {group = select, text = "Unit("..select_unit..")", size_by_text = true})
    self:Button("Element", callback(self, self, "OpenSelectElementDialog"), {group = select, text = "Element("..select_element..")", size_by_text = true})
    self:Button("Instance", callback(self, self, "OpenSelectInstanceDialog", {}), {group = select, size_by_text = true})

    if BeardLib.current_level then
        local load = self:DivGroup("Load", {align_method = "grid"})
        self:Button("Unit", callback(self, self, "OpenLoadUnitDialog"), {group = load, size_by_text = true})
        if FileIO:Exists(BeardLibEditor.ExtractDirectory) then
            self:Button("UnitsExtract", callback(self, self, "OpenLoadUnitDialog", {on_click = callback(self, self, "LoadUnitFromExtract"), not_loaded = true}), {
                group = load, size_by_text = true, text = "Unit(From Extract)", help = BeardLibEditor.ExtractImportHelp
            })
        end
    end

    self.layers = self.layers or {env = EnvironmentLayerEditor:new(self), sound = SoundLayerEditor:new(self), portal = PortalLayerEditor:new(self)}
    local managers = {
        ["AI"] = true, 
        ["environment"] = self.layers.env, 
        ["sound"] = self.layers.sound, 
        ["wires"] = true, 
        ["portal"] = self.layers.portal, 
    }
    local managers_group = self:DivGroup("Managers")
    self:Button("Assets", self._assets_manager and ClassClbk(self._assets_manager, "Show") or nil, {group = managers_group, enabled = BeardLib.current_level ~= nil})
    self:Button("Objectives", self._objectives_manager and ClassClbk(self._objectives_manager, "Show") or nil, {group = managers_group, enabled = BeardLib.current_level ~= nil})

    for name, layer in pairs(managers) do
        self:Button(name, ClassClbk(self, "build_menu", name:lower(), layer), {
            enabled = not Global.editor_safe_mode,
            group = managers_group,
            text = string.capitalize(name)
        })
    end
 
    self:reset()

    local fixes = self:DivGroup("Fixes", {help = "Quick fixes for common issues"})
    if self._assets_manager then
        self:Button("Clean add.xml", ClassClbk(self._assets_manager, "clean_add_xml"), {group = fixes, help = "This removes unused files from the add.xml and cleans duplicates"})
    end
    self:Button("Remove brush(massunits) layer", ClassClbk(self, "remove_brush_layer"), {
        group = fixes,
        help = "Brushes/Mass units are small decals in the map such as garbage on floor and such, sadly the editor has no way of editing it, the best you can do is remove it."
    })

    self:build_continents()
end


function WData:remove_brush_layer()
    BeardLibEditor.Utils:YesNoQuestion("This will remove the brush layer from your level, this cannot be undone from the editor.", function()
        self:data().brush = nil
        MassUnitManager:delete_all_units()
        self:save()
        self:GetPart("opt"):save()
    end)
end

local function base_button_pos(item)
    local p = item:Panel():parent()
    item:Panel():set_world_righttop(p:world_righttop())
end

--Continents
function WData:build_continents()
    local opt = {items_size = 18, size_by_text = true, texture = "textures/editor_icons_df", position = "RightTop"}
    local prev
    local function toolbar_item(name, clbk, toolbar, o)
        o = table.merge(clone(opt), o)
        if prev and prev.override_panel ~= toolbar and prev.panel ~= toolbar then
            prev = nil
        end
        if prev then
            o.position = callback(self, self, "button_pos", prev)
        end
        local item
        if o.text then
            item = self:SmallButton(name, clbk, toolbar, o)
        else
            item = self:SmallImageButton(name, clbk, nil, nil, toolbar, o)
        end
        prev = item
    end

    if managers.worlddefinition then
        local continents = self:DivGroup("Continents")
        toolbar_item("NewContinent", ClassClbk(self, "new_continent"), continents, {text = "+", help = "Add continent"})
        for name, data in pairs(managers.worlddefinition._continent_definitions) do
            local continent = self:Group(name, {group = continents, text = name})
            toolbar_item("Remove", ClassClbk(self, "remove_continent", name), continent, {highlight_color = Color.red, texture_rect = {184, 2, 48, 48}})
            toolbar_item("ClearUnits", ClassClbk(self, "clear_all_units_from_continent", name), continent, {highlight_color = Color.red, texture_rect = {7, 2, 48, 48}})
            toolbar_item("Settings", ClassClbk(self, "open_continent_settings", name), continent, {texture_rect = {385, 385, 115, 115}})
            toolbar_item("SelectUnits", ClassClbk(self, "select_all_units_from_continent", name), continent, {texture_rect = {122, 1, 48, 48}})
            toolbar_item("AddScript", ClassClbk(self, "add_new_mission_script", name), continent, {text = "+", help = "Add mission script"})
            for sname, data in pairs(managers.mission._missions[name]) do
                local script = self:Divider(sname, {border_color = Color.green, group = continent, text = sname, offset = {8, 4}})
                opt.continent = name
                toolbar_item("RemoveScript", ClassClbk(self, "remove_script", sname), script, {highlight_color = Color.red, texture_rect = {184, 2, 48, 48}})
                toolbar_item("ClearElements", ClassClbk(self, "clear_all_elements_from_script", sname), script, {highlight_color = Color.red, texture_rect = {7, 2, 48, 48}})
                toolbar_item("Rename", ClassClbk(self, "rename_script", sname), script, {texture_rect = {66, 1, 48, 48}})
                toolbar_item("SelectElements", ClassClbk(self, "select_all_units_from_script", sname), script, {texture_rect = {122, 1, 48, 48}})
            end
        end
    end
end

function WData:open_continent_settings(continent)
    self._continent_settings:Show({continent = continent, callback = callback(self, self, "build_default_menu")})
end

function WData:remove_brush_layer()
    BeardLibEditor.Utils:YesNoQuestion("This will remove the brush layer from your level, this cannot be undone from the editor.", function()
        self:data().brush = nil
        MassUnitManager:delete_all_units()
        self:save()
    end)
end

function WData:remove_continent(continent)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the continent!", function()
        self:clear_all_units_from_continent(continent, true, true)
        managers.mission._missions[continent] = nil
        managers.worlddefinition._continents[continent] = nil
        managers.worlddefinition._continent_definitions[continent] = nil
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
        self:build_default_menu()
    end)
end

function WData:select_all_units_from_continent(continent)
    local selected_units = {}
    for k, static in pairs(managers.worlddefinition._continent_definitions[continent].statics) do
        if static.unit_data and static.unit_data.unit_id then
            local unit = managers.worlddefinition:get_unit_on_load(static.unit_data.unit_id)
            if alive(unit) then
                table.insert(selected_units, unit)
            end
        end
    end        
    self:GetPart("mission"):remove_script()
    self:GetPart("static")._selected_units = selected_units
    self:GetPart("static"):set_selected_unit()
end

function WData:clear_all_units_from_continent(continent, no_refresh, no_dialog)
    function delete_all()
        local worlddef = managers.worlddefinition
        for k, static in pairs(worlddef._continent_definitions[continent].statics) do
            if static.unit_data and static.unit_data.unit_id then
                local unit = worlddef:get_unit_on_load(static.unit_data.unit_id)
                if alive(unit) then
                    worlddef:delete_unit(unit)
                    World:delete_unit(unit)
                end
            end
        end
        worlddef._continent_definitions[continent].editor_groups = {}
        worlddef._continent_definitions[continent].statics = {}
        if no_refresh ~= true then
            self._parent:load_continents(managers.worlddefinition._continent_definitions)
            self:build_default_menu()
        end
    end
    if no_dialog == true then
        delete_all()
    else
        BeardLibEditor.Utils:YesNoQuestion("This will delete all units in the continent!", delete_all)
    end
end

function WData:new_continent()
    local worlddef = managers.worlddefinition
    BeardLibEditor.InputDialog:Show({title = "Continent name", text = "", callback = function(name)
        if name == "" then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
                self:new_continent()
            end})
            return
        elseif name == "environments" or string.begins(name, " ") then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:new_continent()
            end})
            return
        elseif worlddef._continent_definitions[name] then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Continent name already taken!", callback = function()
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
    BeardLibEditor.InputDialog:Show({title = "Mission script name", text = "", callback = function(name)
        if name == "" then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        elseif string.begins(name, " ") then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        elseif mission._scripts[name] then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Mission script name already taken!", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
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

function WData:remove_script(script, menu, item)
    BeardLibEditor.Utils:YesNoQuestion("This will delete the mission script including all elements inside it!", function()
        local mission = managers.mission
        self:_clear_all_elements_from_script(script, item.continent, true, true)
        mission._missions[item.continent][script] = nil
        mission._scripts[script] = nil
        self:build_default_menu()  
    end)
end

function WData:rename_script(script, menu, item)
    local mission = managers.mission
    BeardLibEditor.InputDialog:Show({title = "Rename Mission script to", text = script, callback = function(name)
        if name == "" then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:rename_script(script, menu, item)
            end})
            return
        elseif string.begins(name, " ") then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_script(script, menu, item)
            end})
            return
        elseif mission._scripts[name] then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Mission script name already taken", callback = function()
                self:rename_script(script, menu, item)
            end})
            return
        end
        mission._scripts[script]._name = name
        mission._scripts[name] = mission._scripts[script]
        mission._scripts[script] = nil
        mission._missions[item.continent][name] = deep_clone(mission._missions[item.continent][script])
        mission._missions[item.continent][script] = nil
        self._parent:load_continents(managers.worlddefinition._continent_definitions)
    end})
end

function WData:clear_all_elements_from_script(script, menu, item)
    self:_clear_all_elements_from_script(script, item.continent)
end

function WData:delete_unit(unit)
    for  _, manager in pairs(self.layers) do
        if manager.delete_unit then
            manager:delete_unit(unit)
        end
    end
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
        BeardLibEditor.Utils:YesNoQuestion("This will delete all elements in the mission script!", delete_all)
    end
end

function WData:select_all_units_from_script(script, menu, item)
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

--World Data
function WData:destroy_back_button()
    local btn = self._menu:GetItem("Back")
    if btn then
        btn:Destroy()
    end
end

function WData:back_button()
    self:destroy_back_button()
    self:SmallButton("Back", callback(self, self, "build_default_menu"), self._menu:GetItem("Title"), {
        text_offset = 4,
        max_width = false,
        highlight_color = Color.black:with_alpha(0.25), font_size = 18
    })
end

function WData:build_menu(name, layer)
    self.super.build_default_menu(self)
    self:back_button()
    self._current_layer = name
    if type(layer) == "table" then
        layer:build_menu()
    else
        self["build_"..name.."_layer_menu"](self)
    end
end

function WData:build_wires_layer_menu()
    local existing_wires = self:Group("Existing")
    managers.worlddefinition._world_data.wires = managers.worlddefinition._world_data.wires or {}
    for _, wire in pairs(managers.worlddefinition._world_data.wires) do
        local ud = wire.unit_data
        self:Button(ud.name_id, callback(self._parent, self._parent, "select_unit", managers.worlddefinition:get_unit(ud.unit_id)), {group = existing_wires})
    end
    local loaded_wires = self:Group("Spawn")
    for _, wire in pairs(BeardLibEditor.Utils:GetUnits({type = "wire", packages = self._assets_manager:get_level_packages()})) do
        self:Button(wire, function()
            self:BeginSpawning(wire)
        end, {group = loaded_wires})
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
    self:ComboBox("GroupState", function(menu, item)
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
    for _, editor in pairs(self.layers) do
        if editor.reset_selected_units then
            editor:reset_selected_units()
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

-- From old utils menu.

function WData:LoadUnitFromExtract(unit) self._assets_manager:load_from_extract({[unit] = true}) end

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
            self._parent:SpawnUnit(self._currently_spawning)
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
    for name, prefab in pairs(BeardLibEditor.Prefabs) do
        table.insert(prefabs, {name = name, prefab = prefab})
    end
    BeardLibEditor.ListDialog:Show({
        list = prefabs,
        force = true,
        callback = function(item)
            self:GetPart("static"):SpawnPrefab(item.prefab)
            BeardLibEditor.ListDialog:hide()
        end
    }) 
end

function WData:OpenSpawnInstanceDialog()
    local instances = table.map_keys(BeardLib.managers.MapFramework._loaded_instances)
    for _, path in pairs(BeardLibEditor.Utils:GetEntries({type = "world"})) do
        if path:match("levels/instances") then
            table.insert(instances, path)
        end
    end
    BeardLibEditor.ListDialog:Show({
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
            BeardLibEditor.ListDialog:hide()
        end
    })
end

function WData:OpenSpawnElementDialog()
    if not self:CanOpenDialog("SpawnElement") then
        return
    end

    local held_ctrl
    local elements = {}
    for _, element in pairs(BeardLibEditor._config.MissionElements) do
        local name = element:gsub("Element", "")
        table.insert(elements, {name = name, element = element})
    end
    table.sort(elements, function(a,b) return b.name > a.name end)
	BeardLibEditor.ListDialog:Show({
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
    BeardLibEditor.ListDialog:Show({
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
	BeardLibEditor.ListDialog:Show({
	    list = managers.world_instance:instance_names(),
        force = true,
	    callback = params.on_click or function(name)
	    	self._parent:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(name)))	        
	    	BeardLibEditor.ListDialog:hide()
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
	BeardLibEditor.ListDialog:Show({
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
    BeardLibEditor.ListDialog:hide()
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
	BeardLibEditor.ListDialog:Show({
	    list = BeardLibEditor.Utils:GetUnits({not_loaded = params.not_loaded, packages = pkgs, slot = params.slot, type = params.type, not_type = "being"}),
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
                        BeardLibEditor.Utils:Notify("Error", "Cannot spawn the unit")
                    end
                else
                    BeardLibEditor.Utils:QuickDialog({title = "Well that's annoying..", no = "No", message = "This unit is not loaded and if you want to spawn it you have to load a package for it, search packages for the unit?"}, {{"Yes", function()
                        self._assets_manager:find_package(unit, true)
                    end}})
                end
			end
	    end
	}) 
end

function WData:OpenLoadUnitDialog(params)
    local units = {}
    local unit_ids = Idstring("unit")
    for _, unit in pairs(BeardLibEditor.DBPaths.unit) do
        if not PackageManager:has(unit_ids, unit:id()) and not unit:match("wpn_") and not unit:match("msk_") then
            table.insert(units, unit)
        end
    end
	BeardLibEditor.ListDialog:Show({
	    list = units,
        force = true,
	    callback = params.on_click or function(unit)
            BeardLibEditor.ListDialog:hide()
            self._assets_manager:find_package(unit, true)
	    end
	}) 
end