EditorWhisperState = EditorWhisperState or class(MissionScriptEditor)
function EditorWhisperState:init(unit)
	EditorWhisperState.super.init(self, unit)
end
function EditorWhisperState:create_element()
    self.super.create_element(self)
    self._element.class = "ElementWhisperState"
    self._element.values.state = false
end
function EditorWhisperState:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("state", "Sets if whisper state should be turned on or off.", nil, "Whisper State")
end
