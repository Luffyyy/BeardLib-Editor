EditorCharacterTeam = EditorCharacterTeam or class(MissionScriptEditor)
EditorCharacterTeam.SAVE_UNIT_POSITION = false
EditorCharacterTeam.SAVE_UNIT_ROTATION = false
function EditorCharacterTeam:create_element()
	self.super.create_element(self)
	self._element.class = "ElementCharacterTeam"
	self._element.values.elements = {}
	self._element.values.ignore_disabled = nil
	self._element.values.team = ""
	self._element.values.use_instigator = nil
end

function EditorCharacterTeam:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:_build_value_checkbox("use_instigator")
	self:_build_value_checkbox("ignore_disabled")
	self:_build_value_combobox("team", tweak_data.levels:get_team_names_indexed(), "Select wanted team for the character.")
end
