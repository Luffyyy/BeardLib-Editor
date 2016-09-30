EditorMoveUnit = EditorMoveUnit or class(MissionScriptEditor)

function EditorMoveUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementMoveUnit"
    self._element.values.unit_ids = {}
    self._element.values.speed = 500
    self._element.values.start_pos = self._element.values.position
    self._element.values.end_pos = self._element.values.start_pos
end
function EditorMoveUnit:update(t, dt)
    local end_pos = self._element.values.end_pos
    local start_pos = self._element.values.start_pos or self._element.values.position
    if not end_pos and self._element.values.displacement then
        end_pos = mvector3.copy(start_pos)
        mvector3.add(end_pos, self._element.values.displacement)
    end
    Application:draw_sphere(end_pos, 10, 1, 0, 0)
    Application:draw_line(start_pos, end_pos, 0, 1, 0)
end
function EditorMoveUnit:update_positions(...)
    self.super.update_positions(self, ...)
    if not self._element.values.unit_position_as_start_position then
        self._element.values.start_pos = self._element.values.position
    end
end
function EditorMoveUnit:set_element_data(menu, item)   
    self.super.set_element_data(self, menu, item)
    if item.name == "is_displacement" then
        if item.value == true then
            self._last_end_position = mvector3.copy(self._element.values.end_pos) 
            self._element.values.end_pos = nil
            self._element.values.displacement = Vector3()
        else            
            self._element.values.displacement = nil
            self._element.values.end_pos = self._last_end_position or self._element.values.start_pos
        end
        local end_pos = self._element.values.end_pos or self._element.values.displacement
        self._elements_menu:GetItem("end_position_x"):SetValue(end_pos.x, false, true)
        self._elements_menu:GetItem("end_position_y"):SetValue(end_pos.y, false, true)
        self._elements_menu:GetItem("end_position_z"):SetValue(end_pos.z, false, true)
    elseif item.name == "unit_position_as_start_position" then
        if item.value == true then
            self._last_start_position = mvector3.copy(self._element.values.start_pos) 
            self._element.values.start_pos = nil
        else            
            self._element.values.start_pos = self._last_start_position or self._element.values.position
        end                
    end
end
function EditorMoveUnit:set_element_position(...)
    self.super.set_element_position(self, ...)
    if not self._element.values.unit_position_as_start_position then
        self._element.values.start_pos = self._element.values.position
    end
    local pos = Vector3(self._elements_menu:GetItem("end_position_x").value, self._elements_menu:GetItem("end_position_y").value, self._elements_menu:GetItem("end_position_z").value)
    if self._element.values.is_displacement then
        self._element.values.displacement = pos
        self._element.values.end_pos = nil
    else
        self._element.values.end_pos = pos
        self._element.values.displacement = nil
    end
end
function EditorMoveUnit:_build_panel()
	self:_create_panel()
    self:_build_unit_list("unit_ids")
    self:_build_value_number("speed", {floats = 2, min = 0.1}, "Set the speed of unit movement")  
    self:_build_value_checkbox("is_displacement")
    self:_build_value_checkbox("unit_position_as_start_position")
    local end_pos = self._element.values.end_pos or self._element.values.displacement
    self:_build_value_number("end_position_x", {value = end_pos.x or 0, callback = callback(self, self, "set_element_position")})
    self:_build_value_number("end_position_y", {value = end_pos.y or 0, callback = callback(self, self, "set_element_position")})
    self:_build_value_number("end_position_z", {value = end_pos.z or 0, callback = callback(self, self, "set_element_position")})     
end
