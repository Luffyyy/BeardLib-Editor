EditorAIArea = EditorAIArea or class(MissionScriptEditor)
EditorAIArea.SAVE_UNIT_ROTATION = false
function EditorAIArea:create_element()
	EditorAIArea.super.create_element(self)
	self._element.class = "ElementAIArea"
	self._element.values.nav_segs = {}
end

function EditorAIArea:draw_links()
	EditorAIArea.super.draw_links(self)
	for _, id in pairs(self._element.values.nav_segs) do
		local unit = managers.worlddefinition:get_unit(id)
		if alive(unit) then
			self:draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0,
				g = 0.75,
				b = 0
			})
		else
			table.delete(self._element.values.nav_segs, id)
			return
		end
	end
end

function EditorAIArea:_build_panel()
	self:_create_panel()
	self._element.values.nav_segs = self._element.values.nav_segs or {}
	self:BuildUnitsManage("nav_segs", nil, nil, {text = "Navigation Surfaces", units = {"core/units/nav_surface/nav_surface"}})
end