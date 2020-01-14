EditorInstigator = EditorInstigator or class(MissionScriptEditor)
function EditorInstigator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementInstigator"
end

function EditorInstigator:_build_panel()
	self:_create_panel()
	self:Text("This element is a storage for an instigator. It can be used, set, etc from instigator operator elements")
end

EditorInstigatorOperator = EditorInstigatorOperator or class(MissionScriptEditor)
function EditorInstigatorOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementInstigatorOperator"
	self._element.values.elements = {}
	self._element.values.operation = "none"
	self._element.values.keep_on_use = false
end

function EditorInstigatorOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementInstigator"})
	self:ComboCtrl("operation", {
		"none",
		"set",
		"clear",
		"add_first",
		"add_last",
		"use_first",
		"use_last",
		"use_random",
		"use_all"
	}, {help = "Select an operation for the selected elements"})
	self:BooleanCtrl("keep_on_use")
	self:Text("This element is an operator to instigator elements.")
end

function EditorInstigatorOperator:draw_links()
	EditorInstigatorOperator.super.draw_links(self)
	local selected_unit = self:selected_unit()
	for _, id in ipairs(self._element.values.elements) do
		local unit = self:GetPart("mission"):get_element_unit(id)
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:draw_link({
				g = 0.85,
				b = 0.25,
				r = 0.85,
				from_unit = self._unit,
				to_unit = unit
			})
		end
	end
end

EditorInstigatorTrigger = EditorInstigatorTrigger or class(MissionScriptEditor)
function EditorInstigatorTrigger:create_element(unit)
	self.super.create_element(self)
	self._element.class = "ElementInstigatorTrigger"
	self._element.values.trigger_type = "set"
	self._element.values.elements = {}
end

function EditorInstigatorTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementInstigator"})
	self:ComboCtrl("trigger_type", {
		"death",
		"set",
		"changed",
		"cleared"
	}, {help = "Select a trigger type for the selected elements"})
	self:Text("This element is a trigger to instigator elements.")
end

EditorInstigatorTrigger.draw_links = EditorInstigatorOperator.draw_links