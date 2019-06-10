EditorGlobalEventTrigger = EditorGlobalEventTrigger or class(MissionScriptEditor)
function EditorGlobalEventTrigger:create_element()
	self.super.create_element(self)
    self._element.class = "ElementGlobalEventTrigger"
	self._element.values.trigger_times = 1
	self._element.values.global_event = "none"
end
function EditorGlobalEventTrigger:_build_panel()
	self:_create_panel()
	self:ComboCtrl("global_event", table.list_add({"none"}, managers.mission:get_global_event_list()), {help = "Select a global event from the combobox"})
end
