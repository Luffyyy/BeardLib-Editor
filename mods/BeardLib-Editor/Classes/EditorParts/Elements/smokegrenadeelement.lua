EditorSmokeGrenade = EditorSmokeGrenade or class(MissionScriptEditor)
function EditorSmokeGrenade:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSmokeGrenade"
	self._element.values.duration = 15
	self._element.values.immediate = false
	self._element.values.ignore_control = false
end
function EditorSmokeGrenade:_build_panel()
	self:_create_panel()
	self:_build_value_number("duration", {min = 1}, "Set the duration of the smoke grenade", nil, "Duration (sec):")
	self:_build_value_checkbox("immediate", "", nil, "Explode immediately")
	self:_build_value_checkbox("ignore_control", "", nil, "Ignore control/assault mode")
	self:_build_value_combobox("effect_type", {"smoke", "flash"}, "Select what type of effect will be spawned.")
	self:_add_help_text("Spawns a smoke grenade.")
end
