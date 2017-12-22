EditorCounter = EditorCounter or class(MissionScriptEditor)
EditorCounter.SAVE_UNIT_POSITION = false
EditorCounter.SAVE_UNIT_ROTATION = false
EditorCounter.INSTANCE_VAR_NAMES = {{type = "number", value = "counter_target"}}
function EditorCounter:work(...)
	self._draw = {key = "digital_gui_unit_ids"}
	self:add_draw_units(self._draw)
	EditorCounter.super.work(self, ...)
end

function EditorCounter:create_element()
	EditorCounter.super.create_element(self)
	self._element.class = "ElementCounter"
	self._element.module = "CoreElementCounter"
	self._element.values.counter_target = 0
	self._element.values.digital_gui_unit_ids = {}
end

function EditorCounter:check_unit(unit)
	return unit:digital_gui() and unit:digital_gui():is_timer()
end

function EditorCounter:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("digital_gui_unit_ids", nil, self._draw.update_units, {text = "Timer Units", check_unit = callback(self, self, "check_unit")})
	self:NumberCtrl("counter_target", {floats = 0, min = 0, help = "Specifies how many times the counter should be executed before running its on executed"})
	self:Text("Units with number gui extension can have their value updated from a counter.")
end

EditorCounterOperator = EditorCounterOperator or class(MissionScriptEditor)
EditorCounterOperator.SAVE_UNIT_POSITION = false
EditorCounterOperator.SAVE_UNIT_ROTATION = false
EditorCounterOperator.INSTANCE_VAR_NAMES = {
	{type = "number", value = "amount"}
}
EditorCounterOperator.LINK_ELEMENTS = {"elements"}
CounterOperatorUnitElement = CounterOperatorUnitElement or class(EditorCounterOperator)
function EditorCounterOperator:create_element()
	EditorCounterOperator.super.create_element(self)
	self._element.class = "ElementCounterOperator"
	self._element.module = "CoreElementCounter"
	self._element.values.operation = "none"
	self._element.values.amount = 0
	self._element.values.elements = {}
end

function EditorCounterOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementCounter"})
	self:ComboCtrl("operation", {"none", "add", "subtract", "reset", "set"}, {help = "Select an operation for the selected elements"})
	self:NumberCtrl("amount", {floats = 0, min = 0, help = "Amount to add, subtract or set to the counters."})
	self:Text("This element can modify counter elements. Select counters to modify using insert and clicking on the elements.")
end

EditorCounterTrigger = EditorCounterTrigger or class(MissionScriptEditor)
EditorCounterTrigger.SAVE_UNIT_POSITION = false
EditorCounterTrigger.SAVE_UNIT_ROTATION = false
EditorCounterTrigger.LINK_ELEMENTS = {"elements"}
CounterTriggerUnitElement = CounterTriggerUnitElement or class(EditorCounterTrigger)
function EditorCounterTrigger:create_element()
	EditorCounterTrigger.super.create_element(self)
	self._element.class = "ElementCounterTrigger"
	self._element.module = "CoreElementCounter"
	self._element.values.trigger_type = "value"
	self._element.values.amount = 0
	self._element.values.elements = {}
end

function EditorCounterTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementCounter"})
	self:ComboCtrl("trigger_type", {"none", "value", "add", "subtract", "reset", "set"}, {help = "Select a trigger type for the selected elements"})
	self:NumberCtrl("amount", {floats = 0, help = "Specify value to trigger on."})
	self:Text("This element is a trigger to counter elements.")
end

EditorCounterFilter = EditorCounterFilter or class(MissionScriptEditor)
EditorCounterFilter.SAVE_UNIT_POSITION = false
EditorCounterFilter.SAVE_UNIT_ROTATION = false
EditorCounterFilter.LINK_ELEMENTS = {"elements"}
CounterFilterUnitElement = CounterFilterUnitElement or class(EditorCounterFilter)
function EditorCounterFilter:create_element()
	EditorCounterFilter.super.create_element(self)
	self._element.class = "ElementCounterFilter"
	self._element.module = "CoreElementCounter"
	self._element.values.needed_to_execute = "all"
	self._element.values.value = 0
	self._element.values.elements = {}
	self._element.values.check_type = "equal"
end

function EditorCounterFilter:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementCounter"})
	self:ComboCtrl("needed_to_execute", {"all", "any"}, {help = "Select how many elements are needed to execute"})
	self:NumberCtrl("value", {floats = 0, help = "Specify value to trigger on."})
	self:ComboCtrl("check_type", {"equal", "less_than", "greater_than", "less_or_equal", "greater_or_equal", "counters_equal", "counters_not_equal"},{
		help = "Select which check operation to perform"
	})
	self:Text("This element is a filter to counter elements.")
end