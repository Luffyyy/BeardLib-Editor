EditorFeedback = EditorFeedback or class(MissionScriptEditor)
EditorFeedback.USES_POINT_ORIENTATION = true
function EditorFeedback:create_element()
	EditorFeedback.super.create_element(self)
	self._element.class = "ElementFeedback"
	self._element.values.effect = "mission_triggered"
	self._element.values.range = 0
	self._element.values.use_camera_shake = true
	self._element.values.use_rumble = true
	self._element.values.camera_shake_effect = "mission_triggered"
	self._element.values.camera_shake_amplitude = 1
	self._element.values.camera_shake_frequency = 1
	self._element.values.camera_shake_attack = 0.1
	self._element.values.camera_shake_sustain = 0.3
	self._element.values.camera_shake_decay = 2.1
	self._element.values.rumble_peak = 1
	self._element.values.rumble_attack = 0.1
	self._element.values.rumble_sustain = 0.3
	self._element.values.rumble_release = 2.1
	self._element.values.above_camera_effect = "none"
	self._element.values.above_camera_effect_distance = 0.5 
end

function EditorFeedback:_build_panel()
	self:_create_panel()
	self:NumberCtrl("range", {min = -1, help = "The range the effect should be felt. 0 means that it will be felt everywhere"})
	self:BooleanCtrl("use_camera_shake")
	self:ComboCtrl("camera_shake_effect", {"mission_triggered","headbob","player_land","breathing"}, {help = "Select a camera shake effect", "effect"})
	self:NumberCtrl("camera_shake_amplitude", {min = -1, help = "Amplitude basically decides the strenght of the shake", text = "amplitude"})
	self:NumberCtrl("camera_shake_frequency", {min = -1, help = "Changes the frequency of the shake", text = "frequency"})
	self:NumberCtrl("camera_shake_attack", {min = -1, help = "Time to reach maximum shake", text = "attack"})
	self:NumberCtrl("camera_shake_sustain", {min = -1, help = "Time to sustain maximum shake", text = "sustain"})
	self:NumberCtrl("camera_shake_decay", {min = -1, help = "Time to decay from maximum shake to zero", text = "decay"})
	self:BooleanCtrl("use_rumble")
	self:NumberCtrl("rumble_peak", {min = -1, help = "A value to determine the strength of the rumble", text = "peak"})
	self:NumberCtrl("rumble_attack", {min = -1, help = "Time to reach maximum rumble", text = "attack"})
	self:NumberCtrl("rumble_sustain", {min = -1, help = "Time to sustain maximum rumble", text = "sustain"})
	self:NumberCtrl("rumble_release", {min = -1, help = "Time to decay from maximum rumble to zero", text = "release"})
	self:ComboCtrl("above_camera_effect", table.list_add({"none"}, self:_effect_options()), {help = "Select and above camera effect", text = "effect"})
	self:NumberCtrl("above_camera_effect_distance", {
		min = 0,
		max = 1,
		help = "A filter value to use with the range. A value of 1 means that the effect will be played whenever inside the range, a lower value means you need to be closer to the position.", 
		text = "distance filter"
	})
end

function EditorFeedback:_effect_options()
	return BeardLibEditor.Utils:GetEntries({type = "effect", loaded = true})
end