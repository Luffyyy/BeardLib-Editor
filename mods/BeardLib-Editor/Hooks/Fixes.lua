if not Global.editor_mode then
	return
end

local F = table.remove(RequiredScript:split("/"))
local UnitIds = Idstring("unit")

local civ = F == "elementspawncivilian"
if civ or F == "elementspawnenemydummy" then
	local C = civ and ElementSpawnCivilian or ElementSpawnEnemyDummy
	--Makes sure unit path is updated.
	Hooks:PostHook(C, "_finalize_values", "EditorFinalizeValues", function(self)
		if self._values.enemy then
			self._enemy_name = self._values.enemy and Idstring(self._values.enemy) or nil
		end
		if not self._enemy_name then
			if civ then
				self._enemy_name = Idstring("units/characters/civilians/dummy_civilian_1/dummy_civilian_1")
			else
				self._enemy_name = Idstring("units/payday2/characters/ene_swat_1/ene_swat_1")
			end
		end 
	end)
	--Makes sure element doesn't crash in editor.
	local orig = C.produce
	function C:produce(params, ...)
		local enemy = self._enemy_name or self:value("enemy")
		if (not params or not params.name) and (not enemy or not PackageManager:has(UnitIds, enemy:id())) then
			return
		end
		return orig(self, params, ...)
	end
end