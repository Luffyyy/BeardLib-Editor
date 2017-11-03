EditorMoveUnit = EditorMoveUnit or class(MissionScriptEditor)
function EditorMoveUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementMoveUnit"
    self._element.values.unit_ids = {}
    self._element.values.speed = 500
    self._element.values.start_pos = self._element.values.position
    self._element.values.end_pos = self._element.values.start_pos
    self._element.values.remember_unit_position = false
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
    self:SetAxisControls(self._element.values.end_pos or self._element.values.displacement, nil, "EndPosition")
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
        self:update_positions()
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
    local pos = self:AxisControlsPosition("EndPosition")
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
    self:BuildUnitsManage("unit_ids")
    self:BooleanCtrl("is_displacement")
    self:BooleanCtrl("unit_position_as_start_position")
    self:BooleanCtrl("remember_unit_position")
    local end_pos = self._element.values.end_pos or self._element.values.displacement
    self:NumberCtrl("speed", {floats = 2, min = 0.1, help = "Set the speed of the movement"})
    self:AxisControls(callback(self, self, "set_element_position"), {no_rot = true, group = transform}, "EndPosition")
    self:Button("ResetEndPosition", function()
        self._element.values.end_pos = self._element.values.start_pos or self._element.values.position
        self:update_positions()
    end)
    self:update_positions()
end
