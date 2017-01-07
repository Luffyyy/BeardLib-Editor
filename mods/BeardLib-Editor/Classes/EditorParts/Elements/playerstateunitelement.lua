EditorPlayerState = EditorPlayerState or class(MissionScriptEditor)
function EditorPlayerState:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPlayerState"
	self._element.values.state = managers.player:default_player_state()
	self._element.values.use_instigator = false	
end

function EditorPlayerState:_build_panel()
	self:_create_panel()
	self:ComboCtrl("state", mixin_add(managers.player:player_states(), {
		"electrocution"
	}), {help = "Select a state from the combobox"})
	self:BooleanCtrl("use_instigator", {text = "On instigator"})
	self:Text("Set the state the players should change to.")
end
