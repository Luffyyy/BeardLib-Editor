EditorDropinState = EditorDropinState or class(MissionScriptEditor)
function EditorDropinState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDropinState" 
    self._element.values.state = true 
end
function EditorDropinState:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("state", {help = "Sets if drop in should be turned on or off.", text = "Dropin enabled"})
end
