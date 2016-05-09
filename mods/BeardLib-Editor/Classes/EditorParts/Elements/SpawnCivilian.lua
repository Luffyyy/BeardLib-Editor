core:import("CoreEditorUtils")
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
EditorSpawnCivilian._options = {}
for _, dlc in pairs(tweak_data.character:character_map()) do
	for _, character in pairs(dlc.list) do
		local character_path =  dlc.path .. character .. "/" .. character
		if character:match("civ") and PackageManager:has(Idstring("unit"), Idstring(character_path)) then
			table.insert(EditorSpawnCivilian._options, character_path)
		end
	end
end
function EditorSpawnCivilian:init(unit)
	EditorSpawnCivilian.super.init(self, unit)
	self._enemies = {}
	self._states = CopActionAct._act_redirects.civilian_spawn
end
function EditorSpawnCivilian:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnCivilian"
	self._element.values.state = "none"
	self._element.values.enemy = "units/payday2/characters/civ_male_casual_1/civ_male_casual_1"
	self._element.values.force_pickup = "none"
	self._element.values.team = "default"
end
function EditorSpawnCivilian:post_init(...)
	EditorSpawnCivilian.super.post_init(self, ...)
end
function EditorSpawnCivilian:set_element_data(params, ...)
	EditorSpawnCivilian.super.set_element_data(self, params, ...)
end
 
function EditorSpawnCivilian:_build_panel()
	self:_create_panel()
	self._options = {}
	self:_build_value_combobox("enemy", self._options, nil, nil)
 	self:_build_value_combobox("state", table.list_add(self._states, {"none"}))
	local pickups = table.map_keys(tweak_data.pickups)
	table.insert(pickups, "none")
	self:_build_value_combobox("force_pickup", pickups)
	self:_build_value_combobox("team", table.list_add({"default"}, tweak_data.levels:get_team_names_indexed()), "Select the character's team.")
end

function EditorSpawnCivilian:_resolve_team(unit)
	if self._element.values.team == "default" then
		return tweak_data.levels:get_default_team_ID("non_combatant")
	else
		return self._element.values.team
	end
end
 
