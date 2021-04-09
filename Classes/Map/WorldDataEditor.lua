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

function WData:destroy()
    if self._continent_settings then
        self._continent_settings:Destroy()
        self._assets_manager:Destroy()
        self._objectives_manager:Destroy()
    end
    for _, layer in pairs(self.layers) do
        layer:destroy()
    end
end

function WData:enable()
    WData.super.enable(self)
    self:bind_opt("SpawnUnit", ClassClbk(self, "OpenSpawnUnitDialog"))
    self:bind_opt("SpawnElement", ClassClbk(self, "OpenSpawnElementDialog"))
    self:bind_opt("SelectUnit", ClassClbk(self, "OpenSelectUnitDialog"))
    self:bind_opt("SelectElement", ClassClbk(self, "OpenSelectElementDialog"))
    if BeardLib.current_level then
        self:bind_opt("LoadUnit", ClassClbk(self, "OpenLoadDialog", {ext = "unit"}))
    end
    if FileIO:Exists(BLE.ExtractDirectory) then
        self:bind_opt("LoadUnitFromExtract", ClassClbk(self, "OpenLoadDialog", {on_click = ClassClbk(self, "LoadFromExtract", "unit"), ext = "unit"}))
    end
end

function WData:loaded_continents(continents, current_continent)
    self:build_default_menu()

    self:GetPart("mission"):set_elements_vis()

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
    local managers = {"main", "environment", "sound", "wires", "portal", "groups", "ai"}
    self._current_layer = "main"
    for i, name in pairs(managers) do
        self._tabs:tb_btn(name, ClassClbk(self, "build_menu", name:lower()), {
            enabled = not Global.editor_safe_mode,
            text = name == "ai" and "AI" or string.capitalize(name),
            border_bottom = i == 1
        })
    end
end

