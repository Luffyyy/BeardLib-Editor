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
	self._element.values.search_position = self._element.values.position
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
	self._element.values.followup_elements = {}
	self._element.values.spawn_instigator_ids = {}
	self._element.values.test_unit = "default"	
end

function EditorSpecialObjective:draw_links()
	EditorSpecialObjective.super.draw_links(self)
	self:_draw_follow_up()
end

function EditorSpecialObjective:update(t, dt)
	if self._element.values.search_position then
    	Application:draw_sphere(self._element.values.search_position, 10, 1, 0, 0)
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

function EditorSpecialObjective:apply_preset(menu, item)
	local selection = item:SelectedItem()
	BeardLibEditor.Utils:YesNoQuestion("This will apply the access flag preset " .. (selection or ""), function()
		if selection == "clear all" then
			self._element.values.SO_access = managers.navigation:convert_access_filter_to_string({})
		elseif selection == "select all" then
			self._element.values.SO_access = managers.navigation:convert_access_filter_to_string(NavigationManager.ACCESS_FLAGS)
		end 	
	end)
end

function EditorSpecialObjective:manage_flags()
    BeardLibEditor.managers.SelectDialog:Show({
        selected_list = managers.navigation:convert_access_filter_to_table(self._element.values.SO_access),
        list = NavigationManager.ACCESS_FLAGS,
        callback = function(list) self._element.values.SO_access = managers.navigation:convert_access_filter_to_string(list) end
    })
end

function EditorSpecialObjective:set_element_position(...)
    self.super.set_element_position(self, ...)
    self._element.values.search_position = self:AxisControlsPosition("SearchPosition")
end

function EditorSpecialObjective:_build_panel()
	self:_create_panel()
	self._nav_link_filter = managers.navigation:convert_access_filter_to_table(self._element.values.SO_access)
	if type_name(self._element.values.SO_access) == "number" then
		self._element.values.SO_access = tostring(self._element.values.SO_access)
	end
	self:ComboBox("AccessFlagsPreset", callback(self, self, "apply_preset"), {"clear all", "select all"}, nil, {group = self._class_group, help = "Here you can quickly select or deselect all access flags"})
	self:Button("ManageAccessFlags", callback(self, self, "manage_flags"), {group = self._class_group, help = "Decide which types of AI are affected by this element"})
	self:BuildElementsManage("followup_elements", nil, {"ElementSpecialObjective", "ElementSpecialObjectiveGroup"})
	self:BuildElementsManage("spawn_instigator_ids", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian", "ElementSpawnEnemyGroup", "ElementSpawnCivilianGroup"})
	self:AxisControls(callback(self, self, "set_element_position"), {no_rot = true, group = self._class_group}, "SearchPosition")
	self:SetAxisControls(self._element.values.search_position, nil, "SearchPosition")
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
	local none = {"none"}
	self:ComboCtrl("ai_group", table.list_add(none, ElementSpecialObjective._AI_GROUPS), {help = "Select an ai group."})
	self:ComboCtrl("so_action", table.list_add(none, CopActionAct._act_redirects.SO, CopActionAct._act_redirects.script, self._AI_SO_types), {help = "Select a action that the unit should start with."})
	self:ComboCtrl("path_style", table.list_add(none, ElementSpecialObjective._PATHING_STYLES), {help = "Specifies how the patrol path should be used."})
	self:ComboCtrl("path_haste", table.list_add(none, ElementSpecialObjective._HASTES), {help = "Select path haste to use."})
	self:ComboCtrl("path_stance", table.list_add(none, ElementSpecialObjective._STANCES), {help = "Select path stance to use."})
	self:ComboCtrl("pose", table.list_add(none, ElementSpecialObjective._POSES), {help = "Select pose to use."})
	self:ComboCtrl("attitude", table.list_add(none, ElementSpecialObjective._ATTITUDES), {help = "Select combat attitude."})
	self:ComboCtrl("trigger_on", table.list_add(none, ElementSpecialObjective._TRIGGER_ON), {help = "Select when to trigger objective."})
	self:ComboCtrl("interaction_voice", table.list_add(none, ElementSpecialObjective._INTERACTION_VOICES), {help = "Select what voice to use when interacting with the character."})
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