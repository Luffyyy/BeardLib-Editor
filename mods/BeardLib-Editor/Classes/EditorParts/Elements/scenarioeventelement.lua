EditorScenarioEvent = EditorScenarioEvent or class(MissionScriptEditor)
function EditorScenarioEvent:init(unit)
	EditorScenarioEvent.super.init(self, unit)
end
function EditorScenarioEvent:create_element()
	self.super.create_element(self)	
	self._element.class = "ElementScenarioEvent"
	self._element.values.amount = 1
	self._element.values.task = managers.groupai:state():task_names()[1]
	self._element.values.base_chance = 1
	self._element.values.chance_inc = 0
end
function EditorScenarioEvent:_build_panel()
	self:_create_panel()
	self:_build_value_number("amount", {min = 1, max = 25}, "Should be set to the amount of enemies that will be created from this event", "Amount")
	self:_build_value_combobox("task", managers.groupai:state():task_names(), "Select a task from the combobox", "Task")
	self:_build_value_number("base_chance", {min = 0, max = 1}, "Used to specify chance to happen (1==absolutely!)", "Base chance")
	self:_build_value_number("chance_inc", {min = 0, max = 1}, "Used to specify an incremental chance to happen", "Chance incremental")
end
