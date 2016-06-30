EditorOperator = EditorOperator or class(MissionScriptEditor)
EditorOperator.SAVE_UNIT_POSITION = false
EditorOperator.SAVE_UNIT_ROTATION = false

function EditorOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementOperator"
	self._element.values.operation = "none"
	self._element.values.elements = {}
end
function EditorOperator:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements")
	self:_build_value_combobox("operation", {
		"none",
		"add",
		"remove"
	}, "Select an operation for the selected elements")
	self:_add_help_text("Choose an operation to perform on the selected elements. An element might not have the selected operation implemented and will then generate error when executed.")
end
