EditorPressure = EditorPressure or class(MissionScriptEditor)
function EditorPressure:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPressure"
	self._element.values.points = 0
	self._element.values.interval = 0	
end
function EditorPressure:_build_panel()
	self:_create_panel()
	self:NumberCtrl("interval", {min = 0, max = 600, help = "Use this to set the interval in seconds when to add new pressure point (0 means it is disabled)", text =  "Interval"})
	self:NumberCtrl("points", {min = -10, max = 10, help = "Can add pressure points or cool down points", text = "Pressure points"})
	self:Text("If pressure points ~= 0 the interval value wont be used. Add negative pressure points value will generate cool down points. If interval is 0 it will be disabled.")
end
