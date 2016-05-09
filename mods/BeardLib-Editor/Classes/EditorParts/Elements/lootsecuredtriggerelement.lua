EditorLootSecuredTrigger = EditorLootSecuredTrigger or class(MissionScriptEditor)
EditorLootSecuredTrigger.SAVE_UNIT_POSITION = false
EditorLootSecuredTrigger.SAVE_UNIT_ROTATION = false
function EditorLootSecuredTrigger:init(unit)
	EditorLootSecuredTrigger.super.init(self, unit)
end

function EditorLootSecuredTrigger:create_element()
    self.super.create_element(self)
 	self._element.class = "ElementLootSecuredTrigger"
	self._element.values.trigger_times = 1
	self._element.values.amount = 0
	self._element.values.include_instant_cash = false
	self._element.values.report_only = false   
end

function EditorLootSecuredTrigger:_build_panel()
	self:_create_panel()
	self:_build_value_number("amount", {min = 0}, "Minimum amount of loot required to trigger")
	self:_build_value_checkbox("include_instant_cash")
	self:_build_value_checkbox("report_only")
end
