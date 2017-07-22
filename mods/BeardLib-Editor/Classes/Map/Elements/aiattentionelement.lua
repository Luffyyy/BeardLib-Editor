EditorAIAttention = EditorAIAttention or class(MissionScriptEditor)
function EditorAIAttention:create_element()  
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
function EditorAIAttention:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("instigator_ids", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian", "ElementSpawnEnemyGroup", "ElementSpawnCivilianGroup"})
	self:BooleanCtrl("use_instigator")
	self:ComboCtrl("preset", table.list_add({"none"}, tweak_data.attention.indexes), {help = "Select the attention preset."})
	self:ComboCtrl("operation", {"set","add","override"}, {help = "Select an operation."})
	self:ComboCtrl("override", table.list_add({"none"}, tweak_data.attention.indexes), {help = "Select the attention preset to be overriden. (valid only with override operation)"})
end