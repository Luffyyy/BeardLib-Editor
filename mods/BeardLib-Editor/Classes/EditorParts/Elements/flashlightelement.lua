EditorFlashlight = EditorFlashlight or class(MissionScriptEditor)
function EditorFlashlight:init(unit)
	EditorFlashlight.super.init(self, unit)
end

function EditorFlashlight:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFlashlight"
    self._element.values.state = false
    self._element.values.on_player = false 
end

function EditorFlashlight:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("state", "", "Flashlight state")
	self:_build_value_checkbox("on_player", "", "Include player")
	self:add_help_text("Sets if flashlights should be turned on or off.")
end
