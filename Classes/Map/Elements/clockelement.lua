EditorClock = EditorClock or class(MissionScriptEditor)
EditorClock.HOUR_COLOR = Color(0.34901960784313724, 0.16470588235294117, 0.44313725490196076)
EditorClock.MINUTE_COLOR = Color(0.47843137254901963, 0.6196078431372549, 0.20784313725490197)
EditorClock.SECOND_COLOR = Color(0.6666666666666666, 0.592156862745098, 0.2235294117647059)

function EditorClock:create_element()
	self.super.create_element(self)
	self._element.class = "ElementClock"
	self._element.values.modify_on_activate = true
	self._element.values.hour_elements = {}
	self._element.values.minute_elements = {}
	self._element.values.second_elements = {}
end

function EditorClock:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("modify_on_activate", {text = "Modify Elements On Enabled", help = "Should this element modify logic_counter elements on startup"})
	self:BuildElementsManage("hour_elements", nil, {"ElementCounter"})
	self:BuildElementsManage("minute_elements", nil, {"ElementCounter"})
	self:BuildElementsManage("second_elements", nil, {"ElementCounter"})
	self:Text("This element can modify logic_counter elements using set operation when time changes. Select counters to modify using insert and clicking on the elements.")
end

function EditorClock:draw_links(t, dt, selected_unit, selected_units)
	EditorClock.super.draw_links(self, t, dt, selected_unit)
	self:_draw_clock_elements(self._element.values.hour_elements, self.HOUR_COLOR, selected_unit)
	self:_draw_clock_elements(self._element.values.minute_elements, self.MINUTE_COLOR, selected_unit)
	self:_draw_clock_elements(self._element.values.second_elements, self.SECOND_COLOR, selected_unit)
end

function EditorClock:_draw_clock_elements(elements, color, selected_unit)
	for _, id in ipairs(elements) do
		local unit = self:GetPart("mission"):get_element_unit(id)
		if not alive(unit) then
			table.delete(elements, id)
		else
			local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
			if draw then
				self:draw_link({
					from_unit = self._unit,
					to_unit = unit,
					r = color.r,
					g = color.g,
					b = color.b
				})
			end
		end
	end
end
