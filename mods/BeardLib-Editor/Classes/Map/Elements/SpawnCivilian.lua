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
function EditorSpawnCivilian:init(unit)
	EditorSpawnCivilian.super.init(self, unit)
	self._enemies = {}
	self._states = CopActionAct._act_redirects.civilian_spawn
end
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
    self:StringCtrl("enemy", {text = "Civilian Unit Path"})
    self:Button("SelectUnitPath", callback(self, SpawnSelect, "OpenSpawnUnitDialog", {
    	slot = 21,
        on_click = function(unit_path)
            self._menu:GetItem("enemy"):SetValue(unit_path, true)
        end,
    }), {group = other})
 	self:ComboCtrl("state", table.list_add(self._states, {"none"}))
	local pickups = table.map_keys(tweak_data.pickups)
	table.insert(pickups, "none")
	self:ComboCtrl("force_pickup", pickups)
	self:ComboCtrl("team", table.list_add({"default"}, tweak_data.levels:get_team_names_indexed()), {help = "Select the character's team."})
end

function EditorSpawnCivilian:_resolve_team(unit)
	if self._element.values.team == "default" then
		return tweak_data.levels:get_default_team_ID("non_combatant")
	else
		return self._element.values.team
	end
end
 
