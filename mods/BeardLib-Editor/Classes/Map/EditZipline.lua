EditZipLine = EditZipLine or class(EditUnit)
function EditZipLine:editable(unit)	
	return self.super.editable(self, unit) and unit:zipline() ~= nil
end

function EditZipLine:build_menu(units)
	local zipline_options = self:Group("Zipline")
	self:AxisControls(ClassClbk(self, "set_unit_data_parent"), {
		text = "End position",
		group = zipline_options,
		no_rot = true,
		step = self:Value("GridSize")
	}, "EndPos", units[1]:zipline():end_pos())
	
	self:Button("ResetPositionEnd", ClassClbk(self, "use_pos"), {group = zipline_options})
	self:Button("UseCameraPosForPositionEnd", ClassClbk(self, "use_camera_pos"), {group = zipline_options})
	self:Button("UseCameraPosForLinePositionEnd", ClassClbk(self, "use_camera_pos_for_line"), {group = zipline_options})
	self._speed = self:NumberBox("Speed [cm/s]", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():speed(), {floats = 0, min = 0, help = "Sets the speed of the zipline in cm/s", group = zipline_options})
	self._slack = self:NumberBox("Slack [cm]", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():slack(), {floats = 0, min = 0, help = "Value to define slack of the zipline in cm", group = zipline_options})
 	self._type = self:ComboBox("Type", ClassClbk(self, "set_unit_data_parent"), ZipLine.TYPES, table.get_key(ZipLine.TYPES, units[1]:zipline():usage_type()), {group = zipline_options})
	self._ai_ignore_bag = self:Toggle("AIIgnoreBag", ClassClbk(self, "set_unit_data_parent"), units[1]:zipline():ai_ignores_bag(), {text = "AI Ignore Bag", group = zipline_options})
end

function EditZipLine:set_unit_data()
	local unit = self:selected_unit()
	if alive(unit) then
		unit:zipline():set_speed(self._speed:Value())
		unit:zipline():set_slack(self._slack:Value())
		unit:zipline():set_usage_type(self._type:SelectedItem())
		unit:zipline():set_ai_ignores_bag(self._ai_ignore_bag:Value())
		unit:zipline():set_end_pos(self:AxisControlsPosition("EndPos"))
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
	self:SetAxisControls(self:selected_unit():zipline():end_pos(), nil, "EndPos")
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