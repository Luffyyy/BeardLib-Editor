EditorBlurZone = EditorBlurZone or class(MissionScriptEditor)
function EditorBlurZone:init(unit)
	EditorBlurZone.super.init(self, unit)
end
function EditorBlurZone:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBlurZone"
	self._element.values.mode = 0
	self._element.values.radius = 200
	self._element.values.height = 200 
end
function EditorBlurZone:update_selected(t, dt, selected_unit, all_units) -- 
	local brush = Draw:brush()
	brush:set_color(Color(0.15, 1, 1, 1))
	local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
	brush:cylinder(self._unit:position(), self._unit:position() + math.Z * self._element.values.height, self._element.values.radius)
	pen:cylinder(self._unit:position(), self._unit:position() + math.Z * self._element.values.height, self._element.values.radius)
	brush:half_sphere(self._unit:position(), self._element.values.radius, math.Z, 2)
	pen:half_sphere(self._unit:position(), self._element.values.radius, math.Z)
	brush:half_sphere(self._unit:position() + math.Z * self._element.values.height, self._element.values.radius, -math.Z, 2)
	pen:half_sphere(self._unit:position() + math.Z * self._element.values.height, self._element.values.radius, -math.Z)
end
function EditorBlurZone:_build_panel()
	self:_create_panel()
	self:_build_value_number("mode", {min = 0, max = 2}, "Set the mode, 0 is disable, 2 is flash, 1 is normal")
	self:_build_value_number("radius", {min = 1}, "Set the radius")
	self:_build_value_number("height", {min = 0}, "Set the height")
end
