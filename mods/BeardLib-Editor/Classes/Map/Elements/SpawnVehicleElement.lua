EditorVehicleSpawner = EditorVehicleSpawner or class(MissionScriptEditor)
function EditorVehicleSpawner:create_element()
	self.super.create_element(self)
	self._element.class = "ElementVehicleSpawner"
	self._element.values.state = VehicleDrivingExt.STATE_INACTIVE
	self._element.values.vehicle = "falcogini"	
end

function EditorVehicleSpawner:warn_vehicle()
	local element = managers.mission:get_element_by_id(self._element.id)
	self._class_group:ClearItems("temp")
	if element then
		if element._vehicles and self._element.values.vehicle then
			local unit = element._vehicles[self._element.values.vehicle]
			if self._element.values.vehicle and not PackageManager:has(Idstring("unit"), Idstring(unit)) then
				self:Text("[Warning] Vehicle is not loaded!", {label = "temp"})
				local assets = self:Manager("world")._assets_manager
				if assets then
					self:Button("Fix by loading the vehicle", SimpleClbk(assets.find_package, assets, unit, true), {label = "temp", group = self._class_group})
				end
			end
		end
	end
end

function EditorVehicleSpawner:set_element_data(...)
	EditorVehicleSpawner.super.set_element_data(self, ...)
	self:warn_vehicle()
end

function EditorVehicleSpawner:_build_panel()
	self:_create_panel()
	self:ComboCtrl("vehicle", {"falcogini", "escape_van","muscle"}, {help = "Select a vehicle to spawn from the combobox"})
	self:warn_vehicle()
end