EditorActionMessage = EditorActionMessage or class(MissionScriptEditor)
function EditorActionMessage:init(unit)
	EditorActionMessage.super.init(self, unit)
end
function EditorActionMessage:create_element()
	self.super.create_element(self)
	self._element.class = "ElementActionMessage"
	self._element.values.message_id = "none"	
end
function EditorActionMessage:set_text()
	local message = managers.action_messaging:message(self._element.values.message_id)
	self._text:set_value(message and managers.localization:text(message.text_id) or "none")
end
function EditorActionMessage:_build_panel()
	self:_create_panel()
	self._elements_menu:ComboBox({
		name = "message_id",
		text = "Message id: ",
		value = self._element.values.message_id,
		items =  managers.action_messaging:ids(),
		help = "Select a text id from the combobox",
		callback = callback(self, self, "set_element_data")
	})
end
