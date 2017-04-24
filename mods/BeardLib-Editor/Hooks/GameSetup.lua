Hooks:PostHook(GameSetup, "init_finalize", "BeardLibEditorInitFinalize", function()
	BeardLibEditor:SetLoadingText("Almost There")
	if Global.editor_mode then 
		if Global.game_settings.single_player then
			game_state_machine:change_state_by_name("editor")
		else
			Global.editor_mode = nil
			game_state_machine:change_state_by_name("ingame_waiting_for_players")
		end
	end
end)

Hooks:PostHook(GameSetup, "destroy", "BeardLibEditorDestroy",function()
	if managers.editor then
		managers.editor:destroy()
	end
end)