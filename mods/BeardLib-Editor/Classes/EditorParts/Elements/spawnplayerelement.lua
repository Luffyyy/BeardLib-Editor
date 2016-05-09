EditorPlayerSpawner = EditorPlayerSpawner or class(MissionScriptEditor)
function EditorPlayerSpawner:init(element)
	MissionScriptEditor.init(self, element)
end
function EditorPlayerSpawner:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPlayerSpawner"
    self._element.values.state = managers.player:default_player_state()
end
function EditorPlayerSpawner:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("state", managers.player:player_states(), "Select a state from the combobox")
	self:_add_help_text("The state defines how the player will be spawned")
end
 