EditorCharacterTeam = EditorCharacterTeam or class(MissionScriptEditor)
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
	self:BuildElementsManage("elements", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:BooleanCtrl("use_instigator")
	self:BooleanCtrl("ignore_disabled")
	self:ComboCtrl("team", tweak_data.levels:get_team_names_indexed(), {help = "Select wanted team for the character."})
end
