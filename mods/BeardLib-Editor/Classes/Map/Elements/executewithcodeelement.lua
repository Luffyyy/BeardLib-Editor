EditorExecuteWithCode = EditorExecuteWithCode or class(MissionScriptEditor)
function EditorExecuteWithCode:create_element()
    self.super.create_element(self)
    self._element.class = "ElementExecuteWithCode"
end

function EditorExecuteWithCode:_build_panel()
	self:_create_panel()
    self:StringCtrl("code", {min = 0, help = "The code that should run for this element and in the end supposed to return a bool that determines whether this element should execute, you should copy paste your code."})
end