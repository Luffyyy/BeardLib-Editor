EditorPhysicsPush = EditorPhysicsPush or class(MissionScriptEditor)
function EditorPhysicsPush:create_element()
	self.super.create_element(self)
    self._element.class = "ElementPhysicsPush"
	self._element.values.physicspush_range = 1000
	self._element.values.physicspush_velocity = 100
	self._element.values.physicspush_mass = 100
end

function EditorPhysicsPush:update()
	Application:draw_sphere(self._element.values.position, self._element.values.physicspush_range, 0, 1, 0)
end

function EditorPhysicsPush:_build_panel()
	self:_create_panel()
	self:NumberCtrl("range", {min = 1, max = 10000, text = "Range:"})
	self:NumberCtrl("physicspush_velocity", {min = 1, max = 5000, text =  "Velocity:"})
	self:NumberCtrl("physicspush_mass", {min = 1, max = 5000, text = "Mass:"})
end
 