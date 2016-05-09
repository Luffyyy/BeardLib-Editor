EditorSpawnCivilianGroup = EditorSpawnCivilianGroup or class(MissionScriptEditor)
function EditorSpawnCivilianGroup:init(unit)
	EditorSpawnCivilianGroup.super.init(self, unit)
end

function EditorSpawnCivilianGroup:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnCivilianGroup"	
	self._element.values.random = false
	self._element.values.ignore_disabled = true
	self._element.values.amount = 1
	self._element.values.elements = {}
	self._element.values.team = "default"
end

function EditorSpawnCivilianGroup:_build_panel()
	self:_create_panel()
	self:_build_element_list("elements", {"ElementSpawnCivilian"})
	self:_build_value_checkbox("random", "Select spawn points randomly")
	self:_build_value_checkbox("ignore_disabled", "Select if disabled spawn points should be ignored or not")
	self:_build_value_number("amount", {min = 0}, "Specify amount of civilians to spawn from group")
	self:_build_value_combobox("team", table.list_add({"default"}, tweak_data.levels:get_team_names_indexed()), "Select the group's team (overrides character team).")
end
