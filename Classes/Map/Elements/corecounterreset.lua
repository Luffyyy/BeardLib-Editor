EditorCounterReset = EditorCounterReset or class(MissionScriptEditor)
EditorCounterReset.LINK_ELEMENTS = {"elements"}
function EditorCounterReset:create_element(...)
	EditorCounterReset.super.create_element(self, ...)
	self._element.class = "ElementCounterReset"
	self._element.values.counter_target = 1
	self._element.values.elements = {}
end

function EditorCounterReset:draw_links(...)
	EditorCounterReset.super.draw_links(self, ...)
	local selected_unit = self:selected_unit()
	for _, id in ipairs(self._element.values.elements) do
		local unit = self:GetPart("mission"):get_element_unit(id)
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:draw_link({
				g = 0,
				b = 0,
				r = 0.75,
				from_unit = self._unit,
				to_unit = unit
			})
		end
	end
end

function EditorCounterReset:_build_panel(panel, panel_sizer)
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementCounter"})
	self:NumberCtrl("counter_target", {min = 0, floats = 0})
end