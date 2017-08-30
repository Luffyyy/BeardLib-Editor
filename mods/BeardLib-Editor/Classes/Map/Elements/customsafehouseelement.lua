EditorCustomSafehouseFilter = EditorCustomSafehouseFilter or class(MissionScriptEditor)
function EditorCustomSafehouseFilter:create_element(...)
	EditorCustomSafehouseFilter.super.create_element(self, ...)
	self._element.class = "ElementCustomSafehouseFilter"
	self._element.values.room_id = tweak_data.safehouse.rooms[1].room_id
	self._element.values.room_tier = "1"
	self._element.values.tier_check = "current"
	self._element.values.check_type = "equal"
end

function EditorCustomSafehouseFilter:_build_panel()
	self:_create_panel()
	if not self._character_rooms then
		self._character_rooms = {}
		for idx, room in ipairs(tweak_data.safehouse.rooms) do
			table.insert(self._character_rooms, room.room_id)
		end
	end
	self._character_box = self:ComboCtrl("room_id", self._character_rooms, {help = "Select a room from the combobox"})

	local tiers = {}
	for i = 1, #tweak_data.safehouse.prices.rooms do
		table.insert(tiers, tostring(i))
	end
	self._tier_box = self:ComboCtrl("room_tier", tiers, {help = "Select a tier from the combobox"})
	self:ComboCtrl("tier_check", {"current", "highest_unlocked"}, {help = "Select which tier operation to perform"})
	self:ComboCtrl("check_type", {
		"equal",
		"less_than",
		"greater_than",
		"less_or_equal",
		"greater_or_equal"
	}, {help = "Select which check operation to perform"})
	self:Text("Will only execute if the current/highest unlocked tier of the characters room is <operator> the specified tier.")
end

function EditorCustomSafehouseFilter:set_element_data(menu, item)
	EditorCustomSafehouseFilter.super.set_element_data(self, menu, item)
	if item.name == "room_id" then
		local current_selection = self._tier_box:Value()
		local num_tiers = managers.custom_safehouse:get_room_max_tier(self._character_box:SelectedItem())
		local tiers = {}
		for i = 1, num_tiers do
			table.insert(tiers, i)
		end
		self._tier_box:SetItems(tiers)
		self._tier_box:SetValue(math.clamp(current_selection, 0, num_tiers))
	end
end

EditorCustomSafehouseTrophyFilter = EditorCustomSafehouseTrophyFilter or class(MissionScriptEditor)
function EditorCustomSafehouseTrophyFilter:create_element(...)
	EditorCustomSafehouseTrophyFilter.super.create_element(self, ...)
	self._element.class = "ElementCustomSafehouseTrophyFilter"
	self._element.values.trophy = ""
	self._element.values.check_type = "unlocked"
end

function EditorCustomSafehouseTrophyFilter:_build_panel()
	self:_create_panel()
	if not self._trophy_ids then
		self._trophy_ids = {}
		for idx, trophy in ipairs(tweak_data.safehouse.trophies) do
			table.insert(self._trophy_ids, trophy.id)
		end
	end
	self:ComboCtrl("trophy", self._trophy_ids)
	self:ComboCtrl("check_type", {"unlocked", "locked"}, {help = "Check if the trophy is unlocked or locked"})
end

EditorCustomSafehouseAwardTrophy = EditorCustomSafehouseAwardTrophy or class(MissionScriptEditor)
function EditorCustomSafehouseAwardTrophy:create_element(...)
	EditorCustomSafehouseAwardTrophy.super.create_element(self, ...)
	self._element.class = "ElementCustomSafehouseAwardTrophy"
	self._element.values.trophy = ""
	self._element.values.objective_id = ""
	self._element.values.award_instigator = false
	self._element.values.players_from_start = nil
end

function EditorCustomSafehouseAwardTrophy:_build_panel()
	self:_create_panel()
	if not self._trophy_ids then
		self._trophy_ids = {}
		for idx, trophy in ipairs(tweak_data.safehouse.trophies) do
			table.insert(self._trophy_ids, trophy.id)
		end
		for idx, trophy in ipairs(tweak_data.safehouse.dailies) do
			table.insert(self._trophy_ids, trophy.id)
		end
	end
	local objectives = {"select a trophy"}
	if self._element.values.trophy then
		local id = self._element.values.trophy
		local trophy = managers.custom_safehouse:get_trophy(id) or managers.custom_safehouse:get_daily(id)
		if trophy then
			objectives = {}
			for idx, objective in ipairs(trophy.objectives) do
				table.insert(objectives, objective.achievement_id or objective.progress_id)
			end
		end
	end
	self._trophy_box = self:ComboCtrl("trophy", self._trophy_ids, {help = "Select a trophy from the combobox"})
	self._objective_box = self:ComboCtrl("objective_id", objectives, {help = "Select a trophy objective from the combobox"})
	self:BooleanCtrl("award_instigator", {help = "Award only the instigator (Player or driver in vehicle)?"})
	self:BooleanCtrl("players_from_start", {help = "Only award to players that joined from start."})
	self:Text("Awards a Safehouse Trophy")
end

function EditorCustomSafehouseAwardTrophy:set_element_data(menu, item)
	EditorCustomSafehouseAwardTrophy.super.set_element_data(self, menu, item)
	if item.name == "trophy" then
		local id = self._trophy_box:Value()
		local trophy = managers.custom_safehouse:get_trophy(id) or managers.custom_safehouse:get_daily(id)
		local objectives = {}
		for idx, objective in ipairs(trophy.objectives) do
			table.insert(objective.achievement_id or objective.progress_id)
		end
		self._objective_box:SetItems(objectives)
		self._objective_box:SetValue(1)
	end
end