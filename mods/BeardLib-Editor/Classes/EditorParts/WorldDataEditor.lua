WorldDataEditor = WorldDataEditor or class(EditorPart)
function WorldDataEditor:init(parent, menu)
    self.super.init(self, parent, menu, "WorldDataEditor")
end

function WorldDataEditor:build_default_menu()
    self.super.build_default_menu(self)
    self._selected_portal = nil
    self._selected_shape = nil
    local layers = {"ai", "environment", "portals", "wires"}
    self:Divider("Select a layer to edit")
    for _, layer in pairs(layers) do
        self:Button(layer, callback(self, self, "build_menu", layer))
    end
end

function WorldDataEditor:build_menu(menu)
    self.super.build_default_menu(self)
    self:SmallButton("Back", callback(self, self, "build_default_menu"), self._menu:GetItem("Title"), {marker_highlight_color = Color.black:with_alpha(0.25)}) 
    self["build_"..menu.."_layer_menu"](self)
end

function WorldDataEditor:build_wires_layer_menu()
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

function WorldDataEditor:build_portals_layer_menu()
    local portals = self:Group("Portals")
    local transform = self:Group("Transform")
    self:AxisControls(callback(self, self, "set_shape_position"), {group = transform})
    self:ShapeControls(callback(self, self, "set_shape"), {group = transform})
    self:Group("Shapes")
    self:Group("Units")
    self:Button("NewPortal", callback(self, self, "add_portal"), {group = portals})
    self:load_portals()
    self:update_menu()
end

function WorldDataEditor:widget_unit()
    return self:Enabled() and self._selected_shape and FakeObject:new(self._selected_shape) or nil
end

function WorldDataEditor:add_shape()
    self._selected_portal:add_shape({})
    self:load_portal_shapes()
    self:save()
end

function WorldDataEditor:load_portals()
    self._menu:ClearItems("portals")
    for name, portal in pairs(managers.portal:unit_groups()) do
        local btn = self:Button(portal._name, callback(self, self, "select_portal"), {label = "portals", group = self:GetItem("Portals"), items ={
            {text = "Remove", callback = callback(self, self, "remove_portal")},
            {text = "Rename", callback = callback(self, self, "rename_portal")}
        }})
    end   
end

function WorldDataEditor:build_environment_layer_menu()
end

function WorldDataEditor:build_ai_layer_menu()    
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
    self:Button("AddNavSurface", callback(self._parent, self._parent, "SpawnUnit", "core/units/nav_surface/nav_surface"))
end

function WorldDataEditor:rename_portal(menu, item, selection)
    managers.system_menu:show_keyboard_input({
        text = item.name,
        title = "New portal name:",
        callback_func = function(success, new_name)
            if not success or new_name == "" then
                return
            end
            managers.portal:rename_unit_group(item.name, new_name)
            self:load_portals()
        end
    }) 
    self:save()
end

function WorldDataEditor:remove_portal(menu, item, selection)
    QuickMenu:new("Warning", "Remove portal? " .. tostring(item.name),
        {{text = "Yes", callback = function()
            managers.portal:remove_unit_group(item.name)
            self:load_portals()
            self:save()            
        end
    },{text = "No", is_cancel_button = true}}, true)        
end

function WorldDataEditor:remove_shape(menu, item)
    QuickMenu:new("Warning", "Remove shape?",
        {{text = "Yes", callback = function()
            if self._selected_shape == self._selected_portal._shapes[tonumber(item.name)] then
                self._selected_shape = nil
            end
            self._selected_portal:remove_shape(self._selected_portal._shapes[tonumber(item.name)])
            self:load_portal_shapes()
            self:save()              
        end
    },{text = "No", is_cancel_button = true}}, true)    
end

function WorldDataEditor:add_portal(menu, item)
    managers.system_menu:show_keyboard_input({
        text = "",
        title = "Portal name:",
        callback_func = function(success, name)
            if not success or name == "" then
                return
            end
            managers.portal:add_unit_group(name)
            self:load_portals()
        end
    })    
    self:save()
end

function WorldDataEditor:select_portal(menu, item)
    self._selected_shape = nil
    self._menu:ClearItems("Shapes")
    self._menu:ClearItems("Units")
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

function WorldDataEditor:load_portal_shapes()
    self._menu:ClearItems("Shapes")
    local group = self._menu:GetItem("Shapes") 
    self:Button("New Shape", callback(self, self, "add_shape"), {group = group}):SetLabel("Shapes")
    for i=1, #self._selected_portal._shapes do
        local btn = self:Button("shape_" .. tostring(i), callback(self, self, "select_shape"), {group = group})
        btn.id = i
        btn:SetLabel("Shapes")
        self:SmallButton(tostring(i), callback(self, self, "remove_shape"), btn, {text = "x", marker_highlight_color = Color.red})
    end
end

function WorldDataEditor:load_portal_units()
    self._menu:ClearItems("Units")
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

function WorldDataEditor:update(t, dt)
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

function WorldDataEditor:update_menu()
    local shape = self._selected_shape
    self:SetAxisControlsEnabled(shape ~= nil)
    self:SetShapeControlsEnabled(shape ~= nil)
    if shape then
        self:SetAxisControls(shape:position(), shape:rotation())
        self:SetShapeControls(shape._properties)
    end
end

function WorldDataEditor:select_shape(menu, item)
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
    self:update_menu()
    self:save()
end

function WorldDataEditor:set_shape_position(menu, item)
    if not self._selected_portal or not self._selected_shape then
        return
    end   
    self._selected_shape:set_position(self:AxisControlsPosition())
    self._selected_shape:set_rotation(self:AxisControlsRotation())
    self:save()
end

function WorldDataEditor:data()
    return managers.worlddefinition._world_data
end

function WorldDataEditor:save()
    self:data().portal.unit_groups = managers.portal:save_level_data()
end

function WorldDataEditor:set_shape(menu, item)
    if not self._selected_portal or not self._selected_shape then
        return
    end    
    self._selected_shape:set_property(item.name, item.value)
    self:save()
end
