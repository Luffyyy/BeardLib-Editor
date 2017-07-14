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
	self:PathCtrl("enemy", "unit", 21, {text = "Civilian"})
 	self:ComboCtrl("state", table.list_add(clone(CopActionAct._act_redirects.civilian_spawn), {"none"}))
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