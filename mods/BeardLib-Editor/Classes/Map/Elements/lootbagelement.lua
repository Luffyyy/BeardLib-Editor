EditorLootBag = EditorLootBag or class(MissionScriptEditor)
EditorLootBag.USES_POINT_ORIENTATION = true
function EditorLootBag:create_element()
    self.super.create_element(self)	
    self._element.class = "ElementLootBag"
	self._element.values.spawn_dir = Vector3(0, 0, 1)
	self._element.values.push_multiplier = 0
	self._element.values.carry_id = "none"
	self._element.values.from_respawn = false
end

function EditorLootBag:update(d, dt)
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
		Application:draw_arrow(self._element.values.position, self._element.values.position + self._element.values.spawn_dir * 50, 0.75, 0.75, 0.75, 0.1)
	end
end

function EditorLootBag:_build_panel()
	self:_create_panel()
	self:NumberCtrl("push_multiplier", {floats = 1, min = 0, help = "Use this to add a velocity to a physic push on the spawned unit"})
	self:ComboCtrl("carry_id", table.list_add({"none"}, tweak_data.carry:get_carry_ids()), {help = "Select a carry_id to be created."})
	self:BooleanCtrl("from_respawn")
	self:Text("This element can spawn loot bags, control the spawn direction using your arrow keys")
end

EditorLootBagTrigger = EditorLootBagTrigger or class(MissionScriptEditor)
function EditorLootBagTrigger:create_element()
    self.super.create_element(self)
    self._element.class = "ElementLootBagTrigger"
	self._element.values.elements = {}
	self._element.values.trigger_type = "load"
end

function EditorLootBagTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementLootBag"})
	self:ComboCtrl("trigger_type", {"load", "spawn"}, {help = "Select a trigger type for the selected elements"})
	self:Text("This element is a trigger to point_loot_bag element.")
end