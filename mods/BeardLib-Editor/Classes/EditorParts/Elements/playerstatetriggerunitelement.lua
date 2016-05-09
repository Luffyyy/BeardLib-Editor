EditorPlayerStateTrigger = EditorPlayerStateTrigger or class(MissionScriptEditor)
function EditorPlayerStateTrigger:init(unit)
	EditorPlayerStateTrigger.super.init(self, unit)
end

function EditorPlayerStateTrigger:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPlayerStateTrigger"
    self._element.values.trigger_times = 1
    self._element.values.state = managers.player:default_player_state()    
end

function EditorPlayerStateTrigger:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("state", managers.player:player_states(), "Select a state from the combobox")
	self:_add_help_text("Set the player state the element should trigger on.")
end
