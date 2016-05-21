EditorDropinState = EditorDropinState or class(MissionScriptEditor)
function EditorDropinState:init(unit)
	EditorDropinState.super.init(self, unit)	
end
function EditorDropinState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDropinState" 
    self._element.values.state = true 
end
function EditorDropinState:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("state", "Sets if drop in should be turned on or off.", nil, "Dropin enabled")
	self:add_help_text(help)
end
