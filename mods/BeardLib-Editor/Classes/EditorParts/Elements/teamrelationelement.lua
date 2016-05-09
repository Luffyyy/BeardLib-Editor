EditorTeamRelation = EditorTeamRelation or class(MissionScriptEditor)
EditorTeamRelation.SAVE_UNIT_POSITION = false
EditorTeamRelation.SAVE_UNIT_ROTATION = false
function EditorTeamRelation:init(unit)
	MissionScriptEditor.init(self, unit)
end
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
	self:_build_value_checkbox("mutual")
	self:_build_value_combobox("team1", table.list_add({""}, tweak_data.levels:get_team_names_indexed()), "Select the team that will change attitude.")
	self:_build_value_combobox("team2", table.list_add({""}, tweak_data.levels:get_team_names_indexed()), "Select the team that will change attitude.")
	self:_build_value_combobox("relation", {
		"friend",
		"foe",
		"neutral"
	}, "Select the new relation.")
end
