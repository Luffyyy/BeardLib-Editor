EditorLogicChance = EditorLogicChance or class(MissionScriptEditor)
 
function EditorLogicChance:create_element()
	self.super.create_element(self)
	self._element.class = "ElementLogicChance"
	self._element.values.chance = 100
end
function EditorLogicChance:_build_panel()
	self:_create_panel()
	self:_build_value_number("chance", {
		floats = 0,
		min = 0,
		max = 100
	}, "Specifies chance that this element will call its on executed elements (in percent)")
end
EditorLogicChanceOperator = EditorLogicChanceOperator or class(MissionScriptEditor)
 
function EditorLogicChanceOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementLogicChanceOperator"
	self._element.values.operation = "none"
	self._element.values.chance = 0
	self._element.values.elements = {}
end
function EditorLogicChanceOperator:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementLogicChance"})
	self:_build_value_combobox("operation", {
		"none",
		"add_chance",
		"subtract_chance",
		"reset",
		"set_chance"
	}, "Select an operation for the selected elements")
	self:_build_value_number("chance", {
		floats = 0,
		min = 0,
		max = 100
	}, "Amount of chance to add, subtract or set to the logic chance elements.")
	self:_add_help_text("This element can modify logic_chance element. Select logic chance elements to modify using insert and clicking on the elements.")
end
EditorLogicChanceTrigger = EditorLogicChanceTrigger or class(MissionScriptEditor)
function EditorLogicChanceTrigger:create_element()
	self.super.create_element(self)
	self._element.values.class = "ElementLogicChanceTrigger"
	self._element.values.outcome = "fail"
	self._element.values.elements = {}
end

function EditorLogicChanceTrigger:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementLogicChance"})
	self:_build_value_combobox("outcome", {"fail", "success"}, "Select an outcome to trigger on")
	self:_add_help_text("This element is a trigger to logic_chance element.")
end
