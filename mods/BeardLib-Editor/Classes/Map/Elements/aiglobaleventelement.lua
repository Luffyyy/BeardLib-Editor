EditorAiGlobalEvent = EditorAiGlobalEvent or class(MissionScriptEditor)
function EditorAiGlobalEvent:create_element()
	self.super.create_element(self)	
	self._element.class = "ElementAiGlobalEvent"
	self._element.values.blame = "none"
end

function EditorAiGlobalEvent:init(...)
	local unit = EditorAiGlobalEvent.super.init(self, ...)
	if self._element.values.event then
		self._element.values.wave_mode = self._element.values.event
		self._element.values.event = nil
	end
	return unit
end

function EditorAiGlobalEvent:_build_panel()
	self:_create_panel()
	self:ComboCtrl("wave_mode", ElementAiGlobalEvent._wave_modes)
	self:ComboCtrl("AI_event", ElementAiGlobalEvent._AI_events)
	self:ComboCtrl("blame", ElementAiGlobalEvent._blames)
end