EditorCharacterSequence = EditorCharacterSequence or class(MissionScriptEditor)
function EditorCharacterSequence:create_element()
	EditorCharacterSequence.super.create_element(self)
	self._element.class = "ElementCharacterSequence"
	self._element.values.elements = {}
	self._element.values.sequence = ""
end

function EditorCharacterSequence:draw_links()
	EditorCharacterSequence.super.draw_links(self)
	local selected_unit = self:selected_unit()
	for _, id in ipairs(self._element.values.elements) do
		local unit = self:Manager("mission"):get_element_unit(id)
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0,
				g = 0.75,
				b = 0
			})
		end
	end
end

function EditorCharacterSequence:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:BooleanCtrl("use_instigator")
	self:StringCtrl("sequence")
end