EditorGameDirection = EditorGameDirection or class(MissionScriptEditor)
function EditorGameDirection:create_element()
    self.super.create_element(self)
    self._element.class = "ElementGameDirection" 
end
