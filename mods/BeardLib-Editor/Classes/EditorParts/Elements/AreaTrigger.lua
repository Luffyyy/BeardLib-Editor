core:import("CoreShapeManager")
EditorAreaTrigger = EditorAreaTrigger or class(MissionScriptEditor)

function EditorAreaTrigger:init(element)
	self.super.init(self, element)
end
 
function EditorAreaTrigger:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAreaTrigger"
	self._element.values.trigger_times = 1
	self._element.values.interval = 0.1
	self._element.values.trigger_on = "on_enter"
	self._element.values.instigator = managers.mission:default_area_instigator()
	self._element.values.shape_type = "box"
	self._element.values.width = 500
	self._element.values.depth = 500
	self._element.values.height = 500
	self._element.values.radius = 250
	self._element.values.spawn_unit_elements = {}
	self._element.values.amount = "1"
	self._element.values.use_shape_element_ids = nil
	self._element.values.use_disabled_shapes = false
	self._element.values.rules_element_ids = nil
	self._element.values.unit_ids = nil	
end
function EditorAreaTrigger:_add_unit_id(id)
	table.insert(self._element.values.unit_ids, id)
	if self._instigator_ctrlr then
		self._instigator_ctrlr:set_enabled(not self._element.values.unit_ids)
	end
end

function EditorAreaTrigger:_remove_unit_id(id)
	table.delete(self._element.values.unit_ids, id)
	self._element.values.unit_ids = #self._element.values.unit_ids > 0 and self._element.values.unit_ids or nil
	if alive(self._instigator_ctrlr) then
		self._instigator_ctrlr:set_enabled(not self._element.values.unit_ids)
	end
end


function EditorAreaTrigger:_set_shape_type()
	local is_box = self._element.values.shape_type == "box"
	local is_cylinder = self._element.values.shape_type == "cylinder"
	local uses_external = self._element.values.use_shape_element_ids
	is_box = (not uses_external and is_box)
	is_cylinder = (not uses_external and is_cylinder)
	self._depth_params:SetEnabled(is_box)
	self._width_params:SetEnabled(is_box)
	self._height_params:SetEnabled(is_box or is_cylinder)
	self._radius_params:SetEnabled(is_cylinder)
	self._shape_type_params:SetEnabled(not uses_external)
	self._use_disabled_shapes:SetEnabled(uses_external)
end

function EditorAreaTrigger:create_values_ctrlrs(disable)
	self:_build_value_number("interval", {min = 0.01}, "Set the check interval for the area, in seconds.")
	if not disable or not disable.trigger_type then
		self:_build_value_combobox("trigger_on", {"on_enter", "on_exit", "both", "on_empty", "while_inside"})
	end
	if not disable or not disable.instigator then
		local instigator, _ = self:_build_value_combobox("instigator", managers.mission:area_instigator_categories(), "Select an instigator type for the area")
		self._instigator_ctrlr = instigator
		self._instigator_ctrlr:SetEnabled(not self._element.values.unit_ids)
	end
	if not disable or not disable.amount then
		self:_build_value_combobox("amount", {"1", "2", "3", "4", "all"}, "Select how many are required to trigger area")
	end
	self._use_disabled_shapes = self:_build_value_checkbox("use_disabled_shapes")
end

function EditorAreaTrigger:_build_panel(disable_params)
	self:_create_panel()
	self:create_values_ctrlrs(disable_params)
 	
	local shape_type = self:_build_value_combobox("shape_type", {"box", "cylinder"}, "Select shape for area")
	self._shape_type_params = shape_type

	local width = self:_build_value_number("width", {min = 0}, "Set the width for the shape")
	self._width_params = width
	local depth = self:_build_value_number("depth", {min = 0}, "Set the depth for the shape")
	self._depth_params = depth
	local height = self:_build_value_number("height", {min = 0}, "Set the height for the shape")
	self._height_params = height
	local radius = self:_build_value_number("radius", {min = 0}, "Set the radius for the shape")
	self._radius_params = radius
	self:_set_shape_type()
end

function EditorAreaTrigger:clone_data(...)
	EditorAreaTrigger.super.clone_data(self, ...)
end

AreaOperatorElement = AreaOperatorElement or class(MissionScriptEditor)
AreaOperatorElement.SAVE_UNIT_POSITION = false
AreaOperatorElement.SAVE_UNIT_ROTATION = false
function AreaOperatorElement:init(...)
	AreaOperatorElement.super.init(self, ...)
end

function AreaOperatorElement:init(unit)
	CoreAreaOperatorElement.super.init(self, unit)
	self._element.class = "ElementAreaOperator"
	self._element.values.elements = {}
	self._element.values.interval = 0.1
	self._element.values.trigger_on = "on_enter"
	self._element.values.instigator = managers.mission:default_area_instigator()
	self._element.values.amount = "1"
	self._element.values.use_disabled_shapes = false
	self._element.values.operation = "none"
	self._apply_on_checkboxes = {"interval", "use_disabled_shapes"}
	for _,uses in ipairs(self._apply_on_checkboxes) do
		self._element.values["apply_on_" .. uses] = false
		table.insert(self._save_values, "apply_on_" .. uses)
	end
end

function AreaOperatorElement:add_element()

end

function AreaOperatorElement:_build_panel()
	self:_create_panel()
	local exact_names = {"core/units/mission_elements/trigger_area/trigger_area"}
	self:_build_add_remove_unit_from_list(self._element.values.elements, nil, exact_names)
	EditorAreaTrigger.create_values_ctrlrs(self, {trigger_type = true, instigator = true, amount = true})
	panel_sizer:add(EWS:StaticLine(panel, "", "LI_HORIZONTAL"), 0, 5, "EXPAND,TOP,BOTTOM")
	self:_build_value_combobox("operation", {"none", "clear_inside"}, "Select an operation for the selected elements")
	for _,uses in ipairs(self._apply_on_checkboxes) do
		local name = "apply_on_" .. uses
		self:_build_value_checkbox(name)
	end
	self:_add_help_text("This element can modify trigger_area element. Select areas to modify using insert and clicking on the elements.")
end

AreaReportTriggerElement = AreaReportTriggerElement or class(EditorAreaTrigger)
AreaReportTriggerElement.ON_EXECUTED_ALTERNATIVES = {"enter", "leave", "empty", "while_inside", "on_death", "rule_failed", "reached_amount"}

function AreaReportTriggerElement:init(...)
	AreaReportTriggerElement.super.init(self, ...)
	self._element.class = "ElementTriggerAreaReport"
	self._element.values.trigger_on = nil
end

function AreaReportTriggerElement:_build_panel()
	AreaReportTriggerElement.super._build_panel(self, {trigger_type = true})
end


