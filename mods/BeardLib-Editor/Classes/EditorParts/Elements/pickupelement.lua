EditorPickup = EditorPickup or class(MissionScriptEditor)
EditorPickup.SAVE_UNIT_POSITION = false
EditorPickup.SAVE_UNIT_ROTATION = false
function EditorPickup:init(unit)
	MissionScriptEditor.init(self, unit)
end

function EditorPickup:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPickup"
    self._element.values.pickup = "remove"    
end

function EditorPickup.get_options()
	return table.map_keys(tweak_data.pickups)
end
function EditorPickup:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("pickup", table.list_add({"remove"}, table.map_keys(tweak_data.pickups)), "Select a pickup to be set or remove.")
end
