EditorLootBag = EditorLootBag or class(MissionScriptEditor)
EditorLootBag.USES_POINT_ORIENTATION = true
EditorLootBag._test_units = {}
function EditorLootBag:create_element()
    self.super.create_element(self)	
    self._element.class = "ElementLootBag"
	self._element.values.spawn_dir = Vector3(0, 0, -1)
	self._element.values.push_multiplier = 0
	self._element.values.carry_id = "none"
	self._element.values.from_respawn = false
	self._element.values.zipline_unit_id = nil
end

function EditorLootBag:test_element()
    local unit_name = 'units/payday2/pickups/gen_pku_lootbag/gen_pku_lootbag'
    local throw_distance_multiplier = 1

    if self._element.values.carry_id ~= 'none' then
        unit_name = tweak_data.carry[self._element.values.carry_id].unit or unit_name
        local carry_type = tweak_data.carry[self._element.values.carry_id].type
        throw_distance_multiplier =
            tweak_data.carry.types[carry_type].throw_distance_multiplier or throw_distance_multiplier
    end

    local unit = safe_spawn_unit(unit_name, self._unit:position(), self._unit:rotation())

    table.insert(self._test_units, unit)

    local push_value = self._element.values.push_multiplier and self._element.values.spawn_dir * self._element.values.push_multiplier or 0

    unit:push(100, 600 * push_value * throw_distance_multiplier)
end

function EditorLootBag:stop_test_element()
    for _, unit in ipairs(self._test_units) do
        if alive(unit) then
            World:delete_unit(unit)
        end
    end

    self._test_units = {}
end

function EditorLootBag:update(t, dt)
	local kb = Input:keyboard()
	local speed = 60 * dt
	self._element.values.spawn_dir = self._element.values.spawn_dir or Vector3()
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
	if ray and ray.unit and not self._element.values.zipline_unit_id then
		Application:draw_sphere(ray.position, 25, 1, 0, 0)
		Application:draw_arrow(self._element.values.position, self._element.values.position + self._element.values.spawn_dir * 50, 0.75, 0.75, 0.75, 0.1)
	end
	EditorLootBag.super.update(self, t, dt)
end

function EditorLootBag:update_selected(t, dt)
	if self._element.values.zipline_unit_id then
		local id = self._element.values.zipline_unit_id
		local unit = managers.worlddefinition:get_unit(id)
		if alive(unit) then
			self:draw_link({
				g = 0.75,
				b = 0,
				r = 0,
				from_unit = self._unit,
				to_unit = unit
			})
			Application:draw(unit, 0, 0.75, 0)
		else
			self._element.values.zipline_unit_id = nil
		end
	end
end

function EditorLootBag:link_managed(unit)
	if alive(unit) then
		if self:check_unit(unit) and unit:unit_data() then
			self:AddOrRemoveManaged("zipline_unit_id", {unit = unit}, {not_table = true})
		end
	end
end

function EditorLootBag:check_unit(unit)
	return unit:zipline() and unit:zipline():is_usage_type_bag()
end

function EditorLootBag:reset_spawn_dir()
	self._element.values.spawn_dir = Vector3(0, 0, -1)
end

function EditorLootBag:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("zipline_unit_id", nil, nil, {
		text = "Zipline Unit",
		single_select = true,
		not_table = true,
		check_unit = ClassClbk(self, "check_unit")
	})
	self:NumberCtrl("push_multiplier", {floats = 1, min = 0, help = "Use this to add a velocity to a physic push on the spawned unit"})
	self:ComboCtrl("carry_id", table.list_add({"none"}, tweak_data.carry:get_carry_ids()), {
		help = "Select a carry_id to be created.", 
		not_close = true, 
        searchbox = true, 
        fit_text = true
	})
	self:BooleanCtrl("from_respawn")
	self:Text("This element can spawn loot bags, control the spawn direction using your arrow keys")

	self:tb_btn("Reset Push Direction", ClassClbk(self, "reset_spawn_dir"))
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