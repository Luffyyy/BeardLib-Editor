EditorInvulnerable = EditorInvulnerable or class(MissionScriptEditor)
function EditorInvulnerable:create_element(...)
	EditorInvulnerable.super.create_element(self, ...)
	self._element.class = "ElementInvulnerable"
	self._element.values.invulnerable = true
	self._element.values.immortal = false
	self._element.values.elements = {}
end

function EditorInvulnerable:draw_links()
	EditorInvulnerable.super.draw_links(self)
	local selected_unit = self:selected_unit()
	for _, id in ipairs(self._element.values.elements) do
		local unit = self:Manager("mission"):get_element_unit(id)
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

function EditorInvulnerable:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {
		"ElementSpawnEnemyDummy",
		"ElementSpawnEnemyGroup",
		"ElementSpawnCivilian",
		"ElementSpawnCivilianGroup",
		"ElementSpawnPlayer"
	})
	self:BooleanCtrl("invulnerable")
	self:BooleanCtrl("immortal")
	self:Text("Makes a unit invulnerable or immortal.")
end