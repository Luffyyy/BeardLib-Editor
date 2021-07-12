EditorRelativeTeleportTarget = EditorRelativeTeleportTarget or class(MissionScriptEditor)
function EditorRelativeTeleportTarget:create_element()
	self.super.create_element(self)
	self._element.class = "ElementRelativeTeleportTarget"
end