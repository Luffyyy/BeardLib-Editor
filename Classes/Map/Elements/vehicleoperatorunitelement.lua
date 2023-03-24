EditorVehicleOperator = EditorVehicleOperator or class(MissionScriptEditor)
EditorVehicleOperator.WEIRD_ELEMENTS_VALUE = true
EditorVehicleOperator.ACTIONS = {
	"none",
	"lock",
	"unlock",
	"secure",
	"break_down",
	"repair",
	"damage",
	"activate",
	"deactivate",
	"block",
	"enable_player_exit",
	"disable_player_exit"
}
function EditorVehicleOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementVehicleOperator"
	self._element.values.operation = "none"
	self._element.values.damage = "0"
	self._element.values.elements = {}
end

function EditorVehicleOperator:draw_links()
	EditorVehicleOperator.super.draw_links(self)

	for _, id in pairs(self._element.values.elements) do
		local unit = managers.worlddefinition:get_unit(id)
		if alive(unit) then
			self:draw_link({
				g = 0.75,
				b = 0,
				r = 0,
				from_unit = self._unit,
				to_unit = unit
			})
			Application:draw(unit, 0, 0.75, 0)
		end
	end
end

function EditorVehicleOperator:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("elements", nil, nil, {text = "Manage Vehicles List", check_unit = ClassClbk(self, "check_unit")})
	self:ComboCtrl("operation", EditorVehicleOperator.ACTIONS, {help = "Select an operation for the selected vehicles"})
	self:NumberCtrl("damage", {floats = 0, min = 1, help = "Specify the amount of damage."})
	self:BooleanCtrl("use_instigator")

	self:Text("Choose an operation to perform on the selected vehicles")
end

function EditorVehicleOperator:link_managed(unit)
	if alive(unit) then
		if self:check_unit(unit) and unit:unit_data() then
			self:AddOrRemoveManaged("elements", {unit = unit})
		end
	end
end

function EditorVehicleOperator:check_unit(unit)
	return unit:vehicle_driving()
end
