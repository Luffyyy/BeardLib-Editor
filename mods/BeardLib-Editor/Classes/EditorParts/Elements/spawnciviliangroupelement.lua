EditorSpawnCivilianGroup = EditorSpawnCivilianGroup or class(MissionScriptEditor)
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
	self:BuildElementsManage("elements", nil, {"ElementSpawnCivilian"})
	self:BooleanCtrl("random", {text = "Select spawn points randomly"})
	self:BooleanCtrl("ignore_disabled", {help = "Select if disabled spawn points should be ignored or not"})
	self:NumberCtrl("amount", {min = 0, help = "Specify amount of civilians to spawn from group"})
	self:ComboCtrl("team", table.list_add({"default"}, tweak_data.levels:get_team_names_indexed()), {help = "Select the group's team (overrides character team)."})
end
