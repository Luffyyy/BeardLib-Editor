function MenuManager:create_controller()
	if not self._controller then
		self._controller = managers.controller:create_controller("MenuManager", nil, true)
		local setup = self._controller:get_setup()
		local look_connection = setup:get_connection("look")
		self._look_multiplier = look_connection:get_multiplier()
		if not managers.savefile:is_active() then
			self._controller:enable()
		end
	end
end

Hooks:PostHook(MenuCallbackHandler, "_dialog_end_game_yes", "EditorDialogEndGame", function(self)
	Global.editor_mode = nil
	Global.editor_loaded_instance = nil
end)