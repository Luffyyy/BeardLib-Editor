EditorTeammateComment = EditorTeammateComment or class(MissionScriptEditor)
function EditorTeammateComment:init(unit)
	EditorTeammateComment.super.init(self, unit)
end
function EditorTeammateComment:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTeammateComment"
	self._element.values.comment = "none"
	self._element.values.close_to_element = false
	self._element.values.use_instigator = false
	self._element.values.radius = 0
	self._element.values.test_robber = 1
end
function EditorTeammateComment:post_init(...)
	EditorTeammateComment.super.post_init(self, ...)
end
 
function EditorTeammateComment:_build_panel()
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	self:_build_value_combobox("comment", table.list_add({"none"}, managers.groupai:state().teammate_comment_names), "Select a comment")
	self:_build_value_checkbox("close_to_element", "", nil, "Play close to element")
	self:_build_value_checkbox("use_instigator", "", nil, "Play on instigator")
	self:_build_value_number("radius", {min = 0}, "(Optional) Sets a distance to use with the check (in cm)")
	self:_build_value_number("test_robber", {min = 0}, "Can be used to test different robber voice (not saved/loaded)")
end
 