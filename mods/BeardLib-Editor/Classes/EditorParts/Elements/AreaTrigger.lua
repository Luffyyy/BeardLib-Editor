core:import("CoreShapeManager")
EditorAreaTrigger = EditorAreaTrigger or class(MissionScriptEditor)

function EditorAreaTrigger:create_element()
	EditorAreaTrigger.super.create_element(self)
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

function EditorAreaTrigger:set_shape_property(menu, item)	
	self:set_element_data(item.name, menu, item)
	self._shape:set_property(item.name, item.value)
	self._cylinder_shape:set_property(item.name, item.value)
end

function EditorAreaTrigger:create_shapes()
	self._shape = CoreShapeManager.ShapeBoxMiddle:new({position = self._element.values.position, rotation = self._element.values.rotation, width = self._element.values.width, depth = self._element.values.depth, height = self._element.values.height})
	self._cylinder_shape = CoreShapeManager.ShapeCylinderMiddle:new({position = self._element.values.position, rotation = self._element.values.rotation, radius = self._element.values.radius, height = self._element.values.height})	
end

function EditorAreaTrigger:_add_unit_id(id)
	table.insert(self._element.values.unit_ids, id)
	if self._instigator_ctrlr then
		self._instigator_ctrlr:set_enabled(not self._element.values.unit_ids)
	end
end
function EditorAreaTrigger:get_shape()
	if not self._shape then
		self:create_shapes()
	end
	return self._element.values.shape_type == "box" and self._shape or self._element.values.shape_type == "cylinder" and self._cylinder_shape
end
function EditorAreaTrigger:update(t, dt, selected_unit, all_units)
	if not self._element.values.use_shape_element_ids then
		local shape = self:get_shape()
		if shape then
			shape:draw(t, dt, 1, 1, 1)
		end
	else
		--self:_check_removed_units(all_units) 
		for _,id in ipairs(self._element.values.use_shape_element_ids) do
			local unit = all_units[id]
			local shape = unit:mission_element():get_shape()
			shape:draw(t, dt, 0.85, 0.85, 0.85)
		end
	end
	self._shape:set_position(self._element.values.position)
	self._cylinder_shape:set_position(self._element.values.position)	
	self._shape:set_rotation(self._element.values.rotation)
	self._cylinder_shape:set_rotation(self._element.values.rotation)
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
	self:NumberCtrl("interval", {min = 0.01, help ="Set the check interval for the area, in seconds."})
	if not disable or not disable.trigger_type then
		self:ComboCtrl("trigger_on", {"on_enter", "on_exit", "both", "on_empty", "while_inside"})
	end
	if not disable or not disable.instigator then
		local instigator, _ = self:ComboCtrl("instigator", managers.mission:area_instigator_categories(), {help = "Select an instigator type for the area"})
		self._instigator_ctrlr = instigator
		self._instigator_ctrlr:SetEnabled(not self._element.values.unit_ids)
	end
	if not disable or not disable.amount then
		self:ComboCtrl("amount", {"1", "2", "3", "4", "all"}, {help = "Select how many are required to trigger area"})
	end
	self._use_disabled_shapes = self:BooleanCtrl("use_disabled_shapes")
end

function EditorAreaTrigger:_build_panel(disable_params)
	self:_create_panel()
	self:create_values_ctrlrs(disable_params)
 	
	local shape_type = self:ComboCtrl("shape_type", {"box", "cylinder"}, {help = "Select shape for area"})
	self._shape_type_params = shape_type

	local width = self:NumberCtrl("width", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the width for the shape"})
	self._width_params = width
	local depth = self:NumberCtrl("depth", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the depth for the shape"})
	self._depth_params = depth
	local height = self:NumberCtrl("height", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the height for the shape"})
	self._height_params = height
	local radius = self:NumberCtrl("radius", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the radius for the shape"})
	self._radius_params = radius
	self:_set_shape_type()
end

AreaOperatorElement = AreaOperatorElement or class(MissionScriptEditor)
function AreaOperatorElement:init(unit)
	self.super.init(self, unit)
	self._apply_on_checkboxes = {"interval", "use_disabled_shapes"}
	for _,uses in ipairs(self._apply_on_checkboxes) do
		self._element.values["apply_on_" .. uses] = false
		table.insert(self._save_values, "apply_on_" .. uses)
	end
end
function AreaOperatorElement:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAreaOperator"
	self._element.values.elements = {}
	self._element.values.interval = 0.1
	self._element.values.trigger_on = "on_enter"
	self._element.values.instigator = managers.mission:default_area_instigator()
	self._element.values.amount = "1"
	self._element.values.use_disabled_shapes = false
	self._element.values.operation = "none"	
end
function AreaOperatorElement:_build_panel()
	self:_create_panel()
	local exact_names = {"core/units/mission_elements/trigger_area/trigger_area"}
	self:_build_add_remove_unit_from_list(self._element.values.elements, nil, exact_names)
	EditorAreaTrigger.create_values_ctrlrs(self, {trigger_type = true, instigator = true, amount = true})
	self:ComboCtrl("operation", {"none", "clear_inside"}, {help = "Select an operation for the selected elements"})
	for _,uses in ipairs(self._apply_on_checkboxes) do
		local name = "apply_on_" .. uses
		self:BooleanCtrl(name)
	end
	self:Text("This element can modify trigger_area element. Select areas to modify using insert and clicking on the elements.")
end

AreaReportTriggerElement = AreaReportTriggerElement or class(EditorAreaTrigger)
AreaReportTriggerElement.ON_EXECUTED_ALTERNATIVES = {"enter", "leave", "empty", "while_inside", "on_death", "rule_failed", "reached_amount"}

function AreaReportTriggerElement:create_element(...)
	AreaReportTriggerElement.super.create_element(self, ...)
	self._element.class = "ElementTriggerAreaReport"
	self._element.values.trigger_on = nil
end

function AreaReportTriggerElement:_build_panel()
	AreaReportTriggerElement.super._build_panel(self, {trigger_type = true})
end


