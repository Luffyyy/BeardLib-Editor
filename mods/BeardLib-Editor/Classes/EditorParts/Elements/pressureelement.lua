EditorPressure = EditorPressure or class(MissionScriptEditor)
function EditorPressure:init(unit)
	EditorPressure.super.init(self, unit)
end
function EditorPressure:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPressure"
	self._element.values.points = 0
	self._element.values.interval = 0	
end
function EditorPressure:_build_panel()
	self:_create_panel()
	self:_build_value_number("interval", {min = 0, max = 600}, "Use this to set the interval in seconds when to add new pressure point (0 means it is disabled)", "Interval")
	self:_build_value_number("points", {min = -10, max = 10},  "Can add pressure points or cool down points", "Pressure points")

	local pressure_points_params = {
		name = "Pressure points:",
		panel = panel,
		sizer = panel_sizer,
		value = self._element.values.points,
		floats = 0,
		tooltip = "Can add pressure points or cool down points",
		min = -10,
		max = 10,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	self:add_help_text("If pressure points ~= 0 the interval value wont be used. Add negative pressure points value will generate cool down points. If interval is 0 it will be disabled.")
end
