EditorJobValue = EditorJobValue or class(MissionScriptEditor)
EditorJobValue.SAVE_UNIT_POSITION = false
EditorJobValue.SAVE_UNIT_ROTATION = false
function EditorJobValue:init(element)
	EditorJobValue.super.init(self, element)
end
function EditorJobValue:create_element()
    self.super.create_element(self)
	self._element.class = "ElementJobValue"
	self._element.values.key = "none"
	self._element.values.value = 0
	self._element.values.save = nil    
end
function EditorJobValue:_build_panel()
	self:_create_panel()
	self:_build_value_text("key", {})
	self:_build_value_text("value", {})
	self:_build_value_checkbox("save")
end
EditorJobValueFilter = EditorJobValueFilter or class(MissionScriptEditor)
EditorJobValueFilter.SAVE_UNIT_POSITION = false
EditorJobValueFilter.SAVE_UNIT_ROTATION = false
function EditorJobValueFilter:init(unit)
	EditorJobValueFilter.super.init(self, unit)
end
function EditorJobValueFilter:create_element()
    self.super.create_element(self)
 	self._element.class = "ElementJobValueFilter"	
	self._element.values.key = "none"
	self._element.values.value = 0
	self._element.values.save = nil
	self._element.values.check_type = "equal"   
end
function EditorJobValueFilter:_build_panel()
	EditorJobValue._build_panel(self)
	self:_build_value_combobox("check_type", {
		"equal",
		"less_than",
		"greater_than",
		"less_or_equal",
		"greater_or_equal",
		"has_key",
		"not_has_key"
	}, "Select which check operation to perform")
	self:add_help_text("Key is what to check. Value is what it is supposed to be to pass the filter. Different check types can be used i the value is known to be a number, for example, greater_then checks if the stored value is greater then the input value.")
end
EditorApplyJobValue = EditorApplyJobValue or class(MissionScriptEditor)
EditorApplyJobValue.SAVE_UNIT_POSITION = false
EditorApplyJobValue.SAVE_UNIT_ROTATION = false
function EditorApplyJobValue:init(unit)
	EditorApplyJobValue.super.init(self, unit)
end
function EditorApplyJobValue:create_element()
    self.super.create_element(self)
	self._element.class = "ElementApplyJobValue"
	self._element.values.key = "none"
	self._element.values.save = nil
	self._element.values.elements = {}
end
function EditorApplyJobValue:_build_panel()
	EditorJobValue._build_panel(self)
	self:_build_element_list("elements")	
end
