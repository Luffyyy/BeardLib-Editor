EditorCarry = EditorCarry or class(MissionScriptEditor)
function EditorCarry:create_element()
	self.super.create_element(self)
	self._element.class = "ElementCarry"
	self._element.values.elements = {}
	self._element.values.operation = "secure"
	self._element.values.type_filter = "none" 
end
function EditorCarry:_build_panel()
	self:_create_panel()
	self:ComboCtrl("operation", {
		"remove",
		"freeze",
		"secure",
		"secure_silent",
		"add_to_respawn",
		"filter_only"
	})
	self:ComboCtrl("type_filter", table.list_add({"none"}, tweak_data.carry:get_carry_ids()))
end
