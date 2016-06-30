core:import("CoreEngineAccess")
EditorPlayEffect = EditorPlayEffect or class(MissionScriptEditor)
EditorPlayEffect.USES_POINT_ORIENTATION = true
function EditorPlayEffect:create_element()
	self.super.create_element(self)
	self._element.values.class = "ElementPlayEffect"
	self._element.values.effect = "none"
	self._element.values.screen_space = false
	self._element.values.base_time = 0
	self._element.values.random_time = 0
	self._element.values.max_amount = 0
end
function EditorPlayEffect:_effect_options()
	local effect_options = {"none"}
	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		table.insert(effect_options, name)
	end
	return effect_options
end
function EditorPlayEffect:_build_panel(panel, panel_sizer)
	self:_create_panel()
	self:_build_value_checkbox("screen_space", "Play in Screen Space")
	self:_build_value_combobox("effect", self:_effect_options(), "Select and effect from the combobox")
	self:_build_value_number("base_time", {floats = 2, min = 0}, "This is the minimum time to wait before spawning next effect")
	self:_build_value_number("random_time", {floats = 2, min = 0}, "Random time is added to minimum time to give the time between effect spawns")
	self:_build_value_number("max_amount", {floats = 0, min = 0}, "Maximum amount of spawns when repeating effects (0 = unlimited)")
	self:add_help_text([[
Choose an effect from the combobox. Use "Play in Screen Space" if the effect is set up to be played like that. 

Use base time and random time if you want to repeat playing the effect, keep them at 0 to only play it once. "Base Time" is the minimum time between effects. "Random Time" is added to base time to set the total time until next effect. "Max Amount" can be used to set how many times the effect should be repeated (when base time and random time are used). 

Be sure not to use a looping effect when using repeat or the effects will add to each other and wont be stoppable after run simulation or by calling kill or fade kill.]])
end

EditorStopEffect = EditorStopEffect or class(MissionScriptEditor)
function EditorStopEffect:create_element()
	self.super.create_element(self)
	self._element.values.operation = "fade_kill"
	self._element.values.elements = {}
end

function EditorStopEffect:_build_panel(panel, panel_sizer)
	self:_create_panel()
	self:_build_element_list("elements", {"ElementPlayEffect"})
	self:_build_value_combobox("operation", {"kill", "fade_kill"}, "Select a kind of operation to perform on the added effects")
end
