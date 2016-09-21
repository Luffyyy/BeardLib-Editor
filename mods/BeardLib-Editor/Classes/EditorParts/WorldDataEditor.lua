WorldDataEditor = WorldDataEditor or class()
function WorldDataEditor:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "worlddata_menu",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,        
        w = 300,
        help = "",
    })     
    self._menu:SetSize(nil, self._menu:Panel():h() - 42)    
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom()) 
    self:build_default_menu()
end
function WorldDataEditor:build_default_menu()
    self._menu:ClearItems()
    local layers = {"ai", "environment", "portals", "wires"}
    self._menu:Divider({text = "Select a layer to edit"})
    for _, layer in pairs(layers) do
        self:Button(layer, nil, callback(self, self, "build_" .. layer .. "_layer_menu"))
    end
end
function WorldDataEditor:build_wires_layer_menu()
    self._menu:ClearItems()
    self:Button("Back", nil, callback(self, self, "build_default_menu"))
end
function WorldDataEditor:build_portals_layer_menu()
    self._menu:ClearItems()
    self:Button("Back", nil, callback(self, self, "build_default_menu"))    
    local portals = self:Group("portals")
    self._axis_controls = {"position_x", "position_y", "position_z", "rotation_yaw", "rotation_pitch", "rotation_roll"}
    for _, control in pairs(self._axis_controls) do
        self[control] = self:NumberBox(control, nil, callback(self, self, "set_shape_position"), {floats = 0}, 0)
    end
    self._properties_controls = {"width", "height", "depth", "radius"}
    for _, control in pairs(self._properties_controls) do
        self[control] = self:NumberBox(control, nil, callback(self, self, "set_shape"), {floats = 0}, 0)
    end
    local shapes = self:Group("shapes")
    local units = self:Group("units")
    self:Button("New Portal", portals, callback(self, self, "add_portal"))
    self:load_portals(portals)
end
function WorldDataEditor:add_shape()
    self._selected_portal:add_shape({})
    self:load_portal_shapes()
    self:save()
end
function WorldDataEditor:load_portals()
    local group = self._menu:GetItem("portals")
    self._menu:ClearItems("portals")
    for name, portal in pairs(managers.portal:unit_groups()) do
        local btn = self:Button(portal._name, group, callback(self, self, "select_portal"))
        btn:SetLabel("portals")
        self._menu:ContextMenu({
            name = portal._name,
            text = ":",
            override_parent = btn,
            size_by_text = true,
            position = "TopRight",
            items = {
                {text = "Remove", callback = callback(self, self, "remove_portal")},
                {text = "Rename", callback = callback(self, self, "rename_portal")}
            },
            align = "center",
            marker_highlight_color = Color.black,
        })
    end   
end
function WorldDataEditor:build_environment_layer_menu()
    self._menu:ClearItems()
    self:Button("Back", nil, callback(self, self, "build_default_menu"))
end
function WorldDataEditor:build_ai_layer_menu()    
    self._menu:ClearItems()
    self:Button("Back", nil, callback(self, self, "build_default_menu"))
    local states = {
        "empty",
        "airport",
        "besiege",
        "street",
        "zombie_apocalypse"
    }
   -- self:ComboBox("group_state", nil, nil, states, self:data().ai_settings.ai_settings.group_state)
   -- self:Button("add_nav_surface")
end
function WorldDataEditor:rename_portal(menu, item)
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
function WorldDataEditor:remove_portal(menu, item)
    QuickMenu:new( "Warning", "Remove portal? " .. tostring(item.name),
        {{text = "Yes", callback = function()
            managers.portal:remove_unit_group(item.name)
            self:load_portals()
            self:save()            
        end
    },{text = "No", is_cancel_button = true}}, true)        
end
function WorldDataEditor:remove_shape(menu, item)
    QuickMenu:new( "Warning", "Remove shape?",
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
    self._menu:ClearItems("shapes")
    self._menu:ClearItems("units")
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
    self._menu:ClearItems("shapes")
    local group = self._menu:GetItem("shapes") 
    self:Button("New Shape", group, callback(self, self, "add_shape")):SetLabel("shapes")
    for i=1, #self._selected_portal._shapes do
        local btn = self:Button("shape_" .. tostring(i), group, callback(self, self, "select_shape"))
        btn.id = i
        btn:SetLabel("shapes")
        self._menu:Button({
            name = tostring(i),
            text = "x",
            override_parent = btn,
            size_by_text = true,
            position = "TopRight",
            align = "center",
            callback = callback(self, self, "remove_shape"),
            marker_highlight_color = Color.red,
        })
    end
end
function WorldDataEditor:load_portal_units()
    self._menu:ClearItems("units")
    for unit_id, _ in pairs(self._selected_portal._ids) do
        local unit = managers.worlddefinition:get_unit(unit_id)
        if unit then
            local btn = self:Button(unit_id, self._menu:GetItem("units"), function() self._parent:_select_unit(unit) end, string.format("%s[%s]", unit:unit_data().name_id, unit_id))
            btn:SetLabel("units")
            self._menu:Button({
                name = tostring(i),
                text = "x",
                override_parent = btn,
                size_by_text = true,
                position = "TopRight",
                align = "center",
                callback = function() 
                    self._selected_portal:add_unit_id(unit)
                    self:load_portal_units()
                end,
                marker_highlight_color = Color.red,
            })        
        end
    end
end
function WorldDataEditor:update(t, dt)
    if self._selected_portal then
        local r = self._selected_portal._r
        local g = self._selected_portal._g
        local b = self._selected_portal._b   
        local brush = Draw:brush()
        brush:set_color(Color(0.25, r, g, b))
        for k, unit in pairs(World:find_units_quick("all")) do 
            if unit:unit_data() and self._selected_portal._ids[unit:unit_data().unit_id] then
                brush:unit(unit)
                Application:draw(unit, r, g, b)
            end
        end
        if self._selected_shape then
            self._selected_shape:draw(t, dt, 1,1,1)
        end
    end
end
function WorldDataEditor:select_shape(menu, item)
    if self._selected_portal then
        for i=1, #self._selected_portal._shapes do
            self._menu:GetItem("shape_" .. tostring(i)):SetColor()
        end        
        self._selected_shape = item and self._selected_portal._shapes[tonumber(item.id)] 
    end    
    if item then
        item:SetColor(Color.white)
    end
    self.position_x:SetValue(self._selected_shape and self._selected_shape:position().x or 0)      
    self.position_y:SetValue(self._selected_shape and self._selected_shape:position().y or 0)      
    self.position_z:SetValue(self._selected_shape and self._selected_shape:position().z or 0)      
    self.rotation_yaw:SetValue(self._selected_shape and self._selected_shape:rotation():yaw() or 0)      
    self.rotation_pitch:SetValue(self._selected_shape and self._selected_shape:rotation():pitch() or 0)      
    self.rotation_roll:SetValue(self._selected_shape and self._selected_shape:rotation():roll() or 0)      
    for _, control in pairs(self._properties_controls) do
        if self._selected_shape then
            self[control]:SetValue(self._selected_shape._properties[control])
        else
            self[control]:SetValue(0)
        end
    end
    self:save()
end
function WorldDataEditor:set_shape_position(menu, item)
    if not self._selected_portal or not self._selected_shape then
        return
    end   
    self._selected_shape:set_position(Vector3(self.position_x.value, self.position_y.value, self.position_z.value))
    self._selected_shape:set_rotation(Rotation(self.rotation_yaw.value, self.rotation_pitch.value, self.rotation_roll.value))
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
