EditorTeamRelation = EditorTeamRelation or class(MissionScriptEditor)
function EditorTeamRelation:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTeamRelation"
	self._element.values.team1 = ""
	self._element.values.team2 = ""
	self._element.values.relation = "friend"
	self._element.values.mutual = true
end

function EditorTeamRelation:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("mutual")
	self:ComboCtrl("team1", table.list_add({""}, tweak_data.levels:get_team_names_indexed()), {help = "Select the team that will change attitude."})
	self:ComboCtrl("team2", table.list_add({""}, tweak_data.levels:get_team_names_indexed()), {help = "Select the team that will change attitude."})
	self:ComboCtrl("relation", {
		"friend",
		"foe",
		"neutral"
	}, {help = "Select the new relation."})
end
