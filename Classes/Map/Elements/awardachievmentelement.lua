EditorAwardAchievment = EditorAwardAchievment or class(MissionScriptEditor)
function EditorAwardAchievment:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAwardAchievment"
	self._element.values.achievment = nil
	self._element.values.award_instigator = false
	self._element.values.players_from_start = nil
end
function EditorAwardAchievment:_build_panel()
	self:_create_panel()
	self:ComboCtrl("achievment", table.list_add({"none"}, table.map_keys(managers.achievment.achievments)))
	self:BooleanCtrl("award_instigator", {help = "Award only the instigator (Player or driver in vehicle)?"})
	self:BooleanCtrl("players_from_start", {help = "Only award to players that joined from start."})
	self:Text("Awards a Steam Achievment")
end
