EditorDialogue = EditorDialogue or class(MissionScriptEditor)
function EditorDialogue:create_element()
	self.super.create_element(self)
	self._element.class = "ElementDialogue"
	self._element.values.dialogue = "none"
	self._element.values.execute_on_executed_when_done = false
	self._element.values.use_position = false
	self._element.values.force_quit_current = nil 
end
function EditorDialogue:new_save_values(...)
	local t = EditorDialogue.super.new_save_values(self, ...)
	t.position = self._element.values.use_position and self._unit:position() or nil
	return t
end
function EditorDialogue:test_element()
	if self._element.values.dialogue == "none" then
		return
	end
	managers.dialog:quit_dialog()
	managers.dialog:queue_dialog(self._element.values.dialogue, {
		case = "russian",
		on_unit = self._unit,
		skip_idle_check = true
	})
	managers.editor:set_wanted_mute(false)
	managers.editor:set_listener_enabled(true)
end
function EditorDialogue:stop_test_element()
	managers.dialog:quit_dialog()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
end
function EditorDialogue:_build_panel()
	self:_create_panel()
	self:ComboCtrl("dialogue", table.list_add({"none"}, managers.dialog:conversation_names()), {help = "Select a dialogue from the combobox"})
	self:BooleanCtrl("force_quit_current", {help = "Force quits current dialog to allow this to be played immediately"})
	self:BooleanCtrl("execute_on_executed_when_done", {help = "Execute on executed when done"})
	self:BooleanCtrl("use_position")
end
