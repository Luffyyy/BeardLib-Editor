EditorSpawnUnit = EditorSpawnUnit or class(MissionScriptEditor)
function EditorSpawnUnit:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnUnit"
	self._element.values.unit_name = "none"
	self._element.values.unit_spawn_velocity = 0
	self._element.values.unit_spawn_mass = 0
	self._element.values.unit_spawn_dir = Vector3(0, 0, 1)
	self._test_units = {}
end

function EditorSpawnUnit:update(time, rel_time)
	local kb = Input:keyboard()
	local speed = 60 * rel_time
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
	--Unit browser window needed
	--Redo..?
	--What are dynamics ffs ???? xD
	local unit_options = {"none"}
--[[for name, _ in pairs(managers.editor:layers().Dynamics:get_unit_map()) do
		table.insert(unit_options, managers.editor:get_real_name(name))
	end]]
	self:ComboCtrl("unit_name", unit_options, {help = "Select a unit from the combobox"})
	self:NumberCtrl("unit_spawn_velocity", {floats = 0, min = 0, help = "Use this to add a velocity to a physic push on the spawned unit(will need mass as well)", text = "Velocity"})
	self:NumberCtrl("unit_spawn_mass", {floats = 0, min = 0, help ="Use this to add a mass to a physic push on the spawned unit(will need velocity as well)", text = "Mass"})
	self:Text([[
		Select a unit to be spawned in the unit combobox.

		Add velocity and mass if you want to give the spawned unit a 
		push as if it was hit by an object of mass mass, traveling at a 
		velocity of velocity relative to the unit (both values are required to give the push)

		Body slam (80 kg, 10 m/s)
		Fist punch (8 kg, 10 m/s)
		Bullet hit (10 g, 900 m/s)
	]])
end
 