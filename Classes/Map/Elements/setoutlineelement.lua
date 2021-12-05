EditorSetOutline = EditorSetOutline or class(MissionScriptEditor)
function EditorSetOutline:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSetOutline"
	self._element.values.elements = {}
	self._element.values.set_outline = true
	self._element.values.use_instigator = false
	self._element.values.clear_previous = false
end
function EditorSetOutline:_build_panel()
	self:_create_panel()
	local names = {
		"ai_spawn_enemy",
		"ai_spawn_civilian"
	}
	self:BuildElementsManage("elements", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:BooleanCtrl("set_outline", {text = "Enable outline"})
	self:BooleanCtrl("use_instigator", {text = "Instigator only"})
	self:BooleanCtrl("clear_previous", {text = "Clear previous outlines"})
end
