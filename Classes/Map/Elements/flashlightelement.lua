EditorFlashlight = EditorFlashlight or class(MissionScriptEditor)
function EditorFlashlight:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFlashlight"
    self._element.values.state = false
    self._element.values.on_player = false 
end

function EditorFlashlight:_build_panel()
	self:_create_panel()
    self:BooleanCtrl("state", {text = "Flashlight state"})
    self:BooleanCtrl("on_player", {text = "Include player"})
	self:Text("Sets if flashlights should be turned on or off.")
end
