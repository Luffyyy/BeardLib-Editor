EditLadder = EditLadder or class(EditUnit)
function EditLadder:editable(unit) return unit:ladder() ~= nil end
function EditLadder:update_positions() self:selected_unit():ladder():set_config() end

function EditLadder:build_menu(units)
	local ladder_options = self:group("Ladder")
	self._width = ladder_options:numberbox("Width[cm]", ClassClbk(self, "set_unit_data_parent"), units[1]:ladder():width(), {floats = 0, min = 0, help = "Sets the width of the ladder in cm"})
	self._height = ladder_options:numberbox("Height[cm]", ClassClbk(self, "set_unit_data_parent"), units[1]:ladder():height(), {floats = 0, min = 0, help = "Sets the height of the ladder in cm"})
	units[1]:set_config()
end

function EditLadder:set_unit_data()
	local unit = self:selected_unit()
	unit:ladder():set_width(self._width:Value())
	unit:ladder():set_height(self._height:Value())
end
 
function EditLadder:update(t, dt)
	for _, unit in ipairs(self._selected_units) do
		if unit:ladder() then
			unit:ladder():debug_draw()
		end
	end
end