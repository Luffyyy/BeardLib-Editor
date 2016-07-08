WorldDataEditor = WorldDataEditor or class()

function WorldDataEditor:init(parent, menu)
    self._parent = parent
    self._menu = menu:NewMenu({
        name = "world_settings",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,        
        w = 250,
        help = "",
    })    
    self._menu:SetSize(nil, self._menu:Panel():h() - 42)    
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom()) 
    self._axis_controls = {"position_x", "position_y", "position_z", "rotation_yaw", "rotation_pitch", "rotation_roll"}
    for _, control in pairs(self._axis_controls) do
        self[control] = self._menu:Slider({
            name = control,
            text = string.pretty(control, true),
            value = 0,
            floats = 0,
            callback = callback(self, self, "set_shape_position"),
        })
    end
    self._properties_controls = {"width", "height", "depth", "radius"}
    for _, control in pairs(self._properties_controls) do
        self[control] = self._menu:Slider({
            name = control,
            text = string.pretty(control, true),
            value = 0,
            floats = 0,
            callback = callback(self, self, "set_shape"),
        })
    end
    self.shapes = self._menu:ComboBox({
        name = "shapes",
        text = "Select a shape",
        callback = callback(self, self, "select_shape")
    })     
    local group = self._menu:ItemsGroup({
        name = "portals_list",
        text = "Portals",
    })
end
function WorldDataEditor:load_portals()
    for name, portal in pairs(managers.portal:unit_groups()) do
        self._menu:Button({
            name = portal._name,
            text = string.pretty(portal._name, true),
            group = group,
            callback = callback(self, self, "select_portal")
        })
    end   
end
function WorldDataEditor:select_portal(menu, item)
    if self._selected_portal then
        self._menu:GetItem(self._selected_portal._name):SetColor()
    end
    if self._selected_portal and self._selected_portal._name == item.name  then
        self._selected_portal = nil
        self.shapes:SetItems()   
        self.shapes:SetValue(1) 
    else
        item:SetColor(Color.white)
        self._selected_portal = managers.portal:unit_groups()[item.name]
        local shapes = {}
        for i=1, #self._selected_portal._shapes do
            table.insert(shapes, tostring(i))
        end
        self.shapes:SetItems(shapes)        
        self.shapes:SetValue(1) 
    end        
    self.shapes:RunCallback()
    self:save()
end
function WorldDataEditor:update(t, dt)
    if self._selected_portal and self._selected_portal._shapes[self.shapes.value] then
        self._selected_portal._shapes[self.shapes.value]:draw(t, dt, 1,1,1)
    end
end
function WorldDataEditor:select_shape(menu, item)
    local shape = self._selected_portal and self._selected_portal._shapes[item.value] 
    self.position_x:SetValue(shape and shape:position().x or 0)      
    self.position_y:SetValue(shape and shape:position().y or 0)      
    self.position_z:SetValue(shape and shape:position().z or 0)      
    self.rotation_yaw:SetValue(shape and shape:rotation():yaw() or 0)      
    self.rotation_pitch:SetValue(shape and shape:rotation():pitch() or 0)      
    self.rotation_roll:SetValue(shape and shape:rotation():roll() or 0)      
    for _, control in pairs(self._properties_controls) do
        if shape then
            self[control]:SetValue(shape._properties[control])
        else
            self[control]:SetValue(0)
        end
    end
    self:save()
end
function WorldDataEditor:set_shape_position(menu, item)
    if not self._selected_portal or not self._selected_portal._shapes[self.shapes.value] then
        return
    end   
    self._selected_portal._shapes[self.shapes.value]:set_position(Vector3(self.position_x.value, self.position_y.value, self.position_z.value))
    self._selected_portal._shapes[self.shapes.value]:set_rotation(Rotation(self.rotation_yaw.value, self.rotation_pitch.value, self.rotation_roll.value))
    self:save()
end
function WorldDataEditor:save()
    managers.worlddefinition._world_data.portal.unit_groups = managers.portal:save_level_data()
end
function WorldDataEditor:set_shape(menu, item)
    if not self._selected_portal or not self._selected_portal._shapes[self.shapes.value] then
        return
    end    
    self._selected_portal._shapes[self.shapes.value]:set_property(item.name, item.value)
    self:save()
end
