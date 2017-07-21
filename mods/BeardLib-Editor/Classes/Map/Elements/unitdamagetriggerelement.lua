EditorUnitDamage = EditorUnitDamage or class(MissionScriptEditor)
function EditorUnitDamage:create_element(...)
	EditorUnitDamage.super.create_element(self, ...)
	self._element.class = "ElementUnitDamage"
	self._element.values.unit_ids = {}
	self._element.values.damage_types = ""
end

function EditorUnitDamage:update()
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

function EditorUnitDamage:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("unit_ids", nil, nil, {check_unit = function(unit)
		return unit.damage and unit:damage() ~= nil
	end})
	self:StringCtrl("damage_types")
	self:Text([[
CounterOperator elements will use the reported <damage> as the amount to add/subtract/set.
Damage types can be filtered by specifying specific damage types separated by spaces.]])
end