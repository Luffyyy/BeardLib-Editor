EditZipLine = EditZipLine or class(EditUnit)
function EditZipLine:editable(unit)	
	return self.super.editable(self, unit) and unit:zipline() ~= nil
end

function EditZipLine:build_menu(units)
	local zipline_options = self:Group("Zipline")
	self:Divider(tostring(units[1]:zipline():end_pos()), {group = zipline_options})
	self:Button("UseCameraPosForPositionEnd", callback(self, self, "use_camera_pos"), {group = zipline_options})
	self:Button("UseCameraPosForLinePositionEnd", callback(self, self, "use_camera_pos_for_line"), {group = zipline_options})
	self._speed = self:NumberBox("Speed [cm/s]", callback(self._parent, self._parent, "set_unit_data"), units[1]:zipline():speed(), {floats = 0, min = 0, help = "Sets the speed of the zipline in cm/s", group = zipline_options})
	self._slack = self:NumberBox("Slack [cm]", callback(self._parent, self._parent, "set_unit_data"), units[1]:zipline():slack(), {floats = 0, min = 0, help = "Value to define slack of the zipline in cm", group = zipline_options})
 	self._type = self:ComboBox("Type", callback(self._parent, self._parent, "set_unit_data"), ZipLine.TYPES, table.get_key(ZipLine.TYPES, units[1]:zipline():usage_type()), {group = zipline_options})
	self._ai_ignore_bag = self:Toggle("AIIgnoreBag", callback(self._parent, self._parent, "set_unit_data"), units[1]:zipline():ai_ignores_bag(), {text = "AI Ignore Bag", group = zipline_options})
end

function EditZipLine:set_unit_data()
	local unit = self:selected_unit()
	unit:zipline():set_speed(self._speed:Value())
	unit:zipline():set_slack(self._slack:Value())
	unit:zipline():set_usage_type(self._type:SelectedItem())
	unit:zipline():set_ai_ignores_bag(self._ai_ignore_bag:SelectedItem())
end

function EditZipLine:update(t, dt)
	for _, unit in ipairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():debug_draw(t, dt)
		end
	end
end

function EditZipLine:use_camera_pos()
	self:selected_unit():zipline():set_end_pos(managers.editor:camera_position())
end

function EditZipLine:use_camera_pos_for_line()
	self:selected_unit():set_end_pos_by_line(managers.editor:camera_position())
end