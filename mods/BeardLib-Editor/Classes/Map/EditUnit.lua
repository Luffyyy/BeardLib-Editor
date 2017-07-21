EditUnit = EditUnit or class(EditorPart)
function EditUnit:init() end
function EditUnit:build_menu() end
function EditUnit:update() end
function EditUnit:editable(unit) return true end
function EditUnit:super_editable(unit) return (alive(unit) and unit:unit_data()) and self:editable(unit) end
function EditUnit:is_editable(parent, name)
	local units = parent._selected_units
	if self:super_editable(units[1]) then
		self._selected_units = units
	else
		return nil
	end
	self:init_basic(parent, name)
	self._menu = parent:GetMenu()
	MenuUtils:new(self)
	self:build_menu(units)
	return self
end

function EditUnit:set_unit_data_parent()
	self._parent:set_unit_data()
end