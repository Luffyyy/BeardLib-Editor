if not Global.editor_mode then
	return
end

core:module("CorePortalManager")

function PortalManager:pseudo_reset()
	for _, unit in ipairs(managers.worlddefinition._all_units) do
		if alive(unit) then
			unit:unit_data()._visibility_counter = 0
		end
	end
	for _, group in pairs(self._unit_groups) do
		group._is_inside = false
		for _, unit in ipairs(managers.worlddefinition._all_units) do
			if group._ids[unit:unit_data().unit_id] and alive(unit) then
				unit:set_visible(true)
				unit:unit_data()._visibility_counter = 0
			end
		end
	end
end

function PortalUnitGroup:_change_units_visibility_in_editor(diff)
	for _, unit in ipairs(managers.worlddefinition._all_units) do
		if self._ids[unit:unit_data().unit_id] then
			self:_change_visibility(unit, diff)
		end
	end
end

function PortalUnitGroup:draw(t, dt, mul, skip_shapes, skip_units)
	local r = self._r * mul
	local g = self._g * mul
	local b = self._b * mul
	local brush = Draw:brush()
	brush:set_color(Color(0.25, r, g, b))
	if not skip_units then
		for _, unit in ipairs(managers.worlddefinition._all_units) do
			if self._ids[unit:unit_data().unit_id] then
				brush:unit(unit)
				Application:draw(unit, r, g, b)
			end
		end
	end
	if not skip_shapes then
		for _, shape in ipairs(self._shapes) do
			shape:draw(t, dt, r, g, b)
			shape:draw_outline(t, dt, r / 2, g / 2, b / 2)
		end
	end
end