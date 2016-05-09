EditorMandatoryBags = EditorMandatoryBags or class(MissionScriptEditor)
EditorMandatoryBags.SAVE_UNIT_POSITION = false
EditorMandatoryBags.SAVE_UNIT_ROTATION = false
function EditorMandatoryBags:init(unit)
	EditorMandatoryBags.super.init(self, unit)
end

function EditorMandatoryBags:create_element()
    self.super.create_element(self)
  	self._element.class = "ElementMandatoryBags"
	self._element.values.carry_id = "none"
	self._element.values.amount = 0  
end

function EditorMandatoryBags:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("carry_id", table.list_add({"none"}, tweak_data.carry:get_carry_ids()))
	self:_build_value_number("amount", {
		floats = 0,
		min = 0,
		max = 100
	}, "Amount of mandatory bags.")
end
