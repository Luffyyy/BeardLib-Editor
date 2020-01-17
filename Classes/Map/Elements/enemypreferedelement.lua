EditorEnemyPreferedAdd = EditorEnemyPreferedAdd or class(MissionScriptEditor)
EditorEnemyPreferedAdd.SAVE_UNIT_POSITION = false
EditorEnemyPreferedAdd.SAVE_UNIT_ROTATION = false
EditorEnemyPreferedAdd.LINK_ELEMENTS = {
	"spawn_points",
	"spawn_groups"
}
function EditorEnemyPreferedAdd:create_element()
	self.super.create_element(self)
	self._element.class = "ElementEnemyPreferedAdd"
	self._element.values.spawn_groups = {}
	self._element.values.spawn_points = {}
end

function EditorEnemyPreferedAdd:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("spawn_groups", nil, {"ElementSpawnEnemyGroup"})
	self:BuildElementsManage("spawn_points", nil, {"ElementSpawnEnemyDummy"})
end

EditorEnemyPreferedRemove = EditorEnemyPreferedRemove or class(MissionScriptEditor)
function EditorEnemyPreferedRemove:create_element()
	self.super.create_element(self)
	self._element.values.elements = {}
	self._element.class = "ElementEnemyPreferedRemove"
end

function EditorEnemyPreferedRemove:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementEnemyPreferedAdd"})
end