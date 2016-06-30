EditorSetOutline = EditorSetOutline or class(MissionScriptEditor)
function EditorSetOutline:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSetOutline"
	self._element.values.elements = {}
	self._element.values.set_outline = true
end
function EditorSetOutline:_build_panel()
	self:_create_panel()
	local names = {
		"ai_spawn_enemy",
		"ai_spawn_civilian"
	}
	self:_build_element_list("elements", {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
 	self:_build_value_checkbox("set_outline", nil, "Enable outline")
end
