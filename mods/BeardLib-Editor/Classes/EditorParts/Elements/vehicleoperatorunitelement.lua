EditorVehicleOperator = EditorVehicleOperator or class(MissionScriptEditor)
function EditorVehicleOperator:create_element() --Purpose of the element? 
	self.super.create_element(self)
	self._element.class = "ElementVehicleOperator"
	self._element.values.operation = "none"
	self._element.values.damage = "0"
	self._element.values.elements = {}
end

function EditorVehicleOperator:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements")
	self:_build_value_combobox("operation",  {"none","lock","unlock","secure","break_down","repair","damage","activate","deactivate","block"}, "Select an operation for the selected elements")
	self:_build_value_number("damage", {floats = 0, min = 1}, "Specify the amount of damage.")

	self:_add_help_text("Choose an operation to perform on the selected elements. An element might not have the selected operation implemented and will then generate error when executed.")
end
