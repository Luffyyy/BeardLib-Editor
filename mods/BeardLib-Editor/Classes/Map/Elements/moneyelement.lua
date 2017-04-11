EditorMoney = EditorMoney or class(MissionScriptEditor)
EditorMoney.actions = {
	"none",
	"AddOffshore",
	"DeductOffshore",
	"AddSpending",
	"DeductSpending"
}
function EditorMoney:create_element()
	EditorMoney.super.create_element(self)
	self._element.class = "ElementMoney"
	self._element.values.action = "none"
	self._element.values.amount = 0
	self._element.values.remove_all = false
	self._element.values.only_local_player = true
end
function EditorMoney:_build_panel()
	self:_create_panel()
	self:ComboCtrl("action", EditorMoney.actions)
	self:NumberCtrl("amount", {floats = 0})
	self:BooleanCtrl("only_local_player", {help = "Execute only if the local player is the instigator."})
	self:BooleanCtrl("remove_all", {text = "Remove all when deducting", help = "Remove all spending/offshore if deducting."})
	self:Text([[
Used to add or deduct money from the player's spending cash or offshore account.
Enable "only if local player is instigator" if the player activates this, instead of a mission script. ie. offshore gambling]])
end
EditorMoneyFilter = EditorMoneyFilter or class(MissionScriptEditor)
function EditorMoneyFilter:create_element()
	EditorMoneyFilter.super.create_element(self)
	self._element.class = "ElementMoneyFilter"
	self._element.values.value = 0
	self._element.values.account = "offshore"
	self._element.values.check_type = "equal"
	self._element.values.only_local_player = true
end
function EditorMoneyFilter:_build_panel()
	self:_create_panel()
	self:NumCtrl("value", {floats = 0, help = "Specify cash value to trigger on."})
	self:ComboCtrl("account", {"offshore", "spending"}, {help = "Select which account to check."})
	self:ComboCtrl("check_type", {"equal","less_than","greater_than","less_or_equal","greater_or_equal"}, {help = "Select which check operation to perform."})
	self:BooleanCtrl("only_local_player", {help = "Only run if the local player is the instigator."})
	self:Text("Checks that the player has the required amount of cash in their spending or offshore accounts.")
end
