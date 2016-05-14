EditorOverlayEffect = EditorOverlayEffect or class(MissionScriptEditor)

function EditorOverlayEffect:create_element()
	self.super.create_element(self)
	self._element.class = "ElementOverlayEffect" 
	self._element.values.effect = "none"
end

function EditorOverlayEffect:_build_panel(panel, panel_sizer)
	self:_create_panel()
	local options = {}
	for name, _ in pairs(managers.overlay_effect:presets()) do
		table.insert(options, name)
	end
	self:_build_value_combobox("effect", options, "Select a preset effect for the combo box")
	self:_build_value_number("fade_in", {})
	self:_build_value_number("fade_out", {})
	self:_build_value_number("sustain", {})
end
