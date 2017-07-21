core:import("CoreShapeManager")
EditorShape = EditorShape or class(MissionScriptEditor)
function EditorShape:create_element()
	EditorShape.super.create_element(self)
	self._timeline_color = Vector3(1, 1, 0)
	self._brush = Draw:brush()
	self._element.class = "ElementShape"
	self._element.values.trigger_times = 0
	self._element.values.shape_type = "box"
	self._element.values.width = 500
	self._element.values.depth = 500
	self._element.values.height = 500
	self._element.values.radius = 250
end

function EditorShape:update(t, dt, selected_unit, all_units)
	local shape = self:get_shape()
	if shape then
		shape:draw(t, dt, 1, 1, 1)
	end
	self._shape:set_position(self._element.values.position)
	self._cylinder_shape:set_position(self._element.values.position)	
	self._shape:set_rotation(self._element.values.rotation)
	self._cylinder_shape:set_rotation(self._element.values.rotation)
end

function EditorShape:get_shape()
	if not self._shape then
		self:create_shapes()
	end
	return self._element.values.shape_type == "box" and self._shape or self._element.values.shape_type == "cylinder" and self._cylinder_shape
end

function EditorShape:create_shapes()
	self._shape = CoreShapeManager.ShapeBoxMiddle:new({position = self._element.values.position, rotation = self._element.values.rotation, width = self._element.values.width, depth = self._element.values.depth, height = self._element.values.height})
	self._cylinder_shape = CoreShapeManager.ShapeCylinderMiddle:new({position = self._element.values.position, rotation = self._element.values.rotation, radius = self._element.values.radius, height = self._element.values.height})	
end

function EditorShape:destroy()
	if self._shape then
		self._shape:destroy()
	end
	if self._cylinder_shape then
		self._cylinder_shape:destroy()
	end
end

function EditorShape:set_element_data(params, ...)
	EditorShape.super.set_element_data(self, params, ...)
	if params.value == "shape_type" then
		EditorAreaTrigger.set_shape_type(self)
	end
end

function EditorShape:_build_panel()
	self:_create_panel()
	self._shape_type = self:ComboCtrl("shape_type", {"box", "cylinder"}, {help = "Select shape for area"})
	if not self._shape then
		self:create_shapes()
	end
	self._width = self:NumberCtrl("width", {floats = 0, min = 0, callback = callback(self, EditorAreaTrigger, "set_shape_property"), text = "Width[cm]:", help ="Set the width for the shape"})
	self._depth = self:NumberCtrl("depth", {floats = 0, min = 0, callback = callback(self, EditorAreaTrigger, "set_shape_property"), text = "Depth[cm]:", help ="Set the depth for the shape"})
	self._height = self:NumberCtrl("height", {floats = 0, min = 0, callback = callback(self, EditorAreaTrigger, "set_shape_property"), text = "Height[cm]:", help ="Set the height for the shape"})
	self._radius = self:NumberCtrl("radius", {floats = 0, min = 0, callback = callback(self, EditorAreaTrigger, "set_shape_property"), text = "Radius[cm]:", help ="Set the radius for the shape"})

	EditorAreaTrigger.set_shape_type(self)
end