Hooks:PostHook(GameStateMachine, "init", "BeardLibEditorGameStateInit", function(self)
	local editor
	local editor_func
	local ingame_waiting_for_players
	local ingame_waiting_for_players_func
	local ingame_waiting_for_respawn
	local ingame_lobby
	local ingame_lobby_func
	for name in pairs(self._transitions) do
		state = self._states[name] 
		if name == "ingame_lobby_menu" then
			ingame_lobby = state
			ingame_lobby_func = callback(nil, state, "default_transition")
		end
		if name == "ingame_waiting_for_respawn" then
			ingame_waiting_for_respawn = state
		end
		if name == "ingame_waiting_for_players" then
			ingame_waiting_for_players = state
			ingame_waiting_for_players_func = callback(nil, state, "default_transition")
		end
		if name == "editor" then
			editor = state
			editor_func = callback(nil, state, "default_transition")
		end
	end
	if editor and ingame_waiting_for_players and ingame_waiting_for_respawn and ingame_lobby then
		self:add_transition(editor, ingame_waiting_for_players, editor_func)
		self:add_transition(editor, ingame_waiting_for_respawn, editor_func)
		self:add_transition(editor, ingame_lobby, editor_func)
		self:add_transition(ingame_waiting_for_players, editor, ingame_waiting_for_players_func)
		self:add_transition(ingame_lobby, editor, ingame_lobby_func)
	end
end)