EditorProfileFilter = EditorProfileFilter or class(MissionScriptEditor)
function EditorProfileFilter:create_element()
	self.super.create_element(self)
 	self._element.class = "ElementProfileFilter"
	self._element.values.player_lvl = 0
	self._element.values.money_earned = 0
	self._element.values.money_offshore = 0
	self._element.values.achievement = "none"
end

function EditorProfileFilter:_build_panel()
	self:_create_panel()
	self:NumberCtrl("player_lvl", {
		min = 0,
		max = 100, 
		help = "Set player level filter"
	})
	self:NumberCtrl("money_earned", {
		min = 0,
		max = 1000000, 
		help = "Set player level filter"
	})
	self:NumberCtrl("money_offshore", {
		min = 0,
		max = 1000000, 
		help = "Set money offshore filter, in thousands."
	})
	self:ComboCtrl("achievement", table.list_add({"none"}, table.map_keys(managers.achievment.achievments)), {help = "Select an achievement to filter on"})
end
