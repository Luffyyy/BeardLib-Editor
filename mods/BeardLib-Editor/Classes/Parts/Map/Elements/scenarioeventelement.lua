EditorScenarioEvent = EditorScenarioEvent or class(MissionScriptEditor)
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
	self:NumberCtrl("amount", {
		min = 1, 
		max = 25,
		help = "Should be set to the amount of enemies that will be created from this event", 
	})
	self:ComboCtrl("task", managers.groupai:state():task_names(), {
		help = "Select a task from the combobox"
	})
	self:NumberCtrl("base_chance", {min = 0, max = 1, help = "Used to specify chance to happen (1==absolutely!)"})
	self:NumberCtrl("chance_inc", {min = 0, max = 1, help = "Used to specify an incremental chance to happen", text = "Chance incremental"})
end
