EditorAIForceAttentionOperator = EditorAIForceAttentionOperator or class(MissionScriptEditor)
function EditorAIForceAttentionOperator:create_element(...)
	EditorAIForceAttentionOperator.super.create_element(self, ...)
	self._element.class = "ElementAIForceAttentionOperator"
	self._element.values.operation = "disable"
end

function EditorAIForceAttentionOperator:_build_panel()
	self:_create_panel()
	self:Text("Controls an 'AI force attention' element.")
	self:BuildElementsManage("element_id", nil, {"ElementAIForceAttention"}, {single_select = true, text = "Operating on"})
	self:ComboCtrl("operation", {"disable"})
end