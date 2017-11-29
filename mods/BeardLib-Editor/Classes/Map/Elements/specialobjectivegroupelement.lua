EditorSpecialObjectiveGroup = EditorSpecialObjectiveGroup or class(MissionScriptEditor)
function EditorSpecialObjectiveGroup:create_element()
    self.super.create_element(self)
	self._element.class = "ElementSpecialObjectiveGroup"
	self._element.values.base_chance = 1
	self._element.values.use_instigator = false
	self._element.values.followup_elements = nil
	self._element.values.spawn_instigator_ids = nil
	self._element.values.mode = "randomizer"
end

function EditorSpecialObjectiveGroup:_build_panel()
	self:_create_panel()
	self:ComboCtrl("mode", {"randomizer","forced_spawn","recurring_cloaker_spawn","recurring_spawn_1"}, {
		help = "Randomizer: assigns SOs to instigators. Forced Spawn: Will spawn a new group of choice. Recurring: Spawns new group. After failure, a new group will be spawned with a delay."
	})
	self:BooleanCtrl("use_instigator")
	self:NumberCtrl("base_chance", {min = 0, max = 1, floats = 2, help = "Used to specify chance to happen (1==absolutely!)"})
	self:BuildElementsManage("spawn_instigator_ids", nil, {"ElementSpawnEnemyGroup"})
	self:BuildElementsManage("followup_elements", nil, {"ElementSpecialObjective"})
end
