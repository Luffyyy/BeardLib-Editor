EditorLootPile = EditorLootPile or class(MissionScriptEditor)
EditorLootPile.USES_POINT_ORIENTATION = true
function EditorLootPile:create_element(...)
	EditorLootPile.super.create_element(self, ...)
	self._element.class = "ElementLootPile"
	self._element.values.carry_id = ""
	self._element.values.max_loot = -1
	self._element.values.retry_delay = 5
	self._element.values.reissue_delay = 30
end
function EditorLootPile:_build_panel()
	self:_create_panel()
	self:NumberCtrl("max_loot", {min = -1, help = "The maximum number of bags that can be picked up from this loot pile. -1 for unlimited."})
	self:ComboCtrl("carry_id", table.list_add({"none"}, tweak_data.carry:get_carry_ids()), {help = "Select a carry_id to be created."})
	self:NumberCtrl("retry_delay", {min = 1}, {help = "The time in seconds after failing to find a suitable drop off point that the AI system will try again."})
	self:NumberCtrl("reissue_delay", {min = 1}, {help = "The time in seconds after sending the SO to grab a bag that the system will reissue the SO."})
end