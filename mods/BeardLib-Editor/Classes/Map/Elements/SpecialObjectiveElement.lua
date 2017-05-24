EditorSpecialObjective = EditorSpecialObjective or class(MissionScriptEditor) --wip
EditorSpecialObjective.INSTANCE_VAR_NAMES = {
	{
		type = "special_objective_action",
		value = "so_action"
	}
}
EditorSpecialObjective._AI_SO_types = {
	"AI_defend",
	"AI_security",
	"AI_hunt",
	"AI_search",
	"AI_idle",
	"AI_escort",
	"AI_sniper",
	"AI_phalanx"
}
EditorSpecialObjective._enemies = {}
EditorSpecialObjective._nav_link_filter = {}
EditorSpecialObjective._nav_link_filter_check_boxes = {}
function EditorSpecialObjective:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpecialObjective"
	self._element.values.ai_group = "none"
	self._element.values.align_rotation = true
	self._element.values.align_position = true
	self._element.values.needs_pos_rsrv = true
	self._element.values.scan = true
	self._element.values.patrol_path = "none"
	self._element.values.path_style = "none"
	self._element.values.path_haste = "none"
	self._element.values.path_stance = "none"
	self._element.values.pose = "none"
	self._element.values.so_action = "none"
	self._element.values.search_position =  Vector3(0,0,0)
	self._element.values.search_distance = 0
	self._element.values.interval = ElementSpecialObjective._DEFAULT_VALUES.interval
	self._element.values.base_chance = ElementSpecialObjective._DEFAULT_VALUES.base_chance
	self._element.values.chance_inc = 0
	self._element.values.action_duration_min = ElementSpecialObjective._DEFAULT_VALUES.action_duration_min
	self._element.values.action_duration_max = ElementSpecialObjective._DEFAULT_VALUES.action_duration_max
	self._element.values.interrupt_dis = 7
	self._element.values.interrupt_dmg = ElementSpecialObjective._DEFAULT_VALUES.interrupt_dmg
	self._element.values.attitude = "none"
	self._element.values.trigger_on = "none"
	self._element.values.interaction_voice = "none"
	self._element.values.SO_access = "0"
	self._element.values.test_unit = "default"	
end

function EditorSpecialObjective:post_init(...)
	EditorSpecialObjective.super.post_init(self, ...)
	self._nav_link_filter = managers.navigation:convert_access_filter_to_table(self._element.values.SO_access)
	if type_name(self._element.values.SO_access) == "number" then
		self._element.values.SO_access = tostring(self._element.values.SO_access)
	end
end

function EditorSpecialObjective:test_element()
	if not managers.navigation:is_data_ready() then
	 	BeardLibEditor:log("Can't test spawn unit without ready navigation data (AI-graph)")
		return
	end
	local spawn_unit_name
	if self._element.values.test_unit == "default" then
		local SO_access_strings = managers.navigation:convert_access_filter_to_table(self._element.values.SO_access)
		for _, access_category in ipairs(SO_access_strings) do
			if access_category == "civ_male" then
				spawn_unit_name = Idstring("units/payday2/characters/civ_male_casual_1/civ_male_casual_1")
				break
			elseif access_category == "civ_female" then
				spawn_unit_name = Idstring("units/payday2/characters/civ_female_casual_1/civ_female_casual_1")
				break
			elseif access_category == "spooc" then
				spawn_unit_name = Idstring("units/payday2/characters/ene_spook_1/ene_spook_1")
				break
			elseif access_category == "shield" then
				spawn_unit_name = Idstring("units/payday2/characters/ene_shield_2/ene_shield_2")
				break
			elseif access_category == "tank" then
				spawn_unit_name = Idstring("units/payday2/characters/ene_bulldozer_1/ene_bulldozer_1")
				break
			elseif access_category == "taser" then
				spawn_unit_name = Idstring("units/payday2/characters/ene_tazer_1/ene_tazer_1")
				break
			else
				spawn_unit_name = Idstring("units/payday2/characters/ene_swat_1/ene_swat_1")
				break
			end
		end
	else
		spawn_unit_name = self._element.values.test_unit
	end
	spawn_unit_name = spawn_unit_name or Idstring("units/payday2/characters/ene_swat_1/ene_swat_1")
	local enemy = safe_spawn_unit(spawn_unit_name, self._unit:position(), self._unit:rotation())
	if not enemy then
		return
	end
	table.insert(self._enemies, enemy)
	managers.groupai:state():set_char_team(enemy, tweak_data.levels:get_default_team_ID("non_combatant"))
	enemy:movement():set_root_blend(false)
	local t = {
		id = self._unit:unit_data().unit_id,
		editor_name = self._unit:unit_data().name_id
	}
	t.values = self:new_save_values()
	t.values.use_instigator = true
	t.values.is_navigation_link = false
	t.values.followup_elements = nil
	t.values.trigger_on = "none"
	t.values.spawn_instigator_ids = nil
	self._script = MissionScript:new({
		elements = {}
	})
	self._so_class = ElementSpecialObjective:new(self._script, t)
	self._so_class._values.align_position = nil
	self._so_class._values.align_rotation = nil
	self._so_class:on_executed(enemy)
	self._start_test_t = Application:time()
