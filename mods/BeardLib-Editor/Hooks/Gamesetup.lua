function GameSetup:init_finalize()
	if script_data.level_script and script_data.level_script.post_init then
		script_data.level_script:post_init()
	end
	if Global.current_load_package then
		PackageManager:unload(Global.current_load_package)
		Global.current_load_package = nil
	end
	if not Global.game_settings.single_player then
		Global.editor_mode = nil	
	end
	Setup.init_finalize(self)
	managers.hud:init_finalize()
	managers.dialog:init_finalize()
	managers.gage_assignment:init_finalize()
	managers.assets:init_finalize()
	managers.navigation:on_game_started()
	if SystemInfo:platform() == Idstring("PS3") or SystemInfo:platform() == Idstring("PS4") then
		managers.achievment:chk_install_trophies()
	end
	if managers.music then
		managers.music:init_finalize()
	end
	managers.dyn_resource:post_init()
	tweak_data.gui.crime_net.locations = {}
	self._keyboard = Input:keyboard()
	managers.network.account:set_playing(true)	
	if Global.editor_mode then
		game_state_machine:change_state_by_name("editor")
	else
		game_state_machine:change_state_by_name("ingame_waiting_for_players")
	end
end

Hooks:PostHook(GameSetup, "destroy", "BeardLibEditorDestroy",function()
	if BeardLibEditor.managers.MapEditor then
		BeardLibEditor.managers.MapEditor:destroy()
	end
end)