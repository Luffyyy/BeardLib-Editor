EditorAwardAchievment = EditorAwardAchievment or class(MissionScriptEditor)
function EditorAwardAchievment:init(unit)
	EditorAwardAchievment.super.init(self, unit)
end
function EditorAwardAchievment:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAwardAchievment"
	self._element.values.achievment = nil
	self._element.values.award_instigator = false
	self._element.values.players_from_start = nil
end
function EditorAwardAchievment:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("achievment", table.list_add({"none"}, table.map_keys(managers.achievment.achievments)))
	self:_build_value_checkbox("award_instigator", "Award only the instigator (Player or driver in vehicle)?")
	self:_build_value_checkbox("players_from_start", "Only award to players that joined from start.")
	local help = {}
	help.text = "Awards a PSN Trophy or Steam Achievment"
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
