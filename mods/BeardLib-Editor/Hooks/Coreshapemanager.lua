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
 