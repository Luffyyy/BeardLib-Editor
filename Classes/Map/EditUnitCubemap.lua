EditUnitCubemap = EditUnitCubemap or class(EditUnit)
EditUnitCubemap.CUBEMAP_UNIT = "core/units/cubemap_gizmo/cubemap_gizmo"
EditUnitCubemap.DEFAULT_CUBEMAP_RESOLUTION = 512
function EditUnitCubemap:editable(unit)	
	return self.super.editable(self, unit) and unit:name() == EditUnitCubemap.CUBEMAP_UNIT:id() 
end

function EditUnitCubemap:build_menu(units)
	local cubemap_options = self:group("Cubemap")
	local res = {
		128,
		256,
		512,
		1024,
		2048
	}
	self._cubemap_resolution = cubemap_options:combobox("CubemapResolution", ClassClbk(self, "set_unit_data_parent"), res, 3, {help = "Select a resolution from the combobox"})
end

function EditUnitCubemap:set_unit_data()	
	local unit = self:selected_unit()
	local ud = unit:unit_data()
	ud.cubemap_resolution = self._cubemap_resolution:SelectedItem()
	self:update_cubemap()
	log("cont:" ..tostring(ud.continent))
	log("uid:" ..tostring(ud.unit_id))
end

function EditUnitCubemap:update_cubemap()	
	local unit = self:selected_unit()
	local ud = unit:unit_data()
	local res = ud.cubemap_resolution or EditUnitCubemap.DEFAULT_CUBEMAP_RESOLUTION
	self._cubemap_resolution:SetSelectedItem(res)
end

function EditUnitCubemap:set_menu_unit(units) self:update_cubemap() end