EditorEnvironmentOperator = EditorEnvironmentOperator or class(MissionScriptEditor)
EditorEnvironmentOperator.ELEMENT_FILTER = {}
EditorEnvironmentOperator.ACTIONS = {
	"set",
	"enable_global_override",
	"disable_global_override"
}

function EditorEnvironmentOperator:create_element(unit)
	EditorEnvironmentOperator.super.create_element(self, unit)

	self._element.class = "ElementEnvironmentOperator"
	self._element.values.operation = "set"
	self._element.values.environment = ""
	self._element.values.blend_time = 0
	self._element.values.elements = {}
end

function EditorEnvironmentOperator:clear(...)
	Application:trace("EditorEnvironmentOperator:clear !!!!!!!!!!!!!!!!!!!   ", self._old_default_environment)
end

function EditorEnvironmentOperator:_build_panel()
	self:_create_panel()

	self:ComboCtrl("operation", EditorEnvironmentOperator.ACTIONS, {
		help = "Select an operation for the selected elements"
	})
	self:PathCtrl("environment", "environment")
	self:NumberCtrl("blend_time", {
		floats = 2,
		min = 0
	}, {help = "How long this environment should blend in over"})
end
