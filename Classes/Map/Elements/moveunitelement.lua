EditorMoveUnit = EditorMoveUnit or class(MissionScriptEditor)
function EditorMoveUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementMoveUnit"
    self._element.values.unit_ids = {}
    self._element.values.speed = 500
    self._element.values.end_pos = self._element.values.position
    self._element.values.remember_unit_position = false
end

function EditorMoveUnit:update(t, dt)
    local end_pos = self._element.values.end_pos
    local start_pos = self._element.values.position
    if not end_pos and self._element.values.displacement then
        end_pos = mvector3.copy(start_pos)
        mvector3.add(end_pos, self._element.values.displacement)
	end
	if end_pos then
		Application:draw_sphere(end_pos, 10, 1, 0, 0)
		Application:draw_line(start_pos, end_pos, 0, 1, 0)
	end
	EditorMoveUnit.super.update(self, t, dt)
end

function EditorMoveUnit:update_positions(...)
	EditorMoveUnit.super.update_positions(self, ...)
	if self._element.values.unit_position_as_start_position then
		self._element.values.end_pos = self._element.values.position
    end
    local end_pos = self:GetItem("EndPosition")
    if end_pos then
        end_pos:SetValue(self._element.values.end_pos or self._element.values.displacement)
    end
end

function EditorMoveUnit:set_element_data(item)   
    EditorMoveUnit.super.set_element_data(self, item)
    if item.name == "is_displacement" then
        if item:Value() then
            self._last_end_position = mvector3.copy(self._element.values.end_pos) 
            self._element.values.end_pos = nil
            self._element.values.displacement = Vector3()
        else            
            self._element.values.displacement = nil
            self._element.values.end_pos = self._last_end_position or self._element.values.start_pos
        end
        self:update_positions()
    end
end

function EditorMoveUnit:set_element_position(...)
    EditorMoveUnit.super.set_element_position(self, ...)
    local pos = self:GetItem("EndPosition"):Value()
    if self._element.values.is_displacement then
        self._element.values.displacement = pos
        self._element.values.end_pos = nil
	else
		if self._element.values.unit_position_as_start_position then
			self._element.values.position = pos
		end
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
    self._class_group:Vector3("EndPosition", ClassClbk(self, "set_element_position"))
    self:button("ResetEndPosition", function()
        self._element.values.end_pos = self._element.values.position
        self:update_positions()
    end)
    self:update_positions()
end

EditorRotateUnit = EditorRotateUnit or class(MissionScriptEditor)
function EditorRotateUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementRotateUnit"
    self._element.values.unit_ids = {}
    self._element.values.speed = 500
    self._element.values.end_rot = self._element.values.rotation
    self._element.values.remember_unit_rot = false
end

function EditorRotateUnit:update(t, dt)
  --[[ local end_rot = self._element.values.end_rot
    local start_rot = self._element.values.rotation
    if not end_rot and self._element.values.offset then
        end_rot = mvector3.copy(start_pos)
        mvector3.add(end_rot, self._element.values.offset)
	end
	if end_rot then
		Application:draw_sphere(end_rot, 10, 1, 0, 0)
		Application:draw_line(start_pos, end_rot, 0, 1, 0)
	end
	]]
	EditorRotateUnit.super.update(self, t, dt)
end

function EditorRotateUnit:update_positions(...)
	EditorMoveUnit.super.update_positions(self, ...)
	if self._element.values.use_unit_rot then
		self._element.values.end_rot = self._element.values.rotation
    end
    local end_rot = self:GetItem("EndRotation")
    if end_rot then
        end_rot:SetValue(self._element.values.end_rot or self._element.values.offset)
    end
end

function EditorRotateUnit:set_element_data(item)   
    EditorRotateUnit.super.set_element_data(self, item)
    if item.name == "is_offset" then
        if item:Value() then
            self._last_end_rotition = mrotation.copy(self._element.values.end_rot) 
            self._element.values.end_rot = nil
            self._element.values.offset = Rotation()
        else            
            self._element.values.offset = nil
            self._element.values.end_rot = self._last_end_rotition or self._element.values.end_rot
        end
		self:update_positions()
		self:update_element()
    end
end

function EditorRotateUnit:set_element_position(...)
    EditorRotateUnit.super.set_element_position(self, ...)
    local rot = self:GetItem("EndRotation"):Value()
    if self._element.values.offset then
        self._element.values.offset = rot
        self._element.values.end_rot = nil
	else
		if self._element.values.use_unit_rot then
			self._element.values.rotation = rot
		end
        self._element.values.end_rot = rot
        self._element.values.offset = nil
	end
	self:update_element()
end

function EditorRotateUnit:_build_panel()
	self:_create_panel()
    self:BuildUnitsManage("unit_ids")
    --self:BooleanCtrl("is_offset")
    self:BooleanCtrl("use_unit_rot", {text = "Use Unit Rotation"})
    self:BooleanCtrl("remember_unit_rot", {text = "Remember Unit Rotation"})
    local end_rot = self._element.values.end_rot or self._element.values.displacement
    self:NumberCtrl("speed", {floats = 2, min = 0.1, help = "Set the speed of the rotation"})
    self._class_group:Rotation("EndRotation", ClassClbk(self, "set_element_position"))
    self:button("ResetEndRotation", function()
        self._element.values.end_rot = self._element.values.rotation
		self:update_positions()
		self:update_element()
    end)
    self:update_positions()
end