EditorOverlayEffect = EditorOverlayEffect or class(MissionScriptEditor)
function EditorOverlayEffect:create_element()
	self.super.create_element(self)
	self._element.class = "ElementOverlayEffect" 
	self._element.values.effect = "none"
end

function EditorOverlayEffect:_build_panel()
	self:_create_panel()
	local options = {}
	for name, _ in pairs(managers.overlay_effect:presets()) do 
		table.insert(options, name)
	end
	self:ComboCtrl("effect", options, {help = "Select a preset effect for the combo box"})
	self:NumberCtrl("fade_in")
	self:NumberCtrl("fade_out")
	self:NumberCtrl("sustain")
end
