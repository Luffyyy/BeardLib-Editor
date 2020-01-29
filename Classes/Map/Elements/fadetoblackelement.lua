EditorFadeToBlack = EditorFadeToBlack or class(MissionScriptEditor)
function EditorFadeToBlack:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFadeToBlack"
    self._element.values.state = false
end

function EditorFadeToBlack:_build_panel()
    self:_create_panel()

    local overlay_effects = table.map_keys(tweak_data.overlay_effects, function (x, y)
		return x < y
	end)

	self:ComboCtrl("fade_in", overlay_effects, {text = "Fade in overlay effect."})
    self:ComboCtrl("fade_out", overlay_effects, {text = "Fade out overlay effect."})

    self:BooleanCtrl("state", {text = "Fade in/out"})
	self:Text("FadFade in or out, takes 3 seconds. Hardcore.\nCustom fade in/out can be added in TweakData.lua -> self.overlay_effects")
end
