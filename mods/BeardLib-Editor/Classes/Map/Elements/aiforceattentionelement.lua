EditorAIForceAttention = EditorAIForceAttention or class(MissionScriptEditor)
function EditorAIForceAttention:create_element(...)
	EditorAIForceAttention.super.create_element(self, ...)
	self._element.class = "ElementAIForceAttention"
	self._element.values.affected_units = {}
	self._element.values.use_force_spawned = false
	self._element.values.ignore_vis_blockers = false
	self._element.values.include_all_force_spawns = false
	self._element.values.included_units = {}
	self._element.values.excluded_units = {}
	self._element.values.is_spawn = false
end

function EditorAIForceAttention:set_is_spawn()
	local selected = self._element.values.att_unit_id and managers.mission:get_element_by_id(self._element.values.att_unit_id)
	if selected then
		for _, class in pairs({"ElementSpawnEnemyDummy","ElementSpawnEnemyGroup","ElementSpawnCivilian","ElementSpawnCivilianGroup","ElementSpawnPlayer"}) do
			if selected.class == class then
				self._element.values.is_spawn = true
				return
			end
		end
		self._element.values.is_spawn = false
	else
		self._element.values.is_spawn = false
	end
end

function EditorAIForceAttention:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("ignore_vis_blockers", {help = "Allows the affected units to shoot through vis_blockers", group = affected_units})
	self:BooleanCtrl("include_all_force_spawns", {help = "Includes all units that don't participate in the group AI", group = affected_units})
	self:BuildElementsManage("included_units", nil, {"ElementSpawnEnemyDummy", "ElementSpawnEnemyGroup"})
	self:BuildElementsManage("excluded_units", nil, {"ElementSpawnEnemyDummy", "ElementSpawnEnemyGroup"})
	self:BuildElementsManage("att_unit_id", nil, nil, callback(self, self, "set_is_spawn"), {single_select = true, not_table = true})
	self:Text("Select a unit to force the AI's attention to. The 'Affected Units' panel allows you to control which units are affected by this and their behaviour.")
end