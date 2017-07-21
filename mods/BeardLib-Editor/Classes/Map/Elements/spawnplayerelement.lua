EditorPlayerSpawner = EditorPlayerSpawner or class(MissionScriptEditor)
function EditorPlayerSpawner:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPlayerSpawner"
    self._element.values.state = managers.player:default_player_state()
end
function EditorPlayerSpawner:_build_panel()
	self:_create_panel()
    self:ComboCtrl("state", managers.player:player_states(), {help = "Select a state from the combobox"})
	self:Text("The state defines how the player will be spawned")
end
 