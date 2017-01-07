EditZipLine = EditZipLine or class(EditorPart)
function EditZipLine:init()
end
function EditZipLine:is_editable(parent, menu, name)
	local units = parent._selected_units
	if alive(units[1]) and units[1]:zipline() then
		self._selected_units = units
	else
		return nil
	end
	self.super.init_basic(self, parent, menu, name)
	self._menu = parent._menu
	local zipline_options = self:Group("Zipline")

	self:Divider(tostring(units[1]:zipline():end_pos()), {group = zipline_options})
	self:Button("UseCameraPosForPositionEnd", callback(self, self, "_use_camera_pos"), {group = zipline_options})
	self:Button("UseCameraPosForLinePositionEnd", callback(self, self, "_use_camera_pos_for_line"), {group = zipline_options})
	self:NumberBox("Speed [cm/s]", callback(self, self, "_update_speed"), units[1]:zipline():speed(), {floats = 0, min = 0, help = "Sets the speed of the zipline in cm/s", group = zipline_options})
	self:NumberBox("Slack [cm]", callback(self, self, "_update_slack"), units[1]:zipline():slack(), {floats = 0, min = 0, help = "Value to define slack of the zipline in cm", group = zipline_options})
 	self:ComboBox("Type", callback(self, self, "_change_type"), ZipLine.TYPES, table.get_key(ZipLine.TYPES, units[1]:zipline():usage_type()), {group = zipline_options})
	self:Toggle("AIIgnoreBag", callback(self, self, "set_ai_ignores_bag"), units[1]:zipline():ai_ignores_bag(), {text = "AI Ignore Bag", group = zipline_options})
	return self
end
function EditZipLine:update(t, dt)
	for _, unit in ipairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():debug_draw(t, dt)
		end
	end
end
function EditZipLine:_use_camera_pos()
	for _, unit in ipairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():set_end_pos(managers.editor:camera_position())
		end
	end
	self._parent:set_unit_data()
end
function EditZipLine:_use_camera_pos_for_line()
	for _, unit in ipairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():set_end_pos_by_line(managers.editor:camera_position())
		end
	end
	self._parent:set_unit_data()
end
function EditZipLine:_update_speed(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():set_speed(item:Value())
		end
	end
	self._parent:set_unit_data()
end
function EditZipLine:_update_slack(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():set_slack(item:Value())
		end
	end
	self._parent:set_unit_data()
end
function EditZipLine:_change_type(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:zipline() then
			unit:zipline():set_usage_type(item:SelectedItem())
		end
	end
	self._parent:set_unit_data()
end
function EditZipLine:set_ai_ignores_bag(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:zipline() then
			unit:zipline():set_ai_ignores_bag(item:Value())
		end
	end
	self._parent:set_unit_data()
end
 