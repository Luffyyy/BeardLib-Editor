EditorFakeAssaultState = EditorFakeAssaultState or class(MissionScriptEditor)
function EditorFakeAssaultState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFakeAssaultState"
    self._element.values.state = false
end

function EditorFakeAssaultState:_build_panel()
	self:_create_panel()
    self:BooleanCtrl("state", {text = "Fake assault state"})
	self:Text("Sets if fake assault state should be turned on or off.")
end
