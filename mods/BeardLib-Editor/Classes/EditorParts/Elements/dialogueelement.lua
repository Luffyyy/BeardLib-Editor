EditortDialogue = EditortDialogue or class(MissionScriptEditor)
EditortDialogue.SAVE_UNIT_POSITION = false
EditortDialogue.SAVE_UNIT_ROTATION = false
function EditortDialogue:init(unit)
	EditortDialogue.super.init(self, unit)
end
function EditortDialogue:create_element()
	self.super.create_element(self)
	self._element.class = "ElementDialogue"
	self._element.values.dialogue = "none"
	self._element.values.execute_on_executed_when_done = false
	self._element.values.use_position = false
	self._element.values.force_quit_current = nil 
end
function EditortDialogue:new_save_values(...)
	local t = EditortDialogue.super.new_save_values(self, ...)
	t.position = self._element.values.use_position and self._unit:position() or nil
	return t
end
function EditortDialogue:test_element()
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
function EditortDialogue:stop_test_element()
	managers.dialog:quit_dialog()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
end
function EditortDialogue:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("dialogue", table.list_add({"none"}, managers.dialog:conversation_names()), "Select a dialogue from the combobox")
	self:_build_value_checkbox("force_quit_current", "Force quits current dialog to allow this to be played immediately")
	self:_build_value_checkbox("execute_on_executed_when_done", "Execute on executed when done")
	self:_build_value_checkbox("use_position")
end
