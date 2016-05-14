EditorToggle = EditorToggle or class(MissionScriptEditor)
EditorToggle.SAVE_UNIT_POSITION = false
EditorToggle.SAVE_UNIT_ROTATION = false
function EditorToggle:create_element()
	self.super.create_element(self)
	self._element.class = "ElementToggle"
	self._element.values.toggle = "on"
	self._element.values.set_trigger_times = -1
	self._element.values.elements = {}
end

function EditorToggle:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements")
	self:_build_value_combobox("toggle", {
		"on",
		"off",
		"toggle"
	}, "Select how you want to toggle an element")
	self:_build_value_number("set_trigger_times", {floats = 0, min = -1}, "Sets the elements trigger times when toggle on (-1 means do not use)")
end

