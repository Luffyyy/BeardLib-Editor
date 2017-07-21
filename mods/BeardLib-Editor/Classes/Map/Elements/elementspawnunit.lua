EditorSpawnUnit = EditorSpawnUnit or class(MissionScriptEditor)
function EditorSpawnUnit:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnUnit"
	self._element.values.unit_name = "none"
	self._element.values.unit_spawn_velocity = 0
	self._element.values.unit_spawn_mass = 0
	self._element.values.unit_spawn_dir = Vector3(0, 0, 1)
end

function EditorSpawnUnit:update(t, dt)
	local kb = Input:keyboard()
	local speed = 60 * dt
	if kb:down(Idstring("left")) then
		self._element.values.unit_spawn_dir = self._element.values.unit_spawn_dir:rotate_with(Rotation(speed, 0, 0))
	end
	if kb:down(Idstring("right")) then
		self._element.values.unit_spawn_dir = self._element.values.unit_spawn_dir:rotate_with(Rotation(-speed, 0, 0))
	end
	if kb:down(Idstring("up")) then
		self._element.values.unit_spawn_dir = self._element.values.unit_spawn_dir:rotate_with(Rotation(0, 0, speed))
	end
	if kb:down(Idstring("down")) then
		self._element.values.unit_spawn_dir = self._element.values.unit_spawn_dir:rotate_with(Rotation(0, 0, -speed))
	end
	local from = self._element.values.position
	local to = from + self._element.values.unit_spawn_dir * 100000
	local ray = World:raycast("ray", from, to)
	if ray and ray.unit then
		Application:draw_sphere(ray.position, 25, 1, 0, 0)
		Application:draw_arrow(self._element.values.position, self._element.values.position + self._element.values.unit_spawn_dir * 400, 0.75, 0.75, 0.75)
	end
end

function EditorSpawnUnit:_build_panel()
	self:_create_panel()
	self:PathCtrl("unit_name", "unit")
	self:NumberCtrl("unit_spawn_velocity", {floats = 0, min = 0, text = "Velocity", help = "Use this to add a velocity to a physic push on the spawned unit(will need mass as well)"})
	self:NumberCtrl("unit_spawn_mass", {floats = 0, min = 0, text = "Mass", help = "Use this to add a mass to a physic push on the spawned unit(will need velocity as well)"})
end
 