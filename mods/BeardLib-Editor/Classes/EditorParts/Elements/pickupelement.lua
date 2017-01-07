EditorPickup = EditorPickup or class(MissionScriptEditor)
function EditorPickup:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPickup"
    self._element.values.pickup = "remove"    
end

function EditorPickup:_build_panel()
	self:_create_panel()
	self:ComboCtrl("pickup", table.list_add({"remove"}, table.map_keys(tweak_data.pickups)), {help = "Select a pickup to be set or remove."})
end
