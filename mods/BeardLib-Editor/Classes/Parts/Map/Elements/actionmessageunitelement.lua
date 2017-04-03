EditorActionMessage = EditorActionMessage or class(MissionScriptEditor)
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
	self:ComboCtrl("message_id", managers.action_messaging:ids(), {help = "Select a text id from the combobox"})
end
