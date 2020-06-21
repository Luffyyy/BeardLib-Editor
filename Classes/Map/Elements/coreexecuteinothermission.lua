EditorExecuteInOtherMission = EditorExecuteInOtherMission or class(MissionScriptEditor)
EditorExecuteInOtherMission.SKIP_SCRIPT_CHECK = true
function EditorExecuteInOtherMission:create_element(...)
	EditorExecuteInOtherMission.super.create_element(self, ...)
	self._element.class = "ElementExecuteInOtherMission"
end