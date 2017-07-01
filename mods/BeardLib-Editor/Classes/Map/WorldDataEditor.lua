WorldDataEditor = WorldDataEditor or class(EditorPart)
local wde = WorldDataEditor
function wde:init(parent, menu)    
    self.super.init(self, parent, menu, "World")
end

function wde:loaded_continents()
    self:build_default_menu()
    for _, manager in pairs(self.managers) do
        if manager.loaded_continents then
            manager:loaded_continents()
        end
    end
end

function wde:update_positions()
    local shape = self._selected_shape
    self:SetAxisControlsEnabled(shape ~= nil)
    self:SetShapeControlsEnabled(shape ~= nil)
    if shape then
        self:SetAxisControls(shape:position(), shape:rotation())
        self:SetShapeControls(shape._properties)
    end
end

function wde:button_pos(near, item)
    item:Panel():set_righttop(near:Panel():left(), 0)
end

function wde:build_default_menu()
    self.super.build_default_menu(self)
    self.managers = self.managers or {env = EnvironmentLayerEditor:new(self)}
    self._selected_portal = nil
    self._selected_shape = nil
    local layers = self:DivGroup("Layers")
    for _, layer in pairs({"ai", {name = "environment", class = self.managers.env}, "portals", "wires"}) do
        local tbl = type(layer) == "table"
        self:Button(tbl and layer.name or layer, callback(self, self, "build_menu", tbl and layer.class or layer), {group = layers})
    end
    self:build_continents()
end

--Continents
function wde:build_continents()
    local function base_button_pos(item)
        local p = item:Panel():parent()
        item:Panel():set_world_righttop(p:world_righttop())
    end
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

function wde:rename_continent(continent)
    BeardLibEditor.managers.InputDialog:Show({title = "Rename continent to", text = continent, callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
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

function wde:remove_brush_layer()
    BeardLibEditor.Utils:YesNoQuestion("This will remove the brush layer from your level, this cannot be undone from the editor.", function()
        self:data().brush = nil
        MassUnitManager:delete_all_units()
        self:save()
    end)
end

function wde:remove_continent(continent)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the continent!", function()
        self:clear_all_units_from_continent(continent, true, true)
        managers.mission._missions[continent] = nil
        managers.worlddefinition._continents[continent] = nil
        managers.worlddefinition._continent_definitions[continent] = nil
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
        self:build_default_menu()
    end)
end

function wde:select_all_units_from_continent(continent)
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

function wde:clear_all_units_from_continent(continent, no_refresh, no_dialog)
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

function wde:new_continent()
    BeardLibEditor.managers.InputDialog:Show({title = "Continent name", text = "", callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
                self:new_continent()
            end})
            return
        end
        local worlddef = managers.worlddefinition
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

function wde:add_new_mission_script(menu, item)
    BeardLibEditor.managers.InputDialog:Show({title = "Mission script name", text = "", callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:add_new_mission_script()
            end})
            return
        end
        local mission = managers.mission
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

function wde:remove_script(script, menu, item)
    BeardLibEditor.Utils:YesNoQuestion("This will delete the mission script including all elements inside it!", function()
        local mission = managers.mission
        self:_clear_all_elements_from_script(script, item.continent, true, true)
        mission._missions[item.continent][script] = nil
        mission._scripts[script] = nil
        self:build_default_menu()  
    end)
end

function wde:rename_script(script, menu, item)
    BeardLibEditor.managers.InputDialog:Show({title = "Rename Mission script to", text = script, callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:rename_script(script, menu, item)
            end})
            return
        end
        local mission = managers.mission
        if mission._scripts[name] then
            self:rename_script(script)
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

function wde:clear_all_elements_from_script(script, menu, item)
    self:_clear_all_elements_from_script(script, item.continent)
end

function wde:_clear_all_elements_from_script(script, continent, no_refresh, no_dialog)
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

function wde:select_all_units_from_script(script, menu, item)
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
function wde:back_button()
    self:SmallButton("Back", callback(self, self, "build_default_menu"), self._menu:GetItem("Title"), {marker_highlight_color = Color.black:with_alpha(0.25), font_size = 18})
end

function wde:build_menu(layer)
    self.super.build_default_menu(self)
    self:back_button()
    if type(layer) == "string" then
        self["build_"..layer.."_layer_menu"](self)
    else
        layer:build_menu()
    end
end

function wde:build_wires_layer_menu()
    local loaded_wires = self:Group("SpawnWire")
    for _, wire in pairs(BeardLibEditor.Utils:GetUnits({type = "wire"})) do
        self:Button(wire, function()
            self._parent:SpawnUnit(wire)
            self:build_menu("wires")
        end)
    end
    local existing_wires = self:Group("ExistingWires")
    managers.worlddefinition._world_data.wires = managers.worlddefinition._world_data.wires or {}
    for _, wire in pairs(managers.worlddefinition._world_data.wires) do
        local ud = wire.unit_data
        self:Button(ud.name_id, callback(self._parent, self._parent, "select_unit", managers.worlddefinition:get_unit(ud.unit_id)), {group = existing_wires})
    end
end

function wde:build_portals_layer_menu()
    local portals = self:Group("Portals")
    local transform = self:Group("Transform")
    self:AxisControls(callback(self, self, "set_shape_position"), {group = transform})
    self:ShapeControls(callback(self, self, "set_shape"), {group = transform})
    self:Group("Shapes")
    self:Group("Units")
    self:Button("NewPortal", callback(self, self, "add_portal"), {group = portals})
    self:load_portals()
    self:update_positions()
end

function wde:widget_unit()
    return self:Enabled() and self._selected_shape and FakeObject:new(self._selected_shape) or nil
end

function wde:add_shape()
    self._selected_portal:add_shape({})
    self:load_portal_shapes()
    self:save()
end

function wde:load_portals()
    self:ClearItems("portals")
    for name, portal in pairs(managers.portal:unit_groups()) do
        local btn = self:Button(portal._name, callback(self, self, "select_portal"), {label = "portals", group = self:GetItem("Portals"), items ={
            {text = "Remove", callback = callback(self, self, "remove_portal")},
            {text = "Rename", callback = callback(self, self, "rename_portal")}
        }})
    end   
end

function wde:build_ai_layer_menu()    
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

function wde:rename_portal(menu, item, selection)
    BeardLibEditor.managers.InputDialog:Show({title = "Rename portal to", text = item.name, callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Portal name cannot be empty!", callback = function()
                self:rename_portal(menu, item, selection)
            end})
            return
        end
        managers.portal:rename_unit_group(item.name, new_name)
        self:load_portals()
        self:save() 
    end})
