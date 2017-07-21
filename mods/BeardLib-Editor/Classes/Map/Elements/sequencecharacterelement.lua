EditorSequenceCharacter = EditorSequenceCharacter or class(MissionScriptEditor)
function EditorSequenceCharacter:create_element()
    self.super.create_element(self)
	self._element.class = "ElementSequenceCharacter"
	self._element.values.elements = {}
	self._element.values.sequence = ""    
end

function EditorSequenceCharacter:_build_panel()
	self:_create_panel()
	self:StringCtrl("sequence")
	self:BuildElementsManage("sequence", nil, {"ElementSpawnEnemyDummy"})
end
 
 