function WData:build_default()
    self.layers = self.layers or {
        environment = EnvironmentLayerEditor:new(self), 
        sound = SoundLayerEditor:new(self), 
        portal = PortalLayerEditor:new(self),
        ai = AiLayerEditor:new(self),
    }

    if not BeardLib.current_level then
        local s = "Preview mode"
        s = s .. "\nSaving the map will not clone the map, it'll just save it."
        s = s .. "\nIf you wish to clone it please use the 'Clone Existing Heist' feature in projects menu."
        self:alert(s)
    end
    local has_extract = FileIO:Exists(BLE.ExtractDirectory)
    if not has_extract then
        self:alert("You don't have an extract directory\nSome features will not work!")
    end
    if Global.editor_safe_mode then
        local warn = self:alert("Safe mode\nMost features are disabled")
        warn:tb_btn("Load normal mode", function()
            BLE.Utils:YesNoQuestion("Are you sure you want to load into normal mode?", function()
                managers.game_play_central:restart_the_game()
                Global.editor_safe_mode = nil
            end)
        end)
    end
    if not self._parent._has_fix then
        self:alert("Physics settings fix is not installed\nsome features are disabled.")
    end

    local spawn = self:divgroup("Spawn", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    local spawn_unit = BLE.Options:GetValue("Input/SpawnUnit")
    local spawn_element = BLE.Options:GetValue("Input/SpawnElement")
    local select_unit = BLE.Options:GetValue("Input/SelectUnit")
    local select_element = BLE.Options:GetValue("Input/SelectElement")
    local load_unit = BLE.Options:GetValue("Input/LoadUnit")
    local load_unit_fe = BLE.Options:GetValue("Input/LoadUnitFromExtract")
    spawn:s_btn("Unit", ClassClbk(self, "OpenSpawnUnitDialog"), {text = "Unit("..spawn_unit..")"})
    spawn:s_btn("Element", ClassClbk(self, "OpenSpawnElementDialog"), {text = "Element("..spawn_element..")"})
    spawn:s_btn("Instance", ClassClbk(self, "OpenSpawnInstanceDialog"))
    spawn:s_btn("Prefab", ClassClbk(self, "OpenSpawnPrefabDialog"))

    local select = self:divgroup("Select", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    select:s_btn("Unit", ClassClbk(self, "OpenSelectUnitDialog"), {text = "Unit("..select_unit..")"})
    select:s_btn("Element", ClassClbk(self, "OpenSelectElementDialog"), {text = "Element("..select_element..")"})
    select:s_btn("Instance", ClassClbk(self, "OpenSelectInstanceDialog", {}))

    local load = self:divgroup("Load", {enabled = BeardLib.current_level ~= nil, align_method = "grid"})
    local load_extract = self:divgroup("LoadFromExtract", {enabled = has_extract, align_method = "grid"})

    local spawn_help = "Load and spawn. This list selector will close itself after selecting a unit and will let you begin spawning the unit when it's fully loaded!"
    load:s_btn(ext, ClassClbk(self, "OpenLoadDialog", {ext = "unit", spawn = true}), {text = "Spawn Unit("..load_unit..")", help = spawn_help})
    load_extract:s_btn(ext, ClassClbk(self, "OpenLoadDialog", {on_click = extract_clbk, ext = "unit", spawn = true}), {text = "Spawn Unit("..load_unit_fe..")", help = spawn_help})

    for _, ext in pairs(BLE.UsableAssets) do
        local text = ext:capitalize()
        load:s_btn(ext, ClassClbk(self, "OpenLoadDialog", {ext = ext}), {text = text})
        load_extract:s_btn(ext, ClassClbk(self, "OpenLoadDialog", {on_click = ClassClbk(self, "LoadFromExtract", ext), ext = ext}), {text = text})
    end

    local mng = self:divgroup("Managers", {align_method = "grid", enabled = BeardLib.current_level ~= nil})
    mng:s_btn("Assets", self._assets_manager and ClassClbk(self._assets_manager, "Show") or nil)
    mng:s_btn("Objectives", self._objectives_manager and ClassClbk(self._objectives_manager, "Show") or nil)

    self:reset()

    self:build_continents()
end

function WData:LoadFromExtract(ext, asset, clbk)
    self._assets_manager:load_from_extract_dialog({[ext] = {[asset] = true}}, clbk)
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
    local all_continents = self._parent._continents
    if all_continents then
        local continents = self:group("Continents")
        local toolbar = continents:GetToolbar()
        local all_scripts = table.map_keys(managers.mission._scripts)
        self._current_continent = continents:combobox("CurrentContinent", ClassClbk(self, "set_current_continent"), all_continents, table.get_key(all_continents, self._parent._current_continent) or 1)
        self._current_script = continents:combobox("CurrentScript", ClassClbk(self, "set_current_script"), all_scripts, table.get_key(all_scripts, self._parent._current_script) or 1)    
        local icons = BLE.Utils.EditorIcons

        toolbar:tb_imgbtn("NewContinent", ClassClbk(self, "new_continent"), tx, icons.plus, {help = "Add continent"})
        for name, data in pairs(managers.worlddefinition._continent_definitions) do
            local continent = continents:group(name, {text = name})
            local ctoolbar = continent:GetToolbar()
            ctoolbar:tb_imgbtn("Remove", ClassClbk(self, "remove_continent", name), tx, {184, 2, 48, 48}, {highlight_color = Color.red})
            ctoolbar:tb_imgbtn("ClearUnits", ClassClbk(self, "clear_all_units_from_continent", name), tx, {7, 2, 48, 48}, {highlight_color = Color.red})
            ctoolbar:tb_imgbtn("Settings", ClassClbk(self, "open_continent_settings", name), tx, {385, 385, 115, 115})
            ctoolbar:tb_imgbtn("SelectUnits", ClassClbk(self, "select_all_units_from_continent", name), tx, {122, 1, 48, 48})
            ctoolbar:tb_imgbtn("AddScript", ClassClbk(self, "add_new_mission_script", name), tx, icons.plus, {help = "Add mission script"})
            ctoolbar:tb_imgbtn("SetVisible", function(item) 
                local alpha = self:toggle_unit_visibility(name) and 1 or 0.5
                item.enabled_alpha = alpha
                item:SetEnabled(item.enabled)
            end, tx, {155, 95, 64, 64})

            for sname, data in pairs(managers.mission._missions[name]) do
                local script = continent:divider(sname, {continent = name, align_method = "grid_from_right", border_color = Color.green, text = sname, offset = {8, 4}})
                script:tb_imgbtn("RemoveScript", ClassClbk(self, "remove_script", sname), tx, {184, 2, 48, 48}, {highlight_color = Color.red})
                script:tb_imgbtn("ClearElements", ClassClbk(self, "clear_all_elements_from_script", sname), tx, {7, 2, 48, 48}, {highlight_color = Color.red})
                script:tb_imgbtn("Rename", ClassClbk(self, "rename_script", sname), tx, {66, 1, 48, 48})
                script:tb_imgbtn("SelectElements", ClassClbk(self, "select_all_units_from_script", sname), tx, {122, 1, 48, 48})
            end
        end
    end
end

function WData:set_current_script(item)
    self._parent._current_script = item:SelectedItem()
    self:GetPart("mission"):set_elements_vis()
end

function WData:set_current_continent(item) 
    self._parent._current_continent = item:SelectedItem()
end

function WData:open_continent_settings(continent)
    self._continent_settings:Show({continent = continent, callback = ClassClbk(self, "build_default_menu")})
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

        if cname == "world" and name ~= "default" and not mission._missions[cname].default then
            BLE.Dialog:Show({
                title = "WARNING!", 
                message = "First mission script name for the world continent must always be named 'default'"
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

function WData:select_all_units_from_continent(continent)
    local static = self:GetPart("static")
    local selected_units = {}
    local _selected_units = static._selected_units
    local pressed_ctrl = ctrl()

    for _, unit in pairs(self:get_all_units_from_continent(continent)) do
        table.insert(pressed_ctrl and _selected_units or selected_units, unit)
    end
    self:GetPart("mission"):remove_script()
    if not ctrl() then
        static._selected_units = selected_units
    end
    static:set_selected_unit()
end

function WData:select_all_units_from_script(script, item)
    local static = self:GetPart("static")
    local selected_units = {}
    local _selected_units = static._selected_units
    local pressed_ctrl = ctrl()
    for _, unit in pairs(self:GetPart("mission")._units) do
        if unit:mission_element() then
            local element = unit:mission_element().element
            if element.script == script then
                table.insert(pressed_ctrl and _selected_units or selected_units, unit)
            end
        end
    end
    self:GetPart("mission"):remove_script()
    if not pressed_ctrl then
        static._selected_units = selected_units
    end
    static:set_selected_unit()    
end

function WData:build_menu(name, item)
    self:clear_menu()
    self._current_layer = name
    local layer = self.layers[name]
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = false})
    end
    item = item or self._tabs:GetItem(name)
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
    local existing_wires = self:group("Existing")
    managers.worlddefinition._world_data.wires = managers.worlddefinition._world_data.wires or {}
    for _, wire in pairs(managers.worlddefinition._world_data.wires) do
        local ud = wire.unit_data
        existing_wires:button(ud.name_id, ClassClbk(self._parent, "select_unit", managers.worlddefinition:get_unit(ud.unit_id)))
    end
    local loaded_wires = self:group("Spawn")
    for _, wire in pairs(BLE.Utils:GetUnits({type = "wire", packages = self._assets_manager and self._assets_manager:get_level_packages() or {}})) do
        loaded_wires:button(wire, function() self:BeginSpawning(wire) end)
    end
end

function WData:build_groups_layer_menu()
    local tx  = "textures/editor_icons_df"

    local groups = self:pan("Groups", {offset = 2, auto_align = false})
    local continents = managers.worlddefinition._continent_definitions
    for _, continent in pairs(self._parent._continents) do
        if continents[continent].editor_groups then
            for _, editor_group in pairs(continents[continent].editor_groups) do
                if editor_group.units then
                    local group = groups:group(editor_group.name, {text = editor_group.name, auto_align = false, closed = true})
                    local toolbar = group:GetToolbar()
                    toolbar:tb_imgbtn("Remove", function() 
                        BLE.Utils:YesNoQuestion("This will delete the group", function()
                            self:GetPart("static"):remove_group(nil, editor_group)
                            self:build_menu("groups")
                        end)
                    end, tx, {184, 2, 48, 48}, {highlight_color = Color.red})
                    toolbar:tb_imgbtn("Rename", function() 
                        BLE.InputDialog:Show({title = "Group Name", text = group.name, callback = function(name)
                            self:GetPart("static"):set_group_name(nil, editor_group, name)
                            self:build_menu("groups")
                        end})
                    end, tx, {66, 1, 48, 48})
                    toolbar:tb_imgbtn("SelectGroup", ClassClbk(self:GetPart("static"), "select_group", editor_group), tx, {122, 1, 48, 48})
                    toolbar:tb_imgbtn("SetVisible", function(item) 
                        self:GetPart("static"):toggle_group_visibility(editor_group) 
                        item.enabled_alpha = editor_group.visible and 1 or 0.5
                        item:SetEnabled(item.enabled)
                    end, tx, {155, 95, 64, 64}, {enabled_alpha = editor_group.visible ~= nil and (editor_group.visible and 1 or 0.5) or 1})

                    for _, unit_id in pairs(editor_group.units) do
                        local unit = managers.worlddefinition:get_unit(unit_id)
                        if alive(unit) then
                            group:button(tostring(unit_id), ClassClbk(self._parent, "select_unit", unit), {text = unit:editor_id() .. "/" .. tostring(unit_id)})
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
        self:divider("No groups found in the map.")
    end
end

--[[function WData:build_ai_layer_menu()    
    local states = {
        "empty",
        "airport",
        "besiege",
        "street",
        "zombie_apocalypse"
    }
    self:combobox("GroupState", function(item)
        self:data().ai_settings.ai_settings.group_state = item:SelectedItem()
    end, states, table.get_key(states, self:data().ai_settings.ai_settings.group_state))
    self:button("SpawnNavSurface", ClassClbk(self, "BeginSpawning", "core/units/nav_surface/nav_surface"))
    self:button("SpawnCoverPoint", ClassClbk(self, "BeginSpawning", "units/dev_tools/level_tools/ai_coverpoint"))
end]]

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
    if not self:enabled() then
        return
    end

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
        if self._do_switch and self:Val("SelectAndGoToMenu") then
            self:GetPart("static"):Switch()
            self._do_switch = false
        end
        return true
    end
    return false
end

function WData:get_dummy_unit()
    return self._dummy_spawn_unit
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
        if self._parent._current_rot then
            self._dummy_spawn_unit:set_rotation(self._parent._current_rot)
        end
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
        callback = function(instance)
            self:SpawnInstance(instance, nil, true)
            BLE.ListDialog:hide()
        end
    })
