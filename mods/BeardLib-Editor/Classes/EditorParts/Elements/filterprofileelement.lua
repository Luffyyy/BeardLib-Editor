EditorProfileFilter = EditorProfileFilter or class(MissionScriptEditor)
function EditorProfileFilter:init(unit)
	EditorProfileFilter.super.init(self, unit)
end

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
	self:_build_value_number("player_lvl", {
		min = 0,
		max = 100
	}, "Set player level filter")
	self:_build_value_number("money_earned", {
		min = 0,
		max = 1000000
	}, "Set player level filter")
	self:_build_value_number("money_offshore", {
		min = 0,
		max = 1000000
	}, "Set money offshore filter, in thousands.")
	self:_build_value_combobox("achievement", table.list_add({"none"}, table.map_keys(managers.achievment.achievments)), "Select an achievement to filter on")
end
