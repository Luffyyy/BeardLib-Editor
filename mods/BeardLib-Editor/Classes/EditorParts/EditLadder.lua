EditLadder = EditLadder or class(EditorPart)
function EditLadder:init()
end
function EditLadder:is_editable(parent, menu, name)
	local units = parent._selected_units
	if alive(units[1]) and units[1]:ladder() then
		self._selected_units = units
	else
		return nil
	end
	self.super.init_basic(self, parent, menu, name)
	self._menu = parent._menu
	local ladder_options = self:Group("Ladder")

	self._width = self:NumberBox("Width[cm]", callback(self, self, "_update_width"), units[1]:ladder():height(), {floats = 0, min = 0, help = "Sets the width of the ladder in cm", group = ladder_options})
	self._height = self:NumberBox("Height[cm]", callback(self, self, "_update_height"), units[1]:ladder():height(), {floats = 0, min = 0, help = "Sets the height of the ladder in cm", group = ladder_options})
	return self
end

function EditLadder:update(t, dt)
	for _, unit in ipairs(self._selected_units) do
		if unit:ladder() then
			unit:ladder():debug_draw()
		end
	end
end

function EditLadder:_update_width(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if unit:ladder() then
			unit:ladder():set_width(item:Value())
		end
	end
	self._parent:set_unit_data()
end

function EditLadder:_update_height(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if unit:ladder() then
			unit:ladder():set_height(item:Value())
		end
	end
	self._parent:set_unit_data()
end
