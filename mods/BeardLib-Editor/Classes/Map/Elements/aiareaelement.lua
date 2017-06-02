EditorAIArea = EditorAIArea or class(MissionScriptEditor)
EditorAIArea.SAVE_UNIT_ROTATION = false
function EditorAIArea:create_element()
	EditorAIArea.super.create_element(self)
	self._element.class = "ElementAIArea"
	self._element.values.nav_segs = {}
	self._nav_seg_units = {}
end

function EditorAIArea:layer_finished()
	EditorAIArea.super.layer_finished(self)
	if not self._element.values.nav_segs then
		return
	end
	for _, u_id in ipairs(self._element.values.nav_segs) do
		local unit = managers.worlddefinition:get_unit_on_load(u_id, callback(self, self, "load_nav_seg_unit"))
		if unit then
			self._nav_seg_units[u_id] = unit
		end
	end
end

function EditorAIArea:load_nav_seg_unit(unit)
	self._nav_seg_units[unit:unit_data().unit_id] = unit
end

function EditorAIArea:draw_links(t, dt, selected_unit, all_units)
	EditorAIArea.super.draw_links(self, t, dt, selected_unit)
	if selected_unit and self._unit ~= selected_unit and not self._nav_seg_units[selected_unit:unit_data().unit_id] then
		return
	end
	for u_id, unit in pairs(self._nav_seg_units) do
		self:draw_link({
			from_unit = self._unit,
			to_unit = unit,
			r = 0,
			g = 0.75,
			b = 0
		})
	end
end

function EditorAIArea:_build_panel()
	self:_create_panel()
	self._element.values.nav_segs = self._element.values.nav_segs or {}
	self:Button("SelectNavSurfacesForArea", callback(self, self, "OpenUnitsManageDialog", {value_name = "nav_segs", units = {"core/units/nav_surface/nav_surface"}}), {group = self._class_group})
end

function EditorAIArea:_chk_units_alive()
	for u_id, unit in pairs(self._nav_seg_units) do
		if not alive(unit) then
			self._nav_seg_units[u_id] = nil
			self:_remove_nav_seg(u_id)
		end
	end
end
