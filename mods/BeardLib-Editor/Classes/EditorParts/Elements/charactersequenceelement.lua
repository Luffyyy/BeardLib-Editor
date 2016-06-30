EditorCharacterSequence = EditorCharacterSequence or class(MissionScriptEditor)
EditorCharacterSequence.SAVE_UNIT_POSITION = false
EditorCharacterSequence.SAVE_UNIT_ROTATION = false
function EditorCharacterSequence:create_element()
	EditorCharacterSequence.super.create_element(self)
	self._element.class = "ElementCharacterSequence"
	self._element.values.elements = {}
	self._element.values.sequence = ""
end
function EditorCharacterSequence:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:_build_value_checkbox("use_instigator")
	self:_build_value_text("sequence")
end
