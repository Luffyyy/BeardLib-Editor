EditorTangoAward  = EditorTangoAward or class(MissionScriptEditor)

function EditorTangoAward:create_element()
	EditorTangoAward.super.create_element(self)

	self._element.class = "ElementTangoAward"
	self._element.values.challenge = ""
	self._element.values.objective_id = ""
	self._element.values.award_instigator = false
	self._element.values.players_from_start = nil
end

function EditorTangoAward:_build_panel()
	self:_create_panel()

	if not self._challenge_ids then
		self._challenge_ids = {}

		for idx, challenge in ipairs(tweak_data.tango.challenges) do
			table.insert(self._challenge_ids, challenge.id)
		end
	end

	self._challenge_box = self:ComboCtrl("challenge", self._challenge_ids, {help = "Select a challenge from the combobox"})
	PrintT(self:get_objectives())
	self._objective_box = self:ComboCtrl("objective_id", self:get_objectives(), {help = "Select a challenge objective from the combobox"})

	self:BooleanCtrl("award_instigator", {help = "Award only the instigator (Player or driver in vehicle)?"})
	self:BooleanCtrl("players_from_start", {help = "Only award to players that joined from start."})
	self:Text("Awards a weapon-part objective from the Gage Spec Ops (Tango) DLC.")
end

function EditorTangoAward:set_element_data(item)
	EditorTangoAward.super.set_element_data(self, item)

	if item == self._challenge_box then
		self._objective_box:SetItems(self:get_objectives())
		self._objective_box:SetValue(1, true)
	end
end

function EditorTangoAward:get_objectives()
	local objectives = {}
	local id = self._element.values.challenge
	if id then
		local challenge = managers.tango:get_challenge(id)

		if challenge then
			for idx, objective in ipairs(challenge.objectives) do
				table.insert(objectives, objective.progress_id)
			end
		end
	end
	return objectives
end

EditorTangoFilter = EditorTangoFilter or class(MissionScriptEditor)

function EditorTangoFilter:create_element()
	EditorTangoFilter.super.create_element(self)
	
	self._element.class = "ElementTangoFilter"
	self._element.values.challenge = ""
	self._element.values.objective_id = ""
	self._element.values.check_type = "unlocked"
end

function EditorTangoFilter:_build_panel()
	self:_create_panel()

	if not self._challenge_ids then
		self._challenge_ids = {}

		for idx, challenge in ipairs(tweak_data.tango.challenges) do
			table.insert(self._challenge_ids, challenge.id)
		end
	end

	local objectives = EditorTangoAward.get_objectives(self)
	table.insert(objectives, 1, "all")

	self._challenge_box = self:ComboCtrl("challenge", self._challenge_ids, {help = "Select a challenge from the combobox"})
	self._objective_box = self:ComboCtrl("objective_id", objectives, {help = "Select a challenge objective from the combobox"})
	self:ComboCtrl("check_type", {"complete", "incomplete"}, {help = "Check if the challenge is completed or incomplete"})
end

function EditorTangoFilter:set_element_data(item)
	EditorTangoFilter.super.set_element_data(self, item)

	if item == self._challenge_box then
		local objectives = EditorTangoAward.get_objectives(self)
		table.insert(objectives, 1, "all")
		self._objective_box:SetItems(objectives)
		self._objective_box:SetValue(1, true)
	end
end