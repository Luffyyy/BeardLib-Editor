if Global.editor_mode then
core:import("CoreSequenceManager")
CoreUnitDamage = CoreUnitDamage or class()
CoreUnitDamage.ALL_TRIGGERS = "*"
UnitDamage = UnitDamage or class(CoreUnitDamage)
local ids_damage = Idstring("damage")
function CoreUnitDamage:init(unit, default_body_extension_class, body_extension_class_map, ignore_body_collisions, ignore_mover_collisions, mover_collision_ignore_duration)
	self._unit = unit
	self._unit_element = managers.sequence:get(unit:name(), false, true)
	self._damage = 0
	if self._unit_element._set_variables and next(self._unit_element._set_variables) then
		self._variables = clone(self._unit_element._set_variables)
	end
	self._unit:set_extension_update_enabled(ids_damage, self._update_func_map ~= nil)
	for name, element in pairs(self._unit_element:get_proximity_element_map()) do
		local data = {}
		data.name = name
		data.enabled = element:get_enabled()
		data.ref_object = element:get_ref_object() and self._unit:get_object(Idstring(element:get_ref_object()))
		data.interval = element:get_interval()
		data.quick = element:is_quick()
		data.is_within = element:get_start_within()
		data.slotmask = element:get_slotmask()
		data.last_check_time = TimerManager:game():time() + math.rand(math.min(data.interval, 0))
		self:populate_proximity_range_data(data, "within_data", element:get_within_element())
		self:populate_proximity_range_data(data, "outside_data", element:get_outside_element())
		self._proximity_map = self._proximity_map or {}
		self._proximity_map[name] = data
		self._proximity_count = (self._proximity_count or 0) + 1
		if data.enabled then
			if not self._proximity_enabled_count then
				self._proximity_enabled_count = 0
				self:set_update_callback("update_proximity_list", true)
			end
			self._proximity_enabled_count = self._proximity_enabled_count + 1
		end
	end
	self._mover_collision_ignore_duration = mover_collision_ignore_duration
	body_extension_class_map = body_extension_class_map or {}
	default_body_extension_class = default_body_extension_class or CoreBodyDamage
	local inflict_updator_damage_type_map = get_core_or_local("InflictUpdator").INFLICT_UPDATOR_DAMAGE_TYPE_MAP
	local unit_key = self._unit:key()
	for _, body_element in pairs(self._unit_element._bodies) do
		local body = self._unit:body(body_element._name)
		if body then
			body:set_extension(body:extension() or {})
			local body_ext = body_extension_class_map[body_element._name] or default_body_extension_class:new(self._unit, self, body, body_element)
			body:extension().damage = body_ext
			local body_key
			for damage_type, _ in pairs(body_ext:get_endurance_map()) do
				if inflict_updator_damage_type_map[damage_type] then
					body_key = body_key or body:key()
					self._added_inflict_updator_damage_type_map = self._added_inflict_updator_damage_type_map or {}
					self._added_inflict_updator_damage_type_map[damage_type] = {}
					self._added_inflict_updator_damage_type_map[damage_type][body_key] = body_ext
					managers.sequence:add_inflict_updator_body(damage_type, unit_key, body_key, body_ext)
				end
			end
		else
			Application:throw_exception("Unit \"" .. self._unit:name():t() .. "\" doesn't have the body \"" .. body_element._name .. "\" that was loaded into the SequenceManager.")
		end
	end
	if not ignore_body_collisions then
		self._unit:set_body_collision_callback(callback(self, self, "body_collision_callback"))
	end
	if self._unit:mover() and not ignore_mover_collisions then
		self._unit:set_mover_collision_callback(callback(self, self, "mover_collision_callback"))
	end
	self._water_check_element_map = self._unit_element:get_water_element_map()
	if self._water_check_element_map then
		for name, water_element in pairs(self._water_check_element_map) do
			self:set_water_check(name, water_element:get_enabled(), water_element:get_interval(), water_element:get_ref_object(), water_element:get_ref_body(), water_element:get_body_depth(), water_element:get_physic_effect())
		end
	end
	self._startup_sequence_map = self._unit_element:get_startup_sequence_map(self._unit, self)
	if self._startup_sequence_map then
		self._startup_sequence_callback_id = managers.sequence:add_startup_callback(callback(self, self, "run_startup_sequences"))
	end
	if Application:editor() then
		self._editor_startup_sequence_map = self._unit_element:get_editor_startup_sequence_map(self._unit, self)
		if self._editor_startup_sequence_map then
			self._editor_startup_sequence_callback_id = managers.sequence:add_startup_callback(callback(self, self, "run_editor_startup_sequences"))
		end
	end
	--[[if managers.editor then
		managers.editor:register_message(EditorMessage.OnUnitRemoved, nil, callback(self, self, "on_unit_removed"))
		managers.editor:register_message(EditorMessage.OnUnitRestored, nil, callback(self, self, "on_unit_restored"))
	end]]
end
 
end
