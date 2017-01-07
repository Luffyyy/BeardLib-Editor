EditorEquipment = EditorEquipment or class(MissionScriptEditor)
function EditorEquipment:create_element()
    self.super.create_element(self)
    self._element.class = "ElementEquipment"
    self._element.values.equipment = "none"
    self._element.values.amount = 1 
end
function EditorEquipment:_build_panel()
	self:_create_panel()
	self:ComboCtrl("equipment", table.list_add({"none"}, table.map_keys(tweak_data.equipments.specials)))
    self:NumberCtrl("amount", {floats = 0, min = 1, help = "Specifies how many of this equipment to recieve (only work on those who has a max_amount set in their tweak data)."})
end
