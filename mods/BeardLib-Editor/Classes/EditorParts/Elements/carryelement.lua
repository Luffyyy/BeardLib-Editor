EditorCarry = EditorCarry or class(MissionScriptEditor)
EditorCarry.SAVE_UNIT_POSITION = false
EditorCarry.SAVE_UNIT_ROTATION = false
function EditorCarry:init(unit)
	MissionScriptEditor.init(self, unit)
end
function EditorCarry:create_element()
	self.super.create_element(self)
	self._element.class = "ElementCarry"
	self._element.values.elements = {}
	self._element.values.operation = "secure"
	self._element.values.type_filter = "none" 
end
function EditorCarry:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("operation", {
		"remove",
		"freeze",
		"secure",
		"secure_silent",
		"add_to_respawn",
		"filter_only"
	})
	self:_build_value_combobox("type_filter", table.list_add({"none"}, tweak_data.carry:get_carry_ids()))
end
