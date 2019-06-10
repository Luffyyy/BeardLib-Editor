EditorScenarioEvent = EditorScenarioEvent or class(MissionScriptEditor)
function EditorScenarioEvent:create_element(...)
	EditorScenarioEvent.super.create_element(self, ...)
	self._element.class = "ElementScenarioEvent"
	self._element.values.amount = 1
	self._element.values.task = managers.groupai:state():task_names()[1]
	self._element.values.base_chance = 1
	self._element.values.chance_inc = 0
end

function EditorScenarioEvent:_build_panel()
	self:_create_panel()
	self:NumberCtrl("amount", {min = 1, max = 25, floats = 0, help = "Should be set to the amount of enemies that will be created from this event"})
	self:NumberCtrl("base_chance", {min = 0, max = 1, floats = 2, help = "Used to specify chance to happen (1==absolutely!)"})
	self:NumberCtrl("chance_inc", {min = 0, max = 1, floats = 2, help = "Used to specify an incremental chance to happen"})
	self:ComboCtrl("task", managers.groupai:state():task_names())
end