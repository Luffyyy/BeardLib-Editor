EditorChangeVanSkin = EditorChangeVanSkin or class(MissionScriptEditor)
function EditorChangeVanSkin:create_element(unit)
	EditorChangeVanSkin.super.create_element(self, unit)
	self._element.class = "ElementChangeVanSkin"
	self._element.values.unit_ids = {}
	self._element.values.target_skin = "default"
end

function EditorChangeVanSkin:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("unit_ids", nil, nil, {check_unit = callback(self, self, "can_select_unit")})
	local tbl = table.map_keys(tweak_data.van.skins)
	table.sort(tbl, function(a, b) return a < b end)
	self:ComboCtrl("target_skin", tbl)
	self:Text("Changes the equipped skin for the escape van, if it is owned. Can be pointed at a van to change the skin immediately.")
end

function EditorChangeVanSkin:can_select_unit(unit)
	local default_sequence = (tweak_data.van.skins[tweak_data.van.default_skin_id] or {}).sequence_name
	return unit and unit.damage and unit:damage() and unit:damage():has_sequence(default_sequence)
end

function EditorChangeVanSkin:update()
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