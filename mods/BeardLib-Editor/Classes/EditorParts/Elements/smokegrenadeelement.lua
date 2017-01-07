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
	self:NumberCtrl("duration", {min = 1, help = "Set the duration of the smoke grenade", text = "Duration (sec)"})
	self:BooleanCtrl("immediate", {help = "Explode immediately"})
	self:BooleanCtrl("ignore_control", {help = "Ignore control/assault mode"})
	self:ComboCtrl("effect_type", {"smoke", "flash"}, {help = "Select what type of effect will be spawned."})
	self:Text("Spawns a smoke grenade.")
end
