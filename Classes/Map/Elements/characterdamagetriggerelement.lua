EditorCharacterDamage = EditorCharacterDamage or class(MissionScriptEditor)
function EditorCharacterDamage:create_element(...)
	EditorCharacterDamage.super.create_element(self, ...)
	self._element.class = "ElementCharacterDamage"
	self._element.values.elements = {}
	self._element.values.damage_types = ""
	self._element.values.percentage = false
end

function EditorCharacterDamage:draw_links()
	EditorCharacterDamage.super.draw_links(self)
	local selected_unit = self:selected_unit()
	for _, id in ipairs(self._element.values.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:draw_link({
				from_unit = unit,
				to_unit = self._unit,
				r = 0,
				g = 0.85,
				b = 0
			})
		end
	end
end

function EditorCharacterDamage:_build_panel()
	self:_create_panel()
	self:StringCtrl("damage_types")
	self:BooleanCtrl("percentage")
	self:BuildElementsManage("elements", nil, {
		"ElementSpawnEnemyDummy",
		"ElementSpawnEnemyGroup",
		"ElementSpawnCivilian",
		"ElementSpawnCivilianGroup",
		"ElementSpawnPlayer"
	}, {text = "Operating on"})
	self:Text([[
ElementCounterOperator elements will use the reported <damage> as the amount to add/subtract/set.
Damage types can be filtered by specifying specific damage types separated by spaces.]])
end
