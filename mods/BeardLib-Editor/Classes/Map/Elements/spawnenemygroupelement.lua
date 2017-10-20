EditorSpawnEnemyGroup = EditorSpawnEnemyGroup or class(MissionScriptEditor)
EditorSpawnEnemyGroup.RANDOMS = {"amount"}
function EditorSpawnEnemyGroup:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnEnemyGroup"
	self._element.values.spawn_type = "ordered"
	self._element.values.ignore_disabled = true
	self._element.values.amount = 0
	self._element.values.elements = {}
	self._element.values.interval = 0
	self._element.values.team = "default"	
end

function EditorSpawnEnemyGroup:post_init(...)
	EditorSpawnEnemyGroup.super.post_init(self, ...)
	if self._element.values.preferred_spawn_groups then
		local i = 1
		while i <= #self._element.values.preferred_spawn_groups do
			if not tweak_data.group_ai.enemy_spawn_groups[self._element.values.preferred_spawn_groups[i]] then
				table.remove(self._element.values.preferred_spawn_groups, i)
			else
				i = i + 1
			end
		end
		if not next(self._element.values.preferred_spawn_groups) then
			self._element.values.preferred_spawn_groups = nil
		end
	end
	if self._element.values.random ~= nil then
		self._element.values.spawn_type = self._element.values.random and "random" or "ordered"
		self._element.values.random = nil
	end
end

function EditorSpawnEnemyGroup:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementSpawnEnemyDummy"})
	self:ComboCtrl("spawn_type", table.list_add({"ordered"}, {"random", "group", "group_guaranteed"}), {help = "Specify how the enemy will be spawned."})
	self:BooleanCtrl("ignore_disabled", {help = "Select if disabled spawn points should be ignored or not"})
	self:NumberCtrl("amount", {floats = 0, min = 0, help = "Specify amount of enemies to spawn from group"})
	self:NumberCtrl("interval", {floats = 0, min = 0, help = "Used to specify how often this spawn can be used. 0 means no interval"})
	self:ComboCtrl("team", table.list_add({"default"}, tweak_data.levels:get_team_names_indexed()), {help = "Select the group's team (overrides character team)."})
	local opt = {}
	for cat_name, team in pairs(tweak_data.group_ai.enemy_spawn_groups) do
		table.insert(opt, cat_name)
	end
	for i, o in ipairs(opt) do
		self._menu:Toggle({
			name = o,
			text = o,
			value = self._element.values.preferred_spawn_groups and table.contains(self._element.values.preferred_spawn_groups, o) or false,
			callback = callback(self, self, "on_preferred_spawn_groups_checkbox_changed"),
		})
	end
end

function EditorSpawnEnemyGroup:on_preferred_spawn_groups_checkbox_changed(menu, item)
	if item.value then
		self._element.values.preferred_spawn_groups = self._element.values.preferred_spawn_groups or {}
		if table.contains(self._element.values.preferred_spawn_groups, item.name) then
			return
		end
		table.insert(self._element.values.preferred_spawn_groups, item.name)
	elseif self._element.values.preferred_spawn_groups then
		table.delete(self._element.values.preferred_spawn_groups, item.name)
		if not next(self._element.values.preferred_spawn_groups) then
			self._element.values.preferred_spawn_groups = nil
		end
	end
end
