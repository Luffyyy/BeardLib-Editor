EditWire = EditWire or class(EditUnit)
local A_TARGET = Idstring("a_target")
function EditWire:editable(unit) return unit:wire_data() and unit:get_object(A_TARGET) end

function EditWire:build_menu(parent)
	local group = self:Group("Wire")
	self:NumberBox("Slack", callback(self._parent, self._parent, "set_unit_data"), 0, {group = group})
	self:AxisControls(ClassClbk(self, "set_target_axis"), {group = group}, "TargetAxis")
end

function EditWire:update_positions() 
	self:set_unit_data()
	local object = self:target_object()
	self:SetAxisControls(object:position(), object:rotation(), "TargetAxis")
end

function EditWire:set_menu_unit(unit)   
	self._menu:GetItem("Slack"):SetValue(unit and unit:wire_data() and unit:wire_data().slack)
	local object = self:target_object()
	self:SetAxisControls(object:position(), object:rotation(), "TargetAxis")
end

function EditWire:target_object()
	return self:selected_unit():get_object(A_TARGET)
end

function EditWire:widget_unit()
	if Input:keyboard():down(Idstring("tab")) then
		return self:target_object()
	end
end

function EditWire:set_target_axis()
	local object = self:target_object()
	object:set_position(self:AxisControlsPosition("TargetAxis"))
	object:set_rotation(self:AxisControlsRotation("TargetAxis"))
	self:set_unit_data_parent()
end

function EditWire:set_unit_data()
	local unit = self:selected_unit()
	if unit then
		unit:wire_data().slack = self._menu:GetItem("Slack"):Value()
		local target = unit:get_object(A_TARGET)
		unit:wire_data().target_pos = target:position()
		local rot = target:rotation()
		unit:wire_data().target_rot = type(rot) ~= "number" and rot or Rotation() 
		unit:set_moving()
		CoreMath.wire_set_midpoint(unit, unit:orientation_object():name(), A_TARGET, Idstring("a_bender"))
	end
end