end

function WData:SpawnInstance(instance, instance_data, spawn)
    instance_data = instance_data or {}
    local continent = managers.worlddefinition._continent_definitions[self._parent._current_continent]
    if continent then
        continent.instances = continent.instances or {}
        local instance_name = instance_data.name
        if not instance_name then
            instance_name = Path:GetFileName(Path:GetDirectory(instance)).."_"
            local instance_names = managers.world_instance:instance_names()
            local i = 1
            while(table.contains(instance_names, instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i)) do
                i = i + 1
            end
            instance_name = instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i
        end

        local module_data = BeardLib.managers.MapFramework._loaded_instances[instance]
        local index_size = module_data and module_data._config.index_size or self:Val("InstanceIndexSize")

        if not managers.mission:script(instance_data.script) then
            instance_data.script = nil
        end

        instance_data.start_index = nil

        local instance = table.merge({
            continent = self._parent._current_continent,
            name = instance_name,
            folder = instance,
            position = self._parent:cam_spawn_pos(),
            rotation = Rotation(),
            script = self._parent._current_script,
            index_size = index_size,
            start_index = managers.world_instance:get_safe_start_index(index_size, self._parent._current_continent)
        }, instance_data)
        table.insert(continent.instances, instance)
        for _, mission in pairs(managers.mission._missions) do
            if mission[instance.script] then
                table.insert(mission[instance.script].instances, instance_name)
                break
            end
        end
        managers.world_instance:add_instance_data(instance)
        local units = managers.worlddefinition:prepare_for_spawn_instance(instance)
        local data = managers.world_instance:get_instance_data_by_name(instance_name)
        local prepare_mission_data = managers.world_instance:prepare_mission_data_by_name(instance_name)
        local script = managers.mission._scripts[instance.script]
        if not data.mission_placed then
            script:create_instance_elements(prepare_mission_data)
        else
            script:_preload_instance_class_elements(prepare_mission_data)
        end

        local unit = FakeObject:new(data, {instance = true})
        if spawn then
            self:GetPart("static"):set_selected_unit(unit)
        end
        return unit
    end

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
    local held_ctrl
    for k, unit in pairs(World:find_units_quick("disabled", "all")) do
        local ud = unit:unit_data()
        if ud and ud.name and not ud.instance then
            if unit:enabled() or (ud.name_id and ud.continent) then
                table.insert(units, {
                    create_group = ud.name,
                    name = tostring(unit:unit_data().name_id) .. " [" .. (ud.environment_unit and "environment" or ud.sound_unit and "sound" or tostring(ud.unit_id)) .."]",
                    unit = unit,
                    color = not unit:enabled() and Color.grey,
                })
            end
        end
    end
    BLE.MSLD:Show({
        list = units,
        force = true,
        no_callback = ClassClbk(self, "CloseDialog"),
        search_check = function(item, filters, data)
            local unit_type = data.unit:type()
            for _, str in pairs(filters) do
                local type = str:match("type%%:%% (%w+)")
                if type then
                    type = Idstring(type)
                    if unit_type == type then
                        return true
                    end
                end
            end
            return false
        end,
        callback = params.on_click or function(item)
            held_ctrl = ctrl()
            self._parent:select_unit(item.unit, held_ctrl)
            if not held_ctrl then
                self:CloseDialog()
            end
        end,
        select_multi_clbk = function(items)
            self:part("static"):reset_selected_units()
            for _, item in pairs(items) do
                self._parent:select_unit(item.unit, true)
                if not held_ctrl then
                    self:CloseDialog()
                end
            end
        end
    })
