EditorEnvironmentOperator = EditorEnvironmentOperator or class(MissionScriptEditor)
EditorEnvironmentOperator.ACTIONS = {"set"}
function EditorEnvironmentOperator:init(unit)
	EditorEnvironmentOperator.super.init(self, unit)
	self._actions = EditorEnvironmentOperator.ACTIONS
end
function EditorEnvironmentOperator:create_element()
    self.super.create_element(self)
    self._element.class = "ElementEnvironmentOperator"
    self._element.values.operation = "set"
    self._element.values.environment = ""
    self._element.values.elements = {} 
end
function EditorEnvironmentOperator:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("operation", self._actions, "Select an operation for the selected elements")
	self:_build_value_combobox("environment", managers.database:list_entries_of_type("environment"), "Select an environment to use")
end
