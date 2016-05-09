EditorVehicleSpawner = EditorVehicleSpawner or class(MissionScriptEditor)
function EditorVehicleSpawner:init(unit)
	MissionScriptEditor.init(self, unit)
end
function EditorVehicleSpawner:create_element()
	self.super.create_element(self)
	self._element.class = "ElementVehicleSpawner"
	self._element.values.state = VehicleDrivingExt.STATE_INACTIVE
	self._element.values.vehicle = "falcogini"	
end
function EditorVehicleSpawner:_build_panel()
	self:_create_panel()
	local vehicles = {
		"falcogini",
		"escape_van",
		"muscle"
	}
	self:_build_value_combobox("vehicle", vehicles, "Select a vehicle from the combobox")
	self:_add_help_text("The vehicle that will be spawned")
end