end

function WData:OpenSelectInstanceDialog(params)
	params = params or {}
	BLE.MSLD:Show({
	    list = managers.world_instance:instance_names(),
        force = true,
	    callback = params.on_click or function(name)
	    	self._parent:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(name)))
	    	self:CloseDialog()
        end,
        select_multi_clbk = function(items)
            self:part("static"):reset_selected_units()
            for _, name in pairs(items) do
                self._parent:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(name)), true)
                if not held_ctrl then
                    self:CloseDialog()
                end  
            end
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
                for _, element in pairs(tbl.elements) do
                	table.insert(elements, {
                        create_group = string.pretty2(element.class:gsub("Element", "")),
                		name = tostring(element.editor_name) .. " [" .. tostring(element.id) .."]",
                		element = element,
                	})
                end
            end
        end
    end
	BLE.MSLD:Show({
	    list = elements,
        force = true,
        no_callback = ClassClbk(self, "CloseDialog"),
	    callback = params.on_click or function(item)
            held_ctrl = ctrl()
            self._parent:select_element(item.element, held_ctrl)
            if not held_ctrl then
                self:CloseDialog()
            end
	    end,
        select_multi_clbk = function(items)
            self:part("static"):reset_selected_units()
            for _, item in pairs(items) do
                self._parent:select_element(item.element, true)
                if not held_ctrl then
                    self:CloseDialog()
                end
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
    BLE.MSLD:hide()
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
	BLE.MSLD:Show({
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
                        self._assets_manager:find_package(unit, "unit", true)
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
    local do_spawn = ext == "unit" and params.spawn
	BLE.ListDialog:Show({
	    list = units,
		force = true,
		not_loaded = true,
        callback = function(asset)
            if do_spawn then
                self:CloseDialog()
            end
            local function start_spawning()
                if do_spawn then
                    if PackageManager:has(Idstring("unit"), asset:id()) then
                        self:BeginSpawning(asset)
                    end
                end
            end
            if do_spawn and PackageManager:has(Idstring("unit"), asset:id()) then
                start_spawning()
            else
                if params.on_click then
                    params.on_click(asset, start_spawning)
                else
                    self._assets_manager:find_package(asset, ext, true, start_spawning)
                end
            end
	    end
	})
end

function WData:refresh()
    self:build_menu(self._current_layer)
end