end

function EditorSpecialObjective:stop_test_element()
	for _, enemy in ipairs(self._enemies) do
		enemy:set_slot(0)
	end
	self._enemies = {}
	print("Stop test time", self._start_test_t and Application:time() - self._start_test_t or 0)
end

function EditorSpecialObjective:draw_links()
	EditorSpecialObjective.super.draw_links(self)
	self:_draw_follow_up()
end

function EditorSpecialObjective:_highlight_if_outside_the_nav_field(t)
	if managers.navigation:is_data_ready() then
		local my_pos = self._unit:position()
		local nav_tracker = managers.navigation._quad_field:create_nav_tracker(my_pos, true)
		if nav_tracker:lost() then
			local t1 = t % 0.5
			local t2 = t % 1
			local alpha
			if t2 > 0.5 then
				alpha = t1
			else
				alpha = 0.5 - t1
			end
			alpha = math.lerp(0.1, 0.5, alpha)
			local nav_color = Color(alpha, 1, 0, 0)
			Draw:brush(nav_color):cylinder(my_pos, my_pos + math.UP * 80, 20, 4)
		end
		managers.navigation:destroy_nav_tracker(nav_tracker)
	end
end

function EditorSpecialObjective:update_unselected(t, dt, selected_unit, all_units)
	if self._element.values.followup_elements then
		local followup_elements = self._element.values.followup_elements
		local i = #followup_elements
		while i > 0 do
			local element_id = followup_elements[i]
			if not alive(all_units[element_id]) then
				table.remove(followup_elements, i)
			end
			i = i - 1
		end
		if not next(followup_elements) then
			self._element.values.followup_elements = nil
		end
	end
	if self._element.values.spawn_instigator_ids then
		local spawn_instigator_ids = self._element.values.spawn_instigator_ids
		local i = #spawn_instigator_ids
		while i > 0 do
			local id = spawn_instigator_ids[i]
			if not alive(all_units[id]) then
				table.remove(self._element.values.spawn_instigator_ids, i)
			end
			i = i - 1
		end
		if not next(spawn_instigator_ids) then
			self._element.values.spawn_instigator_ids = nil
		end
	end
end

function EditorSpecialObjective:_draw_follow_up()
    local selected_unit = self:selected_unit()
    local unit_sel = self._unit == selected_unit
	if self._element.values.followup_elements then
		for _, element_id in ipairs(self._element.values.followup_elements) do
			local unit = self:Manager("mission"):get_element_unit(element_id)
			local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
			if draw then
				self:draw_link({
					from_unit = self._unit,
					to_unit = unit,
					r = 0,
					g = 0.75,
					b = 0
				})
			end
		end
	end
end

function EditorSpecialObjective:update_editing()
	self:_so_raycast()
	self:_spawn_raycast()
	self:_raycast()
