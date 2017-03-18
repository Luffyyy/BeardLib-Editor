EditorTeleportPlayer = EditorTeleportPlayer or class(MissionScriptEditor)
function EditorTeleportPlayer:create_element()
	self.super.create_element(self)
	self._element.class = "EditorTeleportPlayer"
end