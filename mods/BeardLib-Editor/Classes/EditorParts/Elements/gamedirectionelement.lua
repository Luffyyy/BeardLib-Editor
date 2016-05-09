EditorGameDirection = EditorGameDirection or class(MissionScriptEditor)
function EditorGameDirection:init(unit)
	MissionScriptEditor.init(self, unit)
end

function EditorGameDirection:create_element()
    self.super.create_element(self)
    self._element.class = "ElementGameDirection" 
end

function EditorGameDirection:_build_panel()
end
