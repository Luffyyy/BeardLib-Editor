EditorLootBag = EditorLootBag or class(MissionScriptEditor)
EditorLootBag.USES_POINT_ORIENTATION = true
function EditorLootBag:init(unit)
	MissionScriptEditor.init(self, unit)
end
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
	self:_build_value_number("push_multiplier", {floats = 1, min = 0}, "Use this to add a velocity to a physic push on the spawned unit")
	self:_build_value_combobox("carry_id", table.list_add({"none"}, tweak_data.carry:get_carry_ids()), "Select a carry_id to be created.")
	self:_build_value_checkbox("from_respawn")
end
LootBagTriggerUnitElement = LootBagTriggerUnitElement or class(MissionScriptEditor)
LootBagTriggerUnitElement.SAVE_UNIT_POSITION = false
LootBagTriggerUnitElement.SAVE_UNIT_ROTATION = false
function LootBagTriggerUnitElement:init(unit)
	LootBagTriggerUnitElement.super.init(self, unit)
end
 
function LootBagTriggerUnitElement:create_element()
    self.super.create_element(self)
	self._element.values.elements = {}
	self._element.values.trigger_type = "load"
end
function LootBagTriggerUnitElement:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementLootBag"})
	self:_build_value_combobox("trigger_type", {"load", "spawn"}, "Select a trigger type for the selected elements")
	self:_add_help_text("This element is a trigger to point_loot_bag element.")
end
