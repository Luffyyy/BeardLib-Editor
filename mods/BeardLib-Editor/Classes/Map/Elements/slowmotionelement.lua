EditorSlowMotion = EditorSlowMotion or class(MissionScriptEditor)
function EditorSlowMotion:_build_panel()
    self._element.class = "ElementSlowMotion"
    self._element.values.eff_name = ""
end

function EditorSlowMotion:_build_panel()
	self:_create_panel()
	self:ComboCtrl("eff_name", table.map_keys(tweak_data.timespeed.mission_effects), {help = "Choose effect for slow motion"})
end
