EditorEnemyPreferedAdd = EditorEnemyPreferedAdd or class(MissionScriptEditor)
function EditorEnemyPreferedAdd:create_elment()
	self.super.create_elment(self)
	self._element.class = "ElementEnemyPreferedAdd"
	self._element.values.spawn_groups = {}
	--self._element.values.spawn_points = {}
end

function EditorEnemyPreferedAdd:_build_panel()
	self:_create_panel()
	self:_build_element_list("spawn_groups", {"ElementSpawnEnemyGroup"})
end
EditorEnemyPreferedRemove = EditorEnemyPreferedRemove or class(MissionScriptEditor)
function EditorEnemyPreferedRemove:create_elment()
	self.super.create_elment(self)
	self._element.values.elements = {}
	self._element.class = "ElementEnemyPreferedRemove"
end
function EditorEnemyPreferedRemove:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementEnemyPreferedAdd"})
end
