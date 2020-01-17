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

function EditorOverlayEffect:test_element()
    if self._element.values.effect ~= 'none' then
        local effect = clone(managers.overlay_effect:presets()[self._element.values.effect])
        effect.sustain = self._element.values.sustain or effect.sustain
        effect.fade_in = self._element.values.fade_in or effect.fade_in
        effect.fade_out = self._element.values.fade_out or effect.fade_out

        managers.overlay_effect:play_effect(effect)
    end
end

function EditorOverlayEffect:stop_test_element()
    managers.overlay_effect:stop_effect()
end
