EditorSpawnGrenade = EditorSpawnGrenade or class(MissionScriptEditor)
function EditorSpawnGrenade:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnGrenade"
	self._element.values.grenade_type = "frag"
	self._element.values.spawn_dir = Vector3(0, 0, 1)
	self._element.values.strength = 1
end

function EditorSpawnGrenade:update(d, dt)
	local kb = Input:keyboard()
	local speed = 60 * dt
	if kb:down(Idstring("left")) then
		self._element.values.spawn_dir = self._element.values.spawn_dir:rotate_with(Rotation(speed, 0, 0))
	end
	if kb:down(Idstring("right")) then
		self._element.values.spawn_dir = self._element.values.spawn_dir:rotate_with(Rotation(-speed, 0, 0))
	end
	if kb:down(Idstring("up")) then
		self._element.values.spawn_dir = self._element.values.spawn_dir:rotate_with(Rotation(0, 0, speed))
	end
	if kb:down(Idstring("down")) then
		self._element.values.spawn_dir = self._element.values.spawn_dir:rotate_with(Rotation(0, 0, -speed))
	end
	local from = self._element.values.position
	local to = from + self._element.values.spawn_dir * 100000
	local ray = World:raycast("ray", from, to)
	if ray and ray.unit then
		Application:draw_sphere(ray.position, 25, 1, 0, 0)
		Application:draw_arrow(self._element.values.position, self._element.values.position + self._element.values.spawn_dir * 35, 0.75, 0.75, 0.75, 0.075)
	end
end

function EditorSpawnGrenade:_build_panel()
	self:_create_panel()
	self:ComboCtrl("grenade_type", table.map_keys(tweak_data.blackmarket.projectiles), {help = "Select what type of grenade will be spawned."})
	self:NumberCtrl("strength", {floats = 1, help = "Use this to add a strength to a physic push on the spawned grenade"})
	self:Text("Spawns a grenade.")
end
