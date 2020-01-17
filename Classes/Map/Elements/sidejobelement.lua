EditorSideJobAward = EditorSideJobAward or class(MissionScriptEditor)

function EditorSideJobAward:create_element()
	EditorSideJobAward.super.create_element(self)

	self._element.class = "ElementSideJobAward"
	self._element.values.challenge = ""
	self._element.values.objective_id = ""
	self._element.values.award_instigator = false
	self._element.values.players_from_start = nil
end

function EditorSideJobAward:_build_panel()
	self:_create_panel()

	if not self._challenge_ids then
		self._challenge_ids = {}

		for _, side_job_dlc in ipairs(managers.generic_side_jobs:side_jobs()) do
			for idx, challenge in ipairs(side_job_dlc.manager:challenges()) do
				table.insert(self._challenge_ids, challenge.id)
			end
		end
	end

	local objectives = {"all"}

	if self._element.values.challenge then
		local id = self._element.values.challenge
		local challenge = managers.generic_side_jobs:get_challenge(id)

		if challenge then
			for idx, objective in ipairs(challenge.objectives) do
				table.insert(objectives, objective.progress_id)
			end
		end
	end

	self._challenge_box = self:ComboCtrl("challenge", self._challenge_ids, {help = "Select a challenge from the combobox"})
	self._objective_box = self:ComboCtrl("objective_id", objectives, {help = "Select a challenge objective from the combobox"})

	self._objective_box:set_value(self._element.values.objective_id)
	self:BooleanCtrl("award_instigator", {help = "Award only the instigator (Player or driver in vehicle)?"})
	self:BooleanCtrl("players_from_start", {help = "Only award to players that joined from start."})
	self:Text("Awards an objective from any DLC that uses generic side jobs.")
end

function EditorSideJobAward:set_element_data(data)
	EditorSideJobAward.super.set_element_data(self, data)

	if data.ctrlr == self._challenge_box then
		local id = self._challenge_box:get_value()
		local challenge = managers.generic_side_jobs:get_challenge(id)

		self._objective_box:Clear()

		for idx, objective in ipairs(challenge.objectives) do
			self._objective_box:Append(objective.progress_id)
		end

		self._objective_box:SetValue(1)
	end
end

EditorSideJobFilter = EditorSideJobFilter or class(MissionScriptEditor)

function EditorSideJobFilter:create_element()
	EditorSideJobFilter.super.create_element(self)
	
	self._element.class = "ElementSideJobFilter"
	self._element.values.challenge = ""
	self._element.values.objective_id = ""
	self._element.values.check_type = "unlocked"
end

function EditorSideJobFilter:_build_panel(panel, panel_sizer)
	self:_create_panel()

	if not self._challenge_ids then
		self._challenge_ids = {}

		for _, side_job_dlc in ipairs(managers.generic_side_jobs:side_jobs()) do
			for idx, challenge in ipairs(side_job_dlc.manager:challenges()) do
				table.insert(self._challenge_ids, challenge.id)
			end
		end
	end

	local objectives = {"all"}

	if self._element.values.challenge then
		local id = self._element.values.challenge
		local challenge = managers.generic_side_jobs:get_challenge(id)

		if challenge then
			for idx, objective in ipairs(challenge.objectives) do
				table.insert(objectives, objective.progress_id)
			end
		end
	end

	self._challenge_box = self:ComboCtrl("challenge", self._challenge_ids, {help = "Select a challenge from the combobox"})
	self._objective_box = self:ComboCtrl("objective_id", objectives, {help = "Select a challenge objective from the combobox"})
	self:ComboCtrl("check_type", {"complete", "incomplete"}, {help = "Check if the challenge is completed or incomplete"})
end

function EditorSideJobFilter:set_element_data(data)
	EditorSideJobFilter.super.set_element_data(self, data)

	if data.ctrlr == self._challenge_box then
		local id = self._challenge_box:get_value()
		local challenge = managers.generic_side_jobs:get_challenge(id)

		self._objective_box:Clear()
		self._objective_box:Append("all")

		for idx, objective in ipairs(challenge.objectives) do
			self._objective_box:Append(objective.progress_id)
		end

		self._objective_box:SetValue(1)
	end
end
