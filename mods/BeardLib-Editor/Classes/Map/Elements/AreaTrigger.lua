core:import("CoreShapeManager")
EditorAreaTrigger = EditorAreaTrigger or class(MissionScriptEditor)
function EditorAreaTrigger:init(...)
	local unit = EditorAreaTrigger.super.init(self, ...)
	self._scripts = {}
	return unit
end

function EditorAreaTrigger:create_element()
	EditorAreaTrigger.super.create_element(self)
	self._element.class = "ElementAreaTrigger"
	self._element.module = "CoreElementArea"
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
	self:set_element_data(menu, item)
	self._shape:set_property(item.name, item:Value())
	self._cylinder_shape:set_property(item.name, item:Value())
end

function EditorAreaTrigger:destroy()
	for _, script in pairs(self._scripts) do
		if script.destroy then
			script:destroy()
		end
	end
	if self._shape then
		self._shape:destroy()
	end
	if self._cylinder_shape then
		self._cylinder_shape:destroy()
	end
end

function EditorAreaTrigger:create_shapes()
	self._shape = CoreShapeManager.ShapeBoxMiddle:new({position = self._element.values.position, rotation = self._element.values.rotation, width = self._element.values.width, depth = self._element.values.depth, height = self._element.values.height})
	self._cylinder_shape = CoreShapeManager.ShapeCylinderMiddle:new({position = self._element.values.position, rotation = self._element.values.rotation, radius = self._element.values.radius, height = self._element.values.height})	
end

function EditorAreaTrigger:get_shape()
	if not self._shape then
		self:create_shapes()
	end
	return self._element.values.shape_type == "box" and self._shape or self._element.values.shape_type == "cylinder" and self._cylinder_shape
end

function EditorAreaTrigger:update(t, dt)
    if not self._element.values.use_shape_element_ids then
        local shape = self:get_shape()
        if shape then
            shape:draw(t, dt, 1, 1, 1)
        end
    else
        for _, id in ipairs(self._element.values.use_shape_element_ids) do
            if not self._scripts[id] then
                local element = managers.mission:get_mission_element(id)
                local clss = MissionEditor:get_editor_class(element.class)
                if clss then
                    self._scripts[id] = clss:new(element)
                end
            else
                local shape = self._scripts[id]:get_shape()
                shape:draw(t, dt, 0.85, 0.85, 0.85)
            end
        end
    end
    if self._shape then
	    self._shape:set_position(self._element.values.position)
	    self._cylinder_shape:set_position(self._element.values.position)    
	    self._shape:set_rotation(self._element.values.rotation)
	    self._cylinder_shape:set_rotation(self._element.values.rotation)
	end
end

function EditorAreaTrigger:set_shape_type()
	local is_box = self._element.values.shape_type == "box"
	local is_cylinder = self._element.values.shape_type == "cylinder"
	local uses_external = self._element.values.use_shape_element_ids
	is_box = (not uses_external and is_box)
	is_cylinder = (not uses_external and is_cylinder)
	self._depth:SetEnabled(is_box)
	self._width:SetEnabled(is_box)
	self._height:SetEnabled(is_box or is_cylinder)
	self._radius:SetEnabled(is_cylinder)
	if self._use_disabled then
		self._shape_type:SetEnabled(not uses_external)
		self._use_disabled:SetEnabled(uses_external)
	end
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

function EditorAreaTrigger:nil_if_empty(value_name)
	if self._element.values[value_name] and #self._element.values[value_name] == 0 then
		self._element.values[value_name] = nil
	end
end

function EditorAreaTrigger:_build_panel(disable_params)
	self:_create_panel()
	self:BuildUnitsManage("unit_ids")
	self:BuildElementsManage("spawn_unit_elements", nil, {"ElementSpawnUnit"})
	self:BuildElementsManage("use_shape_element_ids", nil, {"ElementAreaTrigger", "ElementShape"}, callback(self, self, "nil_if_empty"))
	self:BuildElementsManage("rules_element_ids", nil, {"ElementInstigatorRule"}, callback(self, self, "nil_if_empty"))
	self:create_values_ctrlrs(disable_params)
 	
	self._shape_type = self:ComboCtrl("shape_type", {"box", "cylinder"}, {help = "Select shape for area"})
	self._width = self:NumberCtrl("width", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the width for the shape"})
	self._depth = self:NumberCtrl("depth", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the depth for the shape"})
	self._height = self:NumberCtrl("height", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the height for the shape"})
	self._radius = self:NumberCtrl("radius", {floats = 0, callback = callback(self, self, "set_shape_property"), help ="Set the radius for the shape"})
	self:set_shape_type()
end

EditorAreaOperator = EditorAreaOperator or class(MissionScriptEditor)
function EditorAreaOperator:init(...)
	local unit = EditorAreaOperator.super.init(self, ...)
	self._apply_on_checkboxes = {"interval", "use_disabled_shapes"}
	for _,uses in ipairs(self._apply_on_checkboxes) do
		self._element.values["apply_on_" .. uses] = false
	end
	return unit
end

function EditorAreaOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAreaOperator"
	self._element.module = "CoreElementArea"
	self._element.values.elements = {}
	self._element.values.interval = 0.1
	self._element.values.trigger_on = "on_enter"
	self._element.values.instigator = managers.mission:default_area_instigator()
	self._element.values.amount = "1"
	self._element.values.use_disabled_shapes = false
	self._element.values.operation = "none"	
end

function EditorAreaOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementAreaTrigger"})
	EditorAreaTrigger.create_values_ctrlrs(self, {trigger_type = true, instigator = true, amount = true})
	self:ComboCtrl("operation", {"none", "clear_inside"}, {help = "Select an operation for the selected elements"})
	for _,uses in ipairs(self._apply_on_checkboxes) do
		local name = "apply_on_" .. uses
		self:BooleanCtrl(name)
	end
	self:Text("This element can modify trigger_area element. Select areas to modify using insert and clicking on the elements.")
end

EditorAreaReportTrigger = EditorAreaReportTrigger or class(EditorAreaTrigger)
EditorAreaReportTrigger.ON_EXECUTED_ALTERNATIVES = {"enter", "leave", "empty", "while_inside", "on_death", "rule_failed", "reached_amount"}
function EditorAreaReportTrigger:create_element()
	EditorAreaReportTrigger.super.create_element(self)
	self._element.class = "ElementAreaReportTrigger"
	self._element.module = "CoreElementArea"
	self._element.values.trigger_on = nil
end

function EditorAreaReportTrigger:_build_panel()
	EditorAreaReportTrigger.super._build_panel(self, {trigger_type = true})
end