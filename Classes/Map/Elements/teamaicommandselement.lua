EditorTeamAICommands = EditorTeamAICommands or class(MissionScriptEditor)
EditorTeamAICommands.SAVE_UNIT_POSITION = false
EditorTeamAICommands.SAVE_UNIT_ROTATION = false
function EditorTeamAICommands:create_element(...)
	EditorTeamAICommands.super.create_element(self, ...)
	self._element.class = "ElementTeamAICommands"
	self._element.values.elements = {}
	self._element.values.command = "none"
end

function EditorTeamAICommands:_build_panel()
	self:_create_panel()
	self:ComboCtrl("command", {"none","enter_bleedout","enter_custody","ignore_player"}, {help = "Select an team AI command"})
end