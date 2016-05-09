EditorSlowMotion = EditorSlowMotion or class(MissionScriptEditor)
EditorSlowMotion.SAVE_UNIT_POSITION = false
EditorSlowMotion.SAVE_UNIT_ROTATION = false
function EditorSlowMotion:init(unit)
	EditorSlowMotion.super.init(self, unit)
end
function EditorSlowMotion:_build_panel()
    self._element.class = "ElementSlowMotion"
    self._element.values.eff_name = ""
end
function EditorSlowMotion:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("eff_name", table.map_keys(tweak_data.timespeed.mission_effects), "Choose effect. Descriptions in lib/TimeSpeedEffectTweakData.lua")
	self:add_help_text("Choose effect. Descriptions in lib/TimeSpeedEffectTweakData.lua.")
end
