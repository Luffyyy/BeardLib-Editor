WorldDataEditor = WorldDataEditor or class(EditorPart)
local WData = WorldDataEditor
function WData:init(parent, menu) self.super.init(self, parent, menu, "World") end
function WData:button_pos(near, item) item:Panel():set_righttop(near:Panel():left(), 0) end
function WData:data() return managers.worlddefinition and managers.worlddefinition._world_data end

function WData:loaded_continents()
    self:build_default_menu()
    for _, manager in pairs(self.managers) do
        if manager.loaded_continents then
            manager:loaded_continents()
        end
    end
end

function WData:do_spawn_unit(unit, data)
    for _, manager in pairs(self.managers) do
        if manager.is_my_unit and manager:is_my_unit(unit:id())  then
            return manager:do_spawn_unit(unit, data)
        end
    end
end

function WData:is_world_unit(unit)
    unit = unit:id()
    for _, manager in pairs(self.managers) do
        if manager.is_my_unit and manager:is_my_unit(unit) then
            return true
        end
    end
    return false
end

function WData:build_unit_menu()
    local selected_unit = self:selected_unit()
    for _, manager in pairs(self.managers) do
        if manager.build_unit_menu and manager:is_my_unit(selected_unit:name():id()) then
            manager:build_unit_menu()
        end
    end
end

function WData:update_positions()
    local selected_unit = self:selected_unit()
    if selected_unit then
        for _, manager in pairs(self.managers) do
            if manager.save and manager:is_my_unit(selected_unit:name():id()) then
                manager:save()
            end
        end
    end
end

function WData:build_default_menu()
    self.super.build_default_menu(self)
    self.managers = self.managers or {env = EnvironmentLayerEditor:new(self), sound = SoundLayerEditor:new(self), portal = PortalLayerEditor:new(self)}
    local layers = self:DivGroup("Layers")
    for _, layer in pairs({"ai", {name = "environment", class = self.managers.env}, {name = "sound", class = self.managers.sound}, "wires", {name = "portal", class = self.managers.portal}}) do
        local tbl = type(layer) == "table"
        self:Button(tbl and layer.name or layer, callback(self, self, "build_menu", tbl and layer.class or layer), {group = layers})
    end
    self:reset()
    self:build_continents()
end

local function base_button_pos(item)
    local p = item:Panel():parent()
    item:Panel():set_world_righttop(p:world_righttop())
end

--Continents
function WData:build_continents()
    if managers.worlddefinition then
        local continents = self:DivGroup("Continents")
        self:SmallButton("NewContinent", callback(self, self, "new_continent"), continents, {text = "+", position = "TopRight"})
        for name, data in pairs(managers.worlddefinition._continent_definitions) do
            local continent = self:DivGroup(name, {group = continents, text = name, border_lock_height = false})
            local opt = {items_size = 18, size_by_text = true, align = "center", texture = "textures/editor_icons_df", position = base_button_pos}
            opt.marker_highlight_color = Color.red
            local btn = self:SmallImageButton("Remove", callback(self, self, "remove_continent", name), nil, {184, 2, 48, 48}, continent, opt)
            local r = btn
            opt.position = callback(self, self, "button_pos", btn)
            local btn = self:SmallImageButton("ClearUnits", callback(self, self, "clear_all_units_from_continent", name), nil, {7, 2, 48, 48}, continent, opt)
            opt.position = callback(self, self, "button_pos", btn)
            opt.marker_highlight_color = nil
            local btn = self:SmallImageButton("Rename", callback(self, self, "rename_continent", name), nil, {66, 1, 48, 48}, continent, opt)
            opt.position = callback(self, self, "button_pos", btn)
            self:SmallImageButton("SelectUnits", callback(self, self, "select_all_units_from_continent", name), nil, {122, 1, 48, 48}, continent, opt)
            self:Button("NewMissionScript", callback(self, self, "add_new_mission_script"), {group = continent, offset = {16, 2}, continent = name})
            for sname, data in pairs(managers.mission._missions[name]) do
                local script = self:Divider(sname, {group = continent, text = sname, offset = {16, 4}})
                opt.marker_highlight_color = Color.red
                opt.position = base_button_pos
                opt.continent = name
                local btn = self:SmallImageButton("Remove", callback(self, self, "remove_script", sname), nil, {184, 2, 48, 48}, script, opt)
                opt.position = callback(self, self, "button_pos", btn)
                local btn = self:SmallImageButton("ClearElements", callback(self, self, "clear_all_elements_from_script", sname), nil, {7, 2, 48, 48}, script, opt)
                opt.position = callback(self, self, "button_pos", btn)
                opt.marker_highlight_color = nil
                local btn = self:SmallImageButton("Rename", callback(self, self, "rename_script", sname), nil, {66, 1, 48, 48}, script, opt)
                opt.position = callback(self, self, "button_pos", btn)
                self:SmallImageButton("SelectElements", callback(self, self, "select_all_units_from_script", sname), nil, {122, 1, 48, 48}, script, opt)
            end
        end
    end
end

function WData:rename_continent(continent)
    BeardLibEditor.managers.InputDialog:Show({title = "Rename continent to", text = continent, callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
                self:rename_continent(continent)
            end})
            return
        elseif name == "environments" or string.begins(name, " ") then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_continent(continent)
            end})
            return
        elseif worlddef._continent_definitions[name] then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Continent name already taken!", callback = function()
                self:rename_continent(continent)
            end})
            return
        end
        local worlddef = managers.worlddefinition
        local mission = managers.mission
        if worlddef._continent_definitions[name] then
            self:rename_continent(continent)
            return
        end
        worlddef._continent_definitions[name] = deep_clone(worlddef._continent_definitions[continent])
        mission._missions[name] = deep_clone(mission._missions[continent])
        worlddef._continents[name] = deep_clone(worlddef._continents[continent])
        worlddef._continent_definitions[continent] = nil
        mission._missions[continent] = nil
        worlddef._continents[continent] = nil
        for _, script in pairs(mission._scripts) do
            if script._continent == continent then
                script._continent = name
            end
        end
        for k, static in pairs(worlddef._continent_definitions[name].statics) do
            if static.unit_data and static.unit_data.unit_id then
                static.unit_data.continent = name
                local unit = worlddef:get_unit_on_load(static.unit_data.unit_id)
                if alive(unit) then
                    local ud = unit:unit_data()
                    if ud then
                        ud.continent = name
                    else
                        BeardLibEditor:log("[Warning] Unit with no unit data inside continent")
                    end
                end
            end
        end
        self:build_default_menu()        
    end})
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
    self:Manager("mission"):remove_script()
    self:Manager("static")._selected_units = selected_units
    self:Manager("static"):set_selected_unit()
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
    BeardLibEditor.managers.InputDialog:Show({title = "Continent name", text = "", callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
                self:new_continent()
            end})
            return
        elseif name == "environments" or string.begins(name, " ") then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:new_continent()
            end})
            return
        elseif worlddef._continent_definitions[name] then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Continent name already taken!", callback = function()
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
        worlddef._continents[name] = {base_id = worlddef._start_id  * #worlddef._continent_definitions, name = name}
        self._parent:load_continents(worlddef._continent_definitions)
        self:build_default_menu()
    end})
end

function WData:add_new_mission_script(menu, item)
    local mission = managers.mission
    BeardLibEditor.managers.InputDialog:Show({title = "Mission script name", text = "", callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:add_new_mission_script()
            end})
            return
        elseif string.begins(name, " ") then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_new_mission_script()
            end})
            return
        elseif mission._scripts[name] then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Mission script name already taken!", callback = function()
                self:add_new_mission_script()
            end})
            return
        end
        local cname = item.continent
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
    BeardLibEditor.managers.InputDialog:Show({title = "Rename Mission script to", text = script, callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:rename_script(script, menu, item)
            end})
            return
        elseif string.begins(name, " ") then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_script(script, menu, item)
            end})
            return
        elseif mission._scripts[name] then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Mission script name already taken", callback = function()
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
    for  _, manager in pairs(self.managers) do
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
    for _, element in pairs(managers.mission._missions[item.continent][script].elements) do
        for _, unit in pairs(World:find_units_quick("all")) do
            if unit:mission_element() and unit:mission_element().element.id == element.id then
                table.insert(selected_units, unit)
                break
            end
        end
    end
    self:Manager("mission"):remove_script()
    self:Manager("static")._selected_units = selected_units
    self:Manager("static"):set_selected_unit()    
end

--World Data
function WData:back_button()
    self:SmallButton("Back", callback(self, self, "build_default_menu"), self._menu:GetItem("Title"), {marker_highlight_color = Color.black:with_alpha(0.25), font_size = 18})
end

function WData:build_menu(layer)
    self.super.build_default_menu(self)
    self:back_button()
    if type(layer) == "string" then
        self["build_"..layer.."_layer_menu"](self)
    else
        layer:build_menu()
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
    for _, wire in pairs(BeardLibEditor.Utils:GetUnits({type = "wire", packages = self:Manager("utils")._assets_manager:get_level_packages()})) do
        self:Button(wire, function()
            self:Manager("utils"):BeginSpawning(wire)
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
    local utils = self:Manager("utils")
    self:Button("SpawnNavSurface", callback(utils, utils, "BeginSpawning", "core/units/nav_surface/nav_surface"))
    self:Button("SpawnCoverPoint", callback(utils, utils, "BeginSpawning", "units/dev_tools/level_tools/ai_coverpoint"))
end

function WData:update(t, dt)
    for _, editor in pairs(self.managers) do
        if editor.update then
            editor:update(t, dt)
        end
    end
end

function WData:reset()
    for _, editor in pairs(self.managers) do
        if editor.reset then
            editor:reset()
        end
    end
end

function WData:reset_selected_units()
    for _, editor in pairs(self.managers) do
        if editor.reset_selected_units then
            editor:reset_selected_units()
        end
    end
end

function WData:set_selected_unit()
    for _, editor in pairs(self.managers) do
        if editor.set_selected_unit then
            editor:set_selected_unit()
        end
    end
end