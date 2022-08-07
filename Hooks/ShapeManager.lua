if not Global.editor_mode then
	return
end

core:module("CoreShapeManager")
core:import("CoreXml")
core:import("CoreMath")
Shape = Shape or class()
function Shape:init(params)
	self._name = params.name or ""
	self._type = params.type or "none"
	self._position = params.position or Vector3()
	self._rotation = params.rotation or Rotation()
	self._properties = {}
	if Global.editor_mode then
		self._properties_ctrls = {}
		self._min_value = 10
		self._max_value = 10000000
	end
end

function Shape:get_params()
	local params = {}
	for k, v in pairs(self) do
		if string.begins(k, "_") and not (k == "position" or k == "rotation")  then
			params[string.sub(k, 2)] = v
		end
	end
	return params
end

function Shape:create_panel() end

function Shape:update_size(item)
	local val = item:Value()
	self:set_property("width", val.width)
	self:set_property("height", val.height)
	self:set_property("depth", val.depth)
	if not item.no_radius then
		self:set_property("radius", val.radius)
	end
end

function ShapeBox:create_panel(clss, group)
	(group or clss):Shape("Shape", _G.ClassClbk(self, "update_size"), self._properties, {no_radius = true})
end

function Shape:position()
	return alive(self._unit) and self._unit:position() or self._position or Vector3()
end

function Shape:rotation()
	return alive(self._unit) and self._unit:rotation() or self._rotation or Rotation()
end