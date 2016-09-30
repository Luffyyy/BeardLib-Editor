EditorPhysicsPush = EditorPhysicsPush or class(MissionScriptEditor)

function EditorPhysicsPush:create_element()
	self.super.create_element(self)
    self._element.class = "EditorPhysicsPush"
	self._element.values.physicspush_range = 1000
	self._element.values.physicspush_velocity = 100
	self._element.values.physicspush_mass = 100
end
function EditorPhysicsPush:update()
	Application:draw_sphere(self._element.values.position, self._element.values.physicspush_range, 0, 1, 0)
end
function EditorPhysicsPush:_build_panel(panel, panel_sizer)
	self:_create_panel()
	self:_build_value_number("range", {min = 1, max = 10000}, "", "Range:")
	self:_build_value_number("physicspush_velocity", {min = 1, max = 5000}, "", "Velocity:")
	self:_build_value_number("physicspush_mass", {min = 1, max = 5000}, "", "Mass:")
end
 