end

function EditorSpecialObjective:_so_raycast()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and (string.find(ray.unit:name():s(), "point_special_objective", 1, true) or string.find(ray.unit:name():s(), "ai_so_group", 1, true)) then
		local id = ray.unit:unit_data().unit_id
		Application:draw(ray.unit, 0, 1, 0)
		return id
	end
	return nil
end

function EditorSpecialObjective:_spawn_raycast()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if not ray or not ray.unit then
		return
	end
	local id
	if string.find(ray.unit:name():s(), "ai_enemy_group", 1, true) or string.find(ray.unit:name():s(), "ai_spawn_enemy", 1, true) or string.find(ray.unit:name():s(), "ai_civilian_group", 1, true) or string.find(ray.unit:name():s(), "ai_spawn_civilian", 1, true) then
		id = ray.unit:unit_data().unit_id
		Application:draw(ray.unit, 0, 0, 1)
	end
	return id
end

function EditorSpecialObjective:_raycast()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(100000)
	local ray = World:raycast(from, to, nil, managers.slot:get_mask("all"))
	if ray and ray.position then
		Application:draw_sphere(ray.position, 10, 1, 1, 1)
		return ray.position
	end
	return nil
end

function EditorSpecialObjective:_lmb()
	local id = self:_so_raycast()
	if id then
		if self._element.values.followup_elements then
			for i, element_id in ipairs(self._element.values.followup_elements) do
				if element_id == id then
					table.remove(self._element.values.followup_elements, i)
					if not next(self._element.values.followup_elements) then
						self._element.values.followup_elements = nil
					end
					return
				end
			end
		end
		self._element.values.followup_elements = self._element.values.followup_elements or {}
		table.insert(self._element.values.followup_elements, id)
		return
	end
	local id = self:_spawn_raycast()
	if id then
		if self._element.values.spawn_instigator_ids then
			for i, si_id in ipairs(self._element.values.spawn_instigator_ids) do
				if si_id == id then
					table.remove(self._element.values.spawn_instigator_ids, i)
					if not next(self._element.values.spawn_instigator_ids) then
						self._element.values.spawn_instigator_ids = nil
					end
					return
				end
			end
		end
		self._element.values.spawn_instigator_ids = self._element.values.spawn_instigator_ids or {}
		table.insert(self._element.values.spawn_instigator_ids, id)
		return
	end
	self._element.values.search_position = self:_raycast() or self._element.values.search_position
end

function EditorSpecialObjective:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "_lmb"))
end

function EditorSpecialObjective:_apply_preset(menu, item)
	local selection = item:SelectedItem()
	QuickMenuPlus:new("Special objective", "Apply access flag preset " .. (selection or "")  .. "?", {{text = "Yes", callback = function()
		if selection == "clear all" then
			self._element.values.SO_access = managers.navigation:convert_access_filter_to_string({})
		elseif selection == "select all" then
			self._element.values.SO_access = managers.navigation:convert_access_filter_to_string(NavigationManager.ACCESS_FLAGS)
		end 	
	end},{text = "No", is_cancel_button = true}})
end

function EditorSpecialObjective:_toggle_nav_link_filter_value(item)
	if item.value then
		for i, k in ipairs(self._nav_link_filter) do
			if k == item.name then
				return
			end
		end
		table.insert(self._nav_link_filter, item.name)
	else
		table.delete(self._nav_link_filter, item.name)
	end
	self._element.values.SO_access = managers.navigation:convert_access_filter_to_string(self._nav_link_filter)
end

function EditorSpecialObjective:manage_flags()
    BeardLibEditor.managers.SelectDialog:Show({
        selected_list = managers.navigation:convert_access_filter_to_table(self._element.values.SO_access),
        list = NavigationManager.ACCESS_FLAGS,
        callback = function(list) self._element.values.SO_access = managers.navigation:convert_access_filter_to_string(list) end
    })
end

