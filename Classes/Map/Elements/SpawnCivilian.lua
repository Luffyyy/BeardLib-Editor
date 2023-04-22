core:import("CoreUnit")
EditorSpawnCivilian = EditorSpawnCivilian or class(MissionScriptEditor)
EditorSpawnCivilian.USES_POINT_ORIENTATION = true
EditorSpawnCivilian.INSTANCE_VAR_NAMES = {
	{type = "civilian", value = "enemy"},
	{
		type = "civilian_spawn_state",
		value = "state"
	}
}
EditorSpawnCivilian._enemies = {}
function EditorSpawnCivilian:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnCivilian"
	self._element.values.state = "none"
	self._element.values.enemy = ""
	self._element.values.force_pickup = "none"
	self._element.values.team = "default"
end

function EditorSpawnCivilian:_build_panel()
	self:_create_panel()
	self:PathCtrl("enemy", "unit", '/civ_', "dummy_corpse", {
		text = "Civilian",
		extra_info = {load = true}
	})
	self:ComboCtrl("state", table.list_add(clone(CopActionAct._act_redirects.civilian_spawn), {"none"}), {
		not_close = true, 
        searchbox = true, 
        fit_text = true, 
        on_callback = function(item) 
            self:set_element_data(item)
            self:test_element(item)
        end, 
        close_callback = ClassClbk(self, "stop_test_element")
	})
	local pickups = table.map_keys(tweak_data.pickups)
	table.insert(pickups, "none")
	self:ComboCtrl("force_pickup", pickups)
	self:ComboCtrl("team", table.list_add({"default"}, tweak_data.levels:get_team_names_indexed()), {help = "Select the character's team."})
end

function EditorSpawnCivilian:test_element()
	EditorSpawnEnemyDummy.test_element(self)
end

function EditorSpawnCivilian:stop_test_element()
    EditorSpawnEnemyDummy.stop_test_element(self)
end

function EditorSpawnCivilian:get_spawn_anim()
    return self._element.values.state
end

function EditorSpawnCivilian:_resolve_team(unit)
	if self._element.values.team == "default" then
		return tweak_data.levels:get_default_team_ID("non_combatant")
	else
		return self._element.values.team
	end
end

local unit_ids = Idstring("unit")
function EditorSpawnCivilian:set_element_data(item, ...)
	if item.name == "force_pickup" then
		local assets = self:GetPart("assets")
		local id = item:SelectedItem()
		local typ = "unit"
		if assets and not (id == "none" or id == "no_pickup") then
			local unit = tweak_data.pickups[id].unit
			local path = BLE.Utils:Unhash(unit, typ)

			if path and not assets:is_asset_loaded(typ, path) then
				assets:quick_load_from_db(typ, path, nil, nil, {load = true})
			end
		end
	end
	EditorSpawnCivilian.super.set_element_data(self, item, ...)
end