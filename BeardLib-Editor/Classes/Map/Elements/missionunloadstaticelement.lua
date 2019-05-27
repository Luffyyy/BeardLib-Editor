EditorUnloadStatic = EditorUnloadStatic or class(MissionScriptEditor)
EditorUnloadStatic.SAVE_UNIT_POSITION = false
EditorUnloadStatic.SAVE_UNIT_ROTATION = false
function EditorUnloadStatic:create_element(...)
	EditorUnloadStatic.super.create_element(self, ...)
	self._element.class = "ElementUnloadStatic"
	self._element.values.unit_ids = {}
end

function EditorUnloadStatic:update_selected()
	for _, id in pairs(self._element.values.unit_ids) do
		local unit = managers.worlddefinition:get_unit(id)
		if alive(unit) then
			self:draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 1,
				g = 0,
				b = 1
			})
			Application:draw(unit, 1, 0, 1)
		else
			table.delete(self._element.values.unit_ids, id)
			return
		end
	end
end

function EditorUnloadStatic:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("unit_ids")
end