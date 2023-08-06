EditorCharacterDamage = EditorCharacterDamage or class(MissionScriptEditor)
EditorCharacterDamage.ELEMENT_FILTER = {"ElementSpawnEnemyDummy","ElementSpawnEnemyGroup","ElementSpawnCivilian","ElementSpawnCivilianGroup","ElementPlayerSpawner"}
function EditorCharacterDamage:create_element(...)
	EditorCharacterDamage.super.create_element(self, ...)
	self._element.class = "ElementCharacterDamage"
	self._element.values.elements = {}
	self._element.values.damage_types = ""
	self._element.values.percentage = false
end

function EditorCharacterDamage:_build_panel()
	self:_create_panel()
	self:StringCtrl("damage_types")
	self:BooleanCtrl("percentage")
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
	self:Text([[
ElementCounterOperator elements will use the reported <damage> as the amount to add/subtract/set.
Damage types can be filtered by specifying specific damage types separated by spaces.]])
end
