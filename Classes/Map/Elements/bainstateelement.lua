EditorBainState = EditorBainState or class(MissionScriptEditor)
function EditorBainState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementBainState"
    self._element.values.state = true
end
function EditorBainState:_build_panel()
	self:_create_panel()
    self:BooleanCtrl("state", {help = "Sets if bain should speak or not.", text = "Should bain speak"})
end
