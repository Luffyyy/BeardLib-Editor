EditorDisableShout = EditorDisableShout or class(MissionScriptEditor)
function EditorDisableShout:init(unit)
	EditorDisableShout.super.init(self, unit)
end
function EditorDisableShout:create_element()
    self.super.create_element(self)
	self._element.class = "ElementDisableShout"
	self._element.values.elements = {}
	self._element.values.disable_shout = true
end
function EditorDisableShout:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementSpawnCivilian", "ElementSpawnEnemyDummy"})
	self:_build_value_checkbox("disable_shout", "", "Disable shout")
end
 