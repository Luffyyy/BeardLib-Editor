EditorVariableGet = EditorVariableGet or class(MissionScriptEditor)
EditorVariableGet.SAVE_UNIT_POSITION = false
EditorVariableGet.SAVE_UNIT_ROTATION = false
function EditorVariableGet:create_element(...)
	EditorVariableGet.super.create_element(self, ...)
	self._element.class = "ElementVariableGet"
	self._element.values.elements = {}
	self._element.values.variable = ""
	self._element.values.activated = true
end

function EditorVariableGet:_build_panel()
	self:_create_panel()
	self:StringCtrl("variable", {help = "Name of the variable to be used."})
	self:BooleanCtrl("activated", {help = "Set if the variable is active and uncheck if the variable is disabled."})
end

EditorVariableSet = EditorVariableSet or class(EditorVariableGet)
function EditorVariableSet:create_element(...)
	EditorVariableSet.super.create_element(self, ...)
	self._element.class = "ElementVariableSet"
end
