EditorLookAtTrigger = EditorLookAtTrigger or class(MissionScriptEditor)
function EditorLookAtTrigger:init(unit)
	EditorLookAtTrigger.super.init(self, unit)
end

function EditorLookAtTrigger:create_element()
	self.super.create_element(self)
	self._element.class = "ElementLookAtTrigger"
	self._element.values.trigger_times = 1
	self._element.values.interval = 0.1
	self._element.values.sensitivity = 0.9
	self._element.values.distance = 0
	self._element.values.in_front = false 
end

function EditorLookAtTrigger:update(t, dt)
	if self._element.values.distance ~= 0 then
		local brush = Draw:brush()
		brush:set_color(Color(0.15, 1, 1, 1))
		local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
		if not self._element.values.in_front then
			brush:sphere(self._element.values.position, self._element.values.distance, 4)
			pen:sphere(self._element.values.position, self._element.values.distance)
		else
			brush:half_sphere(self._element.values.position, self._element.values.distance, -self._element.values.rotation:y(), 4)
			pen:half_sphere(self._element.values.position, self._element.values.distance, -self._element.values.rotation:y())
		end
	end
end
function EditorLookAtTrigger:_build_panel()
	self:_create_panel()
	self:_build_value_number("interval", {min = 0.01}, "Set the check interval for the look at, in seconds")
	self:_build_value_number("sensitivity", {max = 0.999, min = 0.5})
	self:_build_value_number("distance", {min = 0}, "(Optional) Sets a distance to use with the check (in meters)")
	self:_build_value_checkbox("in_front", "Only in front")
	self:_add_help_text([[
		Interval defines how offen the check should be done. Sensitivity defines how precise the look angle must be. A sensitivity of 0.999 means that you need to look almost directly at it, 0.5 means that you will get the trigger somewhere at the edge of the screen (might be outside or inside). 

		Distance(in meters) can be used as a filter to the trigger (0 means no distance filtering)]]
	)
end
