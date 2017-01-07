EditorFadeToBlack = EditorFadeToBlack or class(MissionScriptEditor)
function EditorFadeToBlack:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFadeToBlack"
    self._element.values.state = false
end

function EditorFadeToBlack:_build_panel()
	self:_create_panel()
    self:BooleanCtrl("state", {text = "Fade in/out"})
	self:Text("Fade in or out, takes 3 seconds. Hardcore.")
end
