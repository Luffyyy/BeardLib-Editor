EditorInstigator = EditorInstigator or class(MissionScriptEditor)
EditorInstigator.SAVE_UNIT_POSITION = false
EditorInstigator.SAVE_UNIT_ROTATION = false
function EditorInstigator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementInstigator"
end
function EditorInstigator:_build_panel()
	self:_create_panel()
	self:_add_help_text("This element is a storage for an instigator. It can be used, set, etc from logic_instigator_operator.")
end
EditorInstigatorOperator = EditorInstigatorOperator or class(MissionScriptEditor)
EditorInstigatorOperator.SAVE_UNIT_POSITION = false
EditorInstigatorOperator.SAVE_UNIT_ROTATION = false
function EditorInstigatorOperator:create_element(unit)
	self.super.create_element(self)
	self._element.class = "ElementInstigatorOperator"
	self._element.values.elements = {}
	self._element.values.operation = "none"
	self._element.values.keep_on_use = false
end

function EditorInstigatorOperator:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementInstigator"})
	self:_build_value_combobox("operation", {
		"none",
		"set",
		"clear",
		"add_first",
		"add_last",
		"use_first",
		"use_last",
		"use_random",
		"use_all"
	}, "Select an operation for the selected elements")
	self:_build_value_checkbox("keep_on_use")
	self:_add_help_text("This element is an operator to logic_instigator element.")
end
EditorInstigatorTrigger = EditorInstigatorTrigger or class(MissionScriptEditor)
EditorInstigatorTrigger.SAVE_UNIT_POSITION = false
EditorInstigatorTrigger.SAVE_UNIT_ROTATION = false
function EditorInstigatorTrigger:create_element(unit)
	self.super.create_element(self)
	self._element.class = "ElementInstigatorTrigger"
	self._element.values.trigger_type = "set"
	self._element.values.elements = {}
end

function EditorInstigatorTrigger:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementInstigator"})
	self:_build_value_combobox("trigger_type", {
		"death",
		"set",
		"changed",
		"cleared"
	}, "Select a trigger type for the selected elements")
	self:_add_help_text("This element is a trigger to logic_instigator element.")
end
