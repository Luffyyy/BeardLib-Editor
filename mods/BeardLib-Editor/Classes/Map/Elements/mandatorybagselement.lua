EditorMandatoryBags = EditorMandatoryBags or class(MissionScriptEditor)
function EditorMandatoryBags:create_element()
    self.super.create_element(self)
  	self._element.class = "ElementMandatoryBags"
	self._element.values.carry_id = "none"
	self._element.values.amount = 0  
end

function EditorMandatoryBags:_build_panel()
	self:_create_panel()
	self:ComboCtrl("carry_id", table.list_add({"none"}, tweak_data.carry:get_carry_ids()))
	self:NumberCtrl("amount", {
		floats = 0,
		min = 0,
		max = 100, 
		help = "Amount of mandatory bags."
	})
end
