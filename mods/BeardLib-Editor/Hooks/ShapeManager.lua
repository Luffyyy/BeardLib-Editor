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

function Shape:update_size(menu, item)
	self:set_property(item.name, item:Value())
end

function ShapeBox:create_panel(clss, group)
	clss:ShapeControls(callback(self, self, "update_size"), {group = group}, "", self._properties, true)
end