EditorBainState = EditorBainState or class(MissionScriptEditor)
function EditorBainState:init(unit)
	EditorBainState.super.init(self, unit)
end
function EditorBainState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementBainState"
    self._element.values.state = true
end
function EditorBainState:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("state", "Sets if bain should speak or not.", "Should bain speak")
end
