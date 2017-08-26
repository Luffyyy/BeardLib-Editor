EditorLogicChance = EditorLogicChance or class(MissionScriptEditor)
function EditorLogicChance:create_element()
	self.super.create_element(self)
	self._element.class = "ElementLogicChance"
	self._element.values.chance = 100
end

function EditorLogicChance:_build_panel()
	self:_create_panel()
	self:NumberCtrl("chance", {
		floats = 0,
		min = 0,
		max = 100,
		help = "Specifies chance that this element will call its on executed elements (in percent)"
	})
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
	self:BuildElementsManage("elements", nil, {"ElementLogicChance"})
	self:ComboCtrl("operation", {
		"none",
		"add_chance",
		"subtract_chance",
		"reset",
		"set_chance"
	}, {help = "Select an operation for the selected elements"})
	self:NumberCtrl("chance", {
		floats = 0,
		min = 0,
		max = 100,
		help = "Amount of chance to add, subtract or set to the logic chance elements."
	})
	self:Text("This element can modify logic chance elements. Select logic chance elements to modify using insert and clicking on the elements.")
end

EditorLogicChanceTrigger = EditorLogicChanceTrigger or class(MissionScriptEditor)
function EditorLogicChanceTrigger:create_element()
	self.super.create_element(self)
	self._element.class = "ElementLogicChanceTrigger"
	self._element.values.outcome = "fail"
	self._element.values.elements = {}
end

function EditorLogicChanceTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementLogicChance"})
	self:ComboCtrl("outcome", {"fail", "success"}, {help = "Select an outcome to trigger on"})
	self:Text("This element is a trigger to logic chance elements.")
end
