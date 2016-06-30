AIAttentionElement = AIAttentionElement or class(MissionScriptEditor)
function AIAttentionElement:create_element()  
	self.super.create_element(self)
	self._nav_link_filter = {}
	self._nav_link_filter_check_boxes = {}
	self._element.class = "ElementAIAttention"
	self._element.values.preset = "none"
	self._element.values.local_pos = nil
	self._element.values.local_rot = nil
	self._element.values.use_instigator = nil
	self._element.values.instigator_ids = {}
	self._element.values.parent_u_id = nil
	self._element.values.parent_obj_name = nil
	self._element.values.att_obj_u_id = nil
	self._element.values.operation = "set"
	self._element.values.override = "none"
	self._parent_unit = nil
	self._parent_obj = nil
	self._att_obj_unit = nil
end
function AIAttentionElement:_build_panel()
	self:_create_panel()
	local names = {
		"ai_spawn_enemy",
		"ai_spawn_civilian",
		"ai_enemy_group",
		"ai_civilian_group"
	}
	self:_build_element_list("instigator_ids", {"ElementSpawnEnemyDummy", "ElementSpawnCivlian", "ElementSpawnEnemyGroup", "ElementSpawnCivlianGroup"})
	self:_build_value_checkbox("use_instigator")
	self:_build_value_combobox("preset", table.list_add({"none"}, tweak_data.attention.indexes), "Select the attention preset.")
	self:_build_value_combobox("operation", {
		"set",
		"add",
		"override"
	}, "Select an operation.")
	self:_build_value_combobox("override", table.list_add({"none"}, tweak_data.attention.indexes), "Select the attention preset to be overriden. (valid only with override operation)")
end
