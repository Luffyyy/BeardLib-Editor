EditorFeedback = EditorFeedback or class(MissionScriptEditor)
EditorFeedback.USES_POINT_ORIENTATION = true
function EditorFeedback:init(element)
	EditorFeedback.super.init(self, element)
end
 
function EditorFeedback:create_element()
	self.super.create_element(self)
	self._element.class = "ElementEditorFeedback"
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
	self:_build_value_number("range", {min = -1}, "The range the effect should be felt. 0 means that it will be felt everywhere")
	self:_build_value_checkbox(camera_shaker_sizer, "use_camera_shake", "Use camera shake")
	self:_build_value_combobox(camera_shaker_sizer, "camera_shake_effect", {
		"mission_triggered",
		"headbob",
		"player_land",
		"breathing"
	}, "Select a camera shake effect", "effect")
	self:_build_value_number("camera_shake_amplitude", {min = -1}, "Amplitude basically decides the strenght of the shake", "amplitude")
	self:_build_value_number("camera_shake_frequency", {min = -1}, "Changes the frequency of the shake", "frequency")
	self:_build_value_number("camera_shake_attack", {min = -1}, "Time to reach maximum shake", "attack")
	self:_build_value_number("camera_shake_sustain", {min = -1}, "Time to sustain maximum shake", "sustain")
	self:_build_value_number("camera_shake_decay", {min = -1}, "Time to decay from maximum shake to zero", "decay")
	self:_build_value_checkbox("use_rumble", "Use rumble")
	self:_build_value_number("rumble_peak", {min = -1}, "A value to determine the strength of the rumble", "peak")
	self:_build_value_number("rumble_attack", {min = -1}, "Time to reach maximum rumble", "attack")
	self:_build_value_number("rumble_sustain", {min = -1}, "Time to sustain maximum rumble", "sustain")
	self:_build_value_number("rumble_release", {min = -1}, "Time to decay from maximum rumble to zero", "release")
	self:_build_value_combobox("above_camera_effect", table.list_add({"none"}, self:_effect_options()), "Select and above camera effect", "effect")
	self:_build_value_number("above_camera_effect_distance", {
		min = 0,
		max = 1
	}, "A filter value to use with the range. A value of 1 means that the effect will be played whenever inside the range, a lower value means you need to be closer to the position.", "distance filter")
end
function EditorFeedback:_effect_options()
	local effect_options = {}
	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		table.insert(effect_options, name)
	end
	return effect_options
end
