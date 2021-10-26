EditorTerminateAssault = EditorTerminateAssault or class(MissionScriptEditor)
function EditorTerminateAssault:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTerminateAssault"
end

function EditorTerminateAssault:_build_panel()
    self:_create_panel()
    self:Text("This element will stop the current assault, and will hide the assault corner HUD element.")
end
