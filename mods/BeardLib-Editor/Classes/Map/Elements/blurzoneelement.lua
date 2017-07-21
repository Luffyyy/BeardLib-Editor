EditorBlurZone = EditorBlurZone or class(MissionScriptEditor)
function EditorBlurZone:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBlurZone"
	self._element.values.mode = 0
	self._element.values.radius = 200
	self._element.values.height = 200 
end

function EditorBlurZone:update(t, dt) 
	local brush = Draw:brush()
	brush:set_color(Color(0.15, 1, 1, 1))
	local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
	brush:cylinder(self._element.values.position, self._element.values.position + math.Z * self._element.values.height, self._element.values.radius)
	pen:cylinder(self._element.values.position, self._element.values.position + math.Z * self._element.values.height, self._element.values.radius)
	brush:half_sphere(self._element.values.position, self._element.values.radius, math.Z, 2)
	pen:half_sphere(self._element.values.position, self._element.values.radius, math.Z)
	brush:half_sphere(self._element.values.position + math.Z * self._element.values.height, self._element.values.radius, -math.Z, 2)
	pen:half_sphere(self._element.values.position + math.Z * self._element.values.height, self._element.values.radius, -math.Z)
end

function EditorBlurZone:_build_panel()
	self:_create_panel()
	self:NumberCtrl("mode", {min = 0, max = 2}, {help = "Set the mode, 0 is disable, 2 is flash, 1 is normal"})
	self:NumberCtrl("radius", {min = 1}, {help = "Set the radius"})
	self:NumberCtrl("height", {min = 0}, {help = "Set the height"})
end