function EditorSpecialObjective:_build_panel()
	self:_create_panel()
	self._nav_link_filter_check_boxes = self._nav_link_filter_check_boxes or {}

	self._nav_link_filter = managers.navigation:convert_access_filter_to_table(self._element.values.SO_access)
	self:ComboBox("AccessFlagsPreset", callback(self, self, "_apply_preset"), {"clear all", "select all"}, nil, {group = self._class_group, help = "Here you can quickly select or deselect all access flags"})
	self:Button("ManageAccessFlags", callback(self, self, "manage_flags"), {group = self._class_group, help = "Decide which types of AI are affected by this element"})
	self:BooleanCtrl("is_navigation_link", {text = "Navigation link"})
	self:BooleanCtrl("align_rotation", {text = "Align rotation"})
	self:BooleanCtrl("align_position", {text = "Align position"})
	self:BooleanCtrl("needs_pos_rsrv", {text = "Reserve position"})
	self:BooleanCtrl("repeatable", {text = "Repeatable"})
	self:BooleanCtrl("use_instigator", {text = "Use instigator"})
	self:BooleanCtrl("forced", {text = "Forced"})
	self:BooleanCtrl("no_arrest", {text = "No Arrest"})
	self:BooleanCtrl("scan", {text = "Idle scan"})
	self:BooleanCtrl("allow_followup_self", {text = "Allow self-followup"})
	self:ComboCtrl("ai_group", table.list_add({"none"}, clone(ElementSpecialObjective._AI_GROUPS)), {help = "Select an ai group."})
	self:ComboCtrl("so_action", table.list_add(table.list_add({"none"}, clone(CopActionAct._act_redirects.SO)), self._AI_SO_types), {help = "Select a action that the unit should start with."})
	self:ComboCtrl("path_style", table.list_add({"none"}, ElementSpecialObjective._PATHING_STYLES), {help = "Specifies how the patrol path should be used."})
	self:ComboCtrl("path_haste", table.list_add({"none"}, ElementSpecialObjective._HASTES), {help = "Select path haste to use."})
	self:ComboCtrl("path_stance", table.list_add({"none"}, ElementSpecialObjective._STANCES), {help = "Select path stance to use."})
	self:ComboCtrl("pose", table.list_add({"none"}, ElementSpecialObjective._POSES), {help = "Select pose to use."})
	self:ComboCtrl("attitude", table.list_add({"none"}, ElementSpecialObjective._ATTITUDES), {help = "Select combat attitude."})
	self:ComboCtrl("trigger_on", table.list_add({"none"}, ElementSpecialObjective._TRIGGER_ON), {help = "Select when to trigger objective."})
	self:ComboCtrl("interaction_voice", table.list_add({"none"}, ElementSpecialObjective._INTERACTION_VOICES), {help = "Select what voice to use when interacting with the character."})
	self:NumberCtrl("search_distance", {min = 0, help = "Used to specify the distance to use when searching for an AI"})
	self:NumberCtrl("interrupt_dis", {
		min = -1, 
		help = "Interrupt if a threat is detected closer than this distance (meters). -1 means at any distance. For non-visible threats this value is multiplied with 0.7.", 
		text = "Interrupt Distance:"
	})
	self:NumberCtrl("interrupt_dmg", {min = -1, 
		help = "Interrupt if total damage received as a ratio of total health exceeds this ratio. value: 0-1.", 
		text = "Interrupt Damage:"
	})
	self:NumberCtrl("interval", {min = -1, help = "Used to specify how often the SO should search for an actor. A negative value means it will check only once."})
	self:NumberCtrl("base_chance", {min = 0, max = 1,  help = "Used to specify chance to happen (1==absolutely!)"})
	self:NumberCtrl("chance_inc", {min = 0, max = 1, help = "Used to specify an incremental chance to happen", text = "Chance incremental:"})
	self:NumberCtrl("action_duration_min", {min = 0, help = "How long the character stays in his specified action."})
	self:NumberCtrl("action_duration_max", {min = 0, help = "How long the character stays in his specified action. Zero means indefinitely."})
end
 