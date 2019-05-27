EditorExecuteInOtherMission = EditorExecuteInOtherMission or class(MissionScriptEditor)
function EditorExecuteInOtherMission:create_elemet(...)
	EditorExecuteInOtherMission.create_elemet(self, ...)
	self._element.class = "ElementExecuteInOtherMission"
end