require("lib/states/GameState")
EditorState = EditorState or class(GameState)
function EditorState:init(game_state_machine)
	GameState.init(self, "editor", game_state_machine)
end

function EditorState:at_enter()
	if not Global.editor_mode then
		return
	end
	 
	managers.editor:set_enabled(true)
    managers.achievment.award = function() end
    local job_id = managers.job:current_job_id()
    if job_id then
	    tweak_data.narrative.jobs[job_id].contract_cost = {0,0,0,0,0,0,0}
	    tweak_data.narrative.jobs[job_id].payout = {0,0,0,0,0,0,0}
		tweak_data.narrative.jobs[job_id].contract_visuals = {}
	    tweak_data.narrative.jobs[job_id].contract_visuals.min_mission_xp = {0,0,0,0,0,0,0}
	    tweak_data.narrative.jobs[job_id].contract_visuals.max_mission_xp = {0,0,0,0,0,0,0}
	end
end

function EditorState:at_exit(new_state)
	if Global.editor_mode then
		if new_state:name() == "world_camera" then
			managers.editor:world_camera_disable()
		else
			managers.editor:set_enabled(false)
			managers.mission:activate()
		end
	end
end