end

function wde:remove_portal(menu, item, selection)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the portal", function()
        managers.portal:remove_unit_group(item.name)
        self:load_portals()
        self:save()   
    end)
end

function wde:remove_shape(menu, item)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the portal shape", function()
        if self._selected_shape == self._selected_portal._shapes[tonumber(item.name)] then
            self._selected_shape = nil
        end
        self._selected_portal:remove_shape(self._selected_portal._shapes[tonumber(item.name)])
        self:load_portal_shapes()
        self:save()        
    end)
end

function wde:add_portal(menu, item)
    BeardLibEditor.managers.InputDialog:Show({title = "Portal name", text = item.name, callback = function(name)
        if name == "" then
            BeardLibEditor.managers.Dialog:Show({title = "ERROR!", message = "Portal name cannot be empty!", callback = function()
                self:add_portal(menu, item)
            end})
            return
        end
        managers.portal:add_unit_group(name)
        self:load_portals()
    end})
    self:save()
end

function wde:select_portal(menu, item)
    self._selected_shape = nil
    self:ClearItems("Shapes")
    self:ClearItems("Units")
    if self._selected_portal then
        self._menu:GetItem(self._selected_portal._name):SetColor()
    end
    if self._selected_portal and self._selected_portal._name == item.name  then
        self._selected_portal = nil
    else
        item:SetColor(Color.white)
        self._selected_portal = managers.portal:unit_groups()[item.name]
        self:load_portal_shapes()
        self:load_portal_units()
    end        
    self:select_shape()
    self:save()
end

function wde:load_portal_shapes()
    self:ClearItems("Shapes")
    local group = self._menu:GetItem("Shapes") 
    self:Button("New Shape", callback(self, self, "add_shape"), {group = group}):SetLabel("Shapes")
    for i=1, #self._selected_portal._shapes do
        local btn = self:Button("shape_" .. tostring(i), callback(self, self, "select_shape"), {group = group})
        btn.id = i
        btn:SetLabel("Shapes")
        self:SmallButton(tostring(i), callback(self, self, "remove_shape"), btn, {text = "x", marker_highlight_color = Color.red})
    end
end

function wde:load_portal_units()
    self:ClearItems("Units")
    for unit_id, _ in pairs(self._selected_portal._ids) do
        local unit = managers.worlddefinition:get_unit(unit_id)
        if unit then
            local btn = self:Button(unit_id, function() self._parent:select_unit(unit) end, {text = string.format("%s[%s]", unit:unit_data().name_id, unit_id), group = self._menu:GetItem("Units")})
            btn:SetLabel("Units")
            self:SmallButton(unit_id, function() 
                self._selected_portal:add_unit_id(unit)
                self:load_portal_units()
            end, btn, {text = "x", marker_highlight_color = Color.red})     
        end
    end
end

function wde:update(t, dt)
    for _, editor in pairs(self.managers) do
        if editor.update then
            editor:update(t, dt)
        end
    end
    if self._selected_portal then
        local portal = self._selected_portal
        local r, g, b = portal._r, portal._g, portal._b
        self._brush:set_color(Color(0.25, r, g, b))
        for unit_id in pairs(self._selected_portal._ids) do  
            local unit = managers.worlddefinition:get_unit(unit_id)
            if alive(unit) then
                self._brush:unit(unit)
            end
        end
        if self._selected_shape then
            self._selected_shape:draw(t, dt, 1,1,1)
        end
    end
end

function wde:select_shape(menu, item)
    if self._selected_portal then
        for i=1, #self._selected_portal._shapes do
            self._menu:GetItem("shape_" .. tostring(i)):SetColor()
        end        
        self._selected_shape = item and self._selected_portal._shapes[tonumber(item.id)] 
        if self._selected_shape then
            self._parent:set_camera(self._selected_shape:position())
        end
    end    
    if item then
        item:SetColor(Color.white)
    end
    self:update_positions()
    self:save()
end

function wde:set_shape_position(menu, item)
    if not self._selected_portal or not self._selected_shape then
        return
    end   
    self._selected_shape:set_position(self:AxisControlsPosition())
    self._selected_shape:set_rotation(self:AxisControlsRotation())
    self:save()
end

function wde:data()
    return managers.worlddefinition._world_data
end

function wde:save()
    self:data().portal.unit_groups = managers.portal:save_level_data()
end

function wde:set_shape(menu, item)
    if not self._selected_portal or not self._selected_shape then
        return
    end    
    self._selected_shape:set_property(item.name, item.value)
    self:save()
end
