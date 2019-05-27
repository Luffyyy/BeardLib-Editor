EditZipLine = EditZipLine or class(EditUnit)
function EditZipLine:editable(unit)	
	return self.super.editable(self, unit) and unit:zipline() ~= nil
end

function EditZipLine:build_menu(units)
	local zipline_options = self:group("Zipline")
	self._epos = zipline_options:Vector3("EndPosition", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():end_pos(), {step = self:Val("GridSize")})
	zipline_options:button("ResetPositionEnd", ClassClbk(self, "use_pos"))
	zipline_options:button("UseCameraPosForPositionEnd", ClassClbk(self, "use_camera_pos"))
	zipline_options:button("UseCameraPosForLinePositionEnd", ClassClbk(self, "use_camera_pos_for_line"))
	self._speed = zipline_options:numberbox("Speed [cm/s]", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():speed(), {floats = 0, min = 0, help = "Sets the speed of the zipline in cm/s"})
	self._slack = zipline_options:numberbox("Slack [cm]", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():slack(), {floats = 0, min = 0, help = "Value to define slack of the zipline in cm"})
 	self._type = zipline_options:combobox("Type", ClassClbk(self, "set_unit_data_parent"), ZipLine.TYPES, table.get_key(ZipLine.TYPES, units[1]:zipline():usage_type()))
	self._ai_ignore_bag = zipline_options:tickbox("AIIgnoreBag", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():ai_ignores_bag(), {text = "AI Ignore Bag"})
end

function EditZipLine:set_unit_data()
	local unit = self:selected_unit()
	if alive(unit) then
		unit:zipline():set_speed(self._speed:Value())
		unit:zipline():set_slack(self._slack:Value())
		unit:zipline():set_usage_type(self._type:SelectedItem())
		unit:zipline():set_ai_ignores_bag(self._ai_ignore_bag:Value())
		unit:zipline():set_end_pos(self._epos:Value())
	end
end

function EditZipLine:update(t, dt)
	for _, unit in pairs(self._selected_units) do
		if unit:zipline() then
			unit:zipline():debug_draw(t, dt)
		end
	end
end

function EditZipLine:update_end_pos()
	self._epos:SetValue(self:selected_unit():zipline():end_pos())
	self:set_unit_data_parent()
end
function EditZipLine:use_pos()
	local unit = self:selected_unit()
	if alive(unit) then
		unit:zipline():set_end_pos(unit:position())
		self:update_end_pos()
	end
end

function EditZipLine:use_camera_pos()
	self:selected_unit():zipline():set_end_pos(managers.editor:camera_position())
	self:update_end_pos()
end

function EditZipLine:use_camera_pos_for_line()
	self:selected_unit():set_end_pos_by_line(managers.editor:camera_position())
	self:update_end_pos()
end

function EditZipLine:update_positions()
	local unit = self:selected_unit()
	if alive(unit) then
		unit:zipline():set_start_pos(unit:position())
	end
end