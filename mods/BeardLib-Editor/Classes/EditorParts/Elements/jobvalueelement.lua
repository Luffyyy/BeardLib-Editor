EditorJobValue = EditorJobValue or class(MissionScriptEditor)
function EditorJobValue:create_element()
    self.super.create_element(self)
	self._element.class = "ElementJobValue"
	self._element.values.key = "none"
	self._element.values.value = 0
	self._element.values.save = nil    
end

function EditorJobValue:_build_panel()
	self:_create_panel()
	self:StringCtrl("key")
	self:StringCtrl("value")
	self:BooleanCtrl("save")
end

EditorJobValueFilter = EditorJobValueFilter or class(MissionScriptEditor)
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
	self:ComboCtrl("check_type", {
		"equal",
		"less_than",
		"greater_than",
		"less_or_equal",
		"greater_or_equal",
		"has_key",
		"not_has_key"
	}, {help = "Select which check operation to perform"})
	self:Text("Key is what to check. Value is what it is supposed to be to pass the filter. Different check types can be used i the value is known to be a number, for example, greater_then checks if the stored value is greater then the input value.")
end

EditorApplyJobValue = EditorApplyJobValue or class(MissionScriptEditor)
function EditorApplyJobValue:create_element()
    self.super.create_element(self)
	self._element.class = "ElementApplyJobValue"
	self._element.values.key = "none"
	self._element.values.save = nil
	self._element.values.elements = {}
end

function EditorApplyJobValue:_build_panel()
	EditorJobValue._build_panel(self)
	self:BuildElementsManage("elements")	
end
