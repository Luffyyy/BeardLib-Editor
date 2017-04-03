EditorLootSecuredTrigger = EditorLootSecuredTrigger or class(MissionScriptEditor)
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
	self:NumberCtrl("amount", {min = 0, help = "Minimum amount of loot required to trigger"})
	self:BooleanCtrl("include_instant_cash")
	self:BooleanCtrl("report_only")
end
