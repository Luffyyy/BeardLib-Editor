EditorStatisticsJobs = EditorStatisticsJobs or class(MissionScriptEditor)
function EditorStatisticsJobs:create_element()
	self.super.create_element(self)
	self._element.class = "ElementStatisticsJobs"
	self._element.values.elements = {}
	self._element.values.job = "four_stores"
	self._element.values.state = "completed"
	self._element.values.difficulty = "all"
	self._element.values.include_prof = true
	self._element.values.include_dropin = false
	self._element.values.required = 1
end

function EditorStatisticsJobs:_build_panel()
	self:_create_panel()
	local job_list = {}
	for job, data in pairs(tweak_data.narrative.jobs) do
		if not data.wrapped_to_job and table.contains(tweak_data.narrative:get_jobs_index(), job) then
			table.insert(job_list, job)
		end
	end
	table.sort(job_list)
	self:ComboCtrl("job", job_list, "Select the required job")
	local states = {
		"started",
		"started_dropin",
		"completed",
		"completed_dropin",
		"failed",
		"failed_dropin"
	}
	self:ComboCtrl("state", states, {help = "Select the required play state."})
	local difficulties = deep_clone(tweak_data.difficulties)
	table.insert(difficulties, "all")
	self:ComboCtrl("difficulty", difficulties, {help = "Select the required difficulty."})
	self:BooleanCtrl("include_prof", {help = "Select if professional heists should be included."})
	self:BooleanCtrl("include_dropin", {help = "Select if drop-in is counted as well."})
	self:NumberCtrl("required", {min = 1, help = "Type the required amount that is needed."})
end
