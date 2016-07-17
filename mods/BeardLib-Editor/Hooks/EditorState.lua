require("lib/states/GameState")
EditorState = EditorState or class(GameState)
function EditorState:init(game_state_machine)
	GameState.init(self, "editor", game_state_machine)
end
function EditorState:at_enter()
	if not Global.editor_mode then
		return
	end
	BeardLibEditor.managers.MapEditor:enable()
    managers.achievment.award = function() end
    local job_id = managers.job:current_job_id()
    tweak_data.narrative.jobs[job_id].contract_cost = {0,0,0,0,0}
    tweak_data.narrative.jobs[job_id].payout = {0,0,0,0,0}
	tweak_data.narrative.jobs[job_id].contract_visuals = {}
    tweak_data.narrative.jobs[job_id].contract_visuals.min_mission_xp = {0,0,0,0,0}
    tweak_data.narrative.jobs[job_id].contract_visuals.max_mission_xp = {0,0,0,0,0}
end
function EditorState:at_exit()
	if Global.editor_mode then
		BeardLibEditor.managers.MapEditor:disable()
	end
end
