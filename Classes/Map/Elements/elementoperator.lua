EditorOperator = EditorOperator or class(MissionScriptEditor)
function EditorOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementOperator"
	self._element.values.operation = "none"
	self._element.values.elements = {}
end

function EditorOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements")
	self:ComboCtrl("operation", {"none","add","remove"}, {help = "Select an operation for the selected elements"})
	self:Text("Choose an operation to perform on the selected elements. An element might not have the selected operation implemented and will then generate error when executed.")
end