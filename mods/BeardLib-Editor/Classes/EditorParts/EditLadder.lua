EditLadder = EditLadder or class(EditUnit)
function EditLadder:editable(unit)
	return unit:ladder() ~= nil
end

function EditLadder:build_menu(units)
	local ladder_options = self:Group("Ladder")
	self._width = self:NumberBox("Width[cm]", callback(self._parent, self._parent, "set_unit_data"), units[1]:ladder():height(), {floats = 0, min = 0, help = "Sets the width of the ladder in cm", group = ladder_options})
	self._height = self:NumberBox("Height[cm]", callback(self._parent, self._parent, "set_unit_data"), units[1]:ladder():height(), {floats = 0, min = 0, help = "Sets the height of the ladder in cm", group = ladder_options})
end

function EditLadder:set_unit_data()
	local unit = self:selected_unit()
	unit:ladder():set_width(self._Width:Value())
	unit:ladder():set_height(self._height:Value())
end
 
function EditLadder:update(t, dt)
	for _, unit in ipairs(self._selected_units) do
		if unit:ladder() then
			unit:ladder():debug_draw()
		end
	end
end