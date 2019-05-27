EditorTeammateComment = EditorTeammateComment or class(MissionScriptEditor)
function EditorTeammateComment:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTeammateComment"
	self._element.values.comment = "none"
	self._element.values.close_to_element = false
	self._element.values.use_instigator = false
	self._element.values.radius = 0
	self._element.values.test_robber = 1
end
 
function EditorTeammateComment:_build_panel()
	self:_create_panel()
	self:ComboCtrl("comment", table.list_add({"none"}, managers.groupai:state().teammate_comment_names), {help = "Select a comment"})
	self:BooleanCtrl("close_to_element", {text = "Play close to element"})
	self:BooleanCtrl("use_instigator", {text = "Play on instigator"})
	self:NumberCtrl("radius", {min = 0, help = "(Optional) Sets a distance to use with the check (in cm)"})
	self:NumberCtrl("test_robber", {min = 0, help = "Can be used to test different robber voice (not saved/loaded)"})
end
 