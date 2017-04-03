Hooks:PostHook(GameSetup, "init_finalize", "BeardLibEditorInitFinalize", function()
	if not Global.game_settings.single_player then
		Global.editor_mode = nil
	end
	if Global.editor_mode then
		game_state_machine:change_state_by_name("editor")
	else
		game_state_machine:change_state_by_name("ingame_waiting_for_players")
	end
end)

Hooks:PostHook(GameSetup, "destroy", "BeardLibEditorDestroy",function()
	if managers.editor then
		managers.editor:destroy()
	end
end)