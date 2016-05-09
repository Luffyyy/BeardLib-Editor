EditorFakeAssaultState = EditorFakeAssaultState or class(MissionScriptEditor)
function EditorFakeAssaultState:init(unit)
	EditorFakeAssaultState.super.init(self, unit)
end

function EditorFakeAssaultState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFakeAssaultState"
    self._element.values.state = false
end

function EditorFakeAssaultState:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("state", "", "Fake assault state")
	self:add_help_text("Sets if fake assault state should be turned on or off.")
end
