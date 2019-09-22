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
	if not alive(self._unit) then
		return
	end
	local shape = EditorAreaTrigger.get_shape(self)
	if shape then
		shape:draw(t, dt, 1, 1, 1)
	end
	EditorAreaTrigger.update_shape_position(self)
	EditorShape.super.update(self, t, dt)
end

EditorShape.destroy = EditorAreaTrigger.destroy 

function EditorShape:set_element_data(params, ...)
	EditorShape.super.set_element_data(self, params, ...)
	if params.name == "shape_type" then
		EditorAreaTrigger.set_shape_type(self)
	end
end

function EditorShape:_build_panel()
	self:_create_panel()
	self._shape_type = self:ComboCtrl("shape_type", {"box", "cylinder", "sphere"}, {help = "Select shape for area"})
	if not self._shape then
		EditorAreaTrigger.create_shapes(self)
	end
	self._width = self:NumberCtrl("width", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Width[cm]:", help ="Set the width for the shape"})
	self._depth = self:NumberCtrl("depth", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Depth[cm]:", help ="Set the depth for the shape"})
	self._height = self:NumberCtrl("height", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Height[cm]:", help ="Set the height for the shape"})
	self._radius = self:NumberCtrl("radius", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Radius[cm]:", help ="Set the radius for the shape"})

	EditorAreaTrigger.set_shape_type(self)
end