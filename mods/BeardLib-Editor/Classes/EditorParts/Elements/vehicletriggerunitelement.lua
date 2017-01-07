EditorVehicleTrigger = EditorVehicleTrigger or class(MissionScriptEditor)
EditorVehicleTrigger.ON_ENTER = "on_enter"
EditorVehicleTrigger.ON_EXIT = "on_exit"
EditorVehicleTrigger.ON_ALL_INSIDE = "on_all_inside"
EditorVehicleTrigger.events = {
	EditorVehicleTrigger.ON_ENTER,
	EditorVehicleTrigger.ON_EXIT,
	EditorVehicleTrigger.ON_ALL_INSIDE
}
function EditorVehicleTrigger:create_element()
	self.super.create_element(self)
	self._element.class = "ElementVehicleTrigger"
	self._element.values.trigger_times = 1
	self._element.values.event = EditorVehicleTrigger.ON_ENTER
end
function EditorVehicleTrigger:_build_panel()
	self:_create_panel()
	self:ComboCtrl("event", EditorVehicleTrigger.events, {help = "Select an event from the combobox"})
	self:Text("Set the vehicle event the element should trigger on.")
end
