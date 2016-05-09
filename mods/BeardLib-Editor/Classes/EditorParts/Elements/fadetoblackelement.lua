EditorFadeToBlack = EditorFadeToBlack or class(MissionScriptEditor)
function EditorFadeToBlack:init(unit)
	EditorFadeToBlack.super.init(self, unit)
end
function EditorFadeToBlack:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFadeToBlack"
    self._element.values.state = false
end
function EditorFadeToBlack:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("state", "", "Fade in/out")
	self:add_help_text("Fade in or out, takes 3 seconds. Hardcore.")
end
