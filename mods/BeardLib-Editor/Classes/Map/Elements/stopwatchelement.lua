EditorStopwatch = EditorStopwatch or class(MissionScriptEditor)
function EditorStopwatch:work(...)
	self._draw = {key = "digital_gui_unit_ids"}
	self:add_draw_units(self._draw)
	EditorStopwatch.super.work(self, ...)
end

function EditorStopwatch:create_element()
	EditorStopwatch.super.create_element(self)
	self._element.class = "ElementStopwatch"
	self._element.values.timer = {0, 0}
	self._element.values.digital_gui_unit_ids = {}
end

function EditorStopwatch:check_unit(unit)
	return unit:digital_gui() and unit:digital_gui():is_timer()
end

function EditorStopwatch:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("digital_gui_unit_ids", nil, self._draw.update_units, {text = "Digital GUI Units", check_unit = callback(self, self, "check_unit")})
	self:Text("Creates a Stopwatch element. Continuously counts up once started until stopped or paused. Can be operated on using the StopwatchOperator element. Can be displayed on a digital gui.")
end

EditorStopwatchOperator = EditorStopwatchOperator or class(MissionScriptEditor)
EditorStopwatchOperator.RANDOMS = {"time"}
EditorStopwatchOperator.LINK_ELEMENTS = {"elements"}
function EditorStopwatchOperator:create_element(...)
	EditorStopwatchOperator.super.create_element(self, ...)
	self._element.class = "ElementStopwatchOperator"
	self._element.values.operation = "none"
	self._element.values.save_key = ""
	self._element.values.condition = "always"
	self._element.values.time = {0, 0}
	self._element.values.elements = {}
end

function EditorStopwatchOperator:set_element_data(...)
	EditorStopwatchOperator.super.set_element_data(self, ...)
	self._value_time:SetEnabled(false)
	self._combo_save_condition:SetEnabled(false)
	self._text_save_key:SetEnabled(false)
	local value = self._combo_operation:SelectedItem()
	if value == "none" then
		self._help_text:SetValue(self._default_help_text)
	elseif value == "pause" then
		self._help_text:SetValue(self._default_help_text .. "Pauses the Stopwatch.")
	elseif value == "start" then
		self._help_text:SetValue(self._default_help_text .. "Starts the Stopwatch counting up.")
	elseif value == "add_time" then
		self._help_text:SetValue(self._default_help_text .. "Adds the time (+random) to the Stopwatch's running time.")
		self._value_time:SetEnabled(true)
	elseif value == "subtract_time" then
		self._help_text:SetValue(self._default_help_text .. "Subtracts the time (+random) from the Stopwatch's running time.")
		self._value_time:SetEnabled(true)
	elseif value == "reset" then
		self._help_text:SetValue(self._default_help_text .. "Resets the Stopwatch to 0 seconds.")
	elseif value == "set_time" then
		self._help_text:SetValue(self._default_help_text .. "Sets the Stopwatch's running time to time (+random).")
		self._value_time:SetEnabled(true)
	elseif value == "save_time" then
		self._help_text:SetValue(self._default_help_text .. [[
Saves the running time of the Stopwatch to a mission value defined in 'Save/Load Key.'
The time will only be saved if it's operator is always or equal to/less than/greater than the saved value (if a saved value exists).]])
		self._combo_save_condition:SetEnabled(true)
		self._text_save_key:SetEnabled(true)
	elseif value == "load_time" then
		self._help_text:SetValue(self._default_help_text .. "Loads the Stopwatch time from the mission value defined in 'Save/Load Key.' The time will not be changed if no time was loaded.")
		self._text_save_key:SetEnabled(true)
	end
end

function EditorStopwatchOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementStopwatch"})
	self._combo_operation = self:ComboCtrl("operation", {"none", "pause","start","add_time", "subtract_time", "reset", "set_time", "save_time", "load_time"}, {
		help = "Select an operation for the selected elements"
	})
	self._value_time = self:NumberCtrl("time", {floats = 1, min = 0, help = "Amount of time to add, subtract or set to the Stopwatch. Used as the default time if can not load the Stopwatch."})
	self:Text("Save/Load Key:")
	self._text_save_key = self:StringCtrl("save_key")
	self._combo_save_condition = self:ComboCtrl("condition", {"always", "equal", "less_than", "greater_than", "less_or_equal", "greater_or_equal"}, {
		help ="Select a condition for which the Stopwatch value will be saved if a value for the Stopwatch is already saved. eg. save if less than the saved value.", text = "Save Condition"
	})
	self._default_help_text = "This element can modify stopwatch elements. Select Stopwatch to modify by inserting it."
	self._help_text = self:Text(self._default_help_text)
	self:set_element_data({})
end

EditorStopwatchTrigger = EditorStopwatchTrigger or class(MissionScriptEditor)
EditorStopwatchTrigger.LINK_ELEMENTS = {"elements"}
function EditorStopwatchTrigger:create_element()
	EditorStopwatchTrigger.super.create_element(self)
	self._element.class = "ElementStopwatchTrigger"
	self._element.values.time = 0
	self._element.values.elements = {}
end

function EditorStopwatchTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementStopwatch"})
	self:NumberCtrl("time", {floats = 1, min = 0, help = "Specify at what time on the Stopwatch this should trigger."})
	self:Text("This element is a trigger to stopwatch elements.")
end

EditorStopwatchFilter = EditorStopwatchFilter or class(MissionScriptEditor)
EditorStopwatchFilter.SAVE_UNIT_POSITION = false
EditorStopwatchFilter.SAVE_UNIT_ROTATION = false
EditorStopwatchFilter.LINK_ELEMENTS = {"elements"}
function EditorStopwatchFilter:create_element()
	EditorStopwatchFilter.super.create_element(self)
	self._element.class = "ElementStopwatchFilter"
	self._element.values.needed_to_execute = "all"
	self._element.values.value = 0
	self._element.values.Stopwatch_value_ids = {}
	self._element.values.elements = {}
	self._element.values.check_type = "equal"
end

function EditorStopwatchFilter:draw_links(...)
	EditorStopwatchFilter.super.draw_links(self, ...)
	self:draw_elements(self._element.values.Stopwatch_value_ids)
end

function EditorStopwatchFilter:set_Stopwatch_value()
	self._value_ctrl:SetEnabled(self._element.values.Stopwatch_value_ids[1] == nil)
end

function EditorStopwatchFilter:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementCounter"})
	self:ComboCtrl("needed_to_execute", {"all", "any"}, {help = "Select how many counter elements are needed to execute"})
	self._value_ctrl = self:NumberCtrl("value", {help = "Specify value to trigger on.", enabled = self._element.values.Stopwatch_value_ids[1] == nil})
	self:BuildElementsManage("Stopwatch_value_ids", nil, {"ElementStopwatch"}, callback(self, self, "set_Stopwatch_value"), {
		single_select = true,
		text = "Stopwatch Element as value",
		help = "Select a Stopwatch element as the value of this filter element"
	})
	self:ComboCtrl("check_type", {"equal", "less_than", "greater_than", "less_or_equal", "greater_or_equal"}, {help = "Select which check operation to perform"})
	self:Text("This element is a filter to stopwatchs element.")
end