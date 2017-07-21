EditWire = EditWire or class(EditUnit)
function EditWire:editable(unit) return unit:wire_data() end

function EditWire:build_menu(parent)
	self:NumberBox("Slack", callback(self._parent, self._parent, "set_unit_data"), 0, {group = self._menu:GetItem("Main")})
end

function EditWire:update_positions() self:set_unit_data() end

function EditWire:set_menu_unit(unit)   
	self._menu:GetItem("Slack"):SetValue(unit and unit:wire_data() and unit:wire_data().slack)
end

function EditWire:widget_unit()
	if Input:keyboard():down(Idstring("tab")) then
		return self:selected_unit():get_object(Idstring("a_target"))
	end
end

function EditWire:set_unit_data()
	local unit = self:selected_unit()
	if unit then
		unit:wire_data().slack = self._menu:GetItem("Slack"):Value()
		local target = unit:get_object(Idstring("a_target"))
		unit:wire_data().target_pos = target:position()
		local rot = target:rotation()
		unit:wire_data().target_rot = type(rot) ~= "number" and rot or Rotation() 
		unit:set_moving()
		CoreMath.wire_set_midpoint(unit, unit:orientation_object():name(), Idstring("a_target"), Idstring("a_bender"))
	end
end