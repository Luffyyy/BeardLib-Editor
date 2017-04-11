EditorCharacterOutline = EditorCharacterOutline or class(MissionScriptEditor)
function EditorCharacterOutline:create_element()
	self.super.create_element(self)
	self._element.class = "ElementCharacterOutline"
end