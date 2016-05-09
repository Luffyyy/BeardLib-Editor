AiGlobalEventUnitElement = AiGlobalEventUnitElement or class(MissionScriptEditor)
function AiGlobalEventUnitElement:init(unit)
	AiGlobalEventUnitElement.super.init(self, unit)
end
function AiGlobalEventUnitElement:create_element()
	self.super.create_element(self)	
	self._element.class = "ElementAiGlobalEvent"
	self._element.values.blame = "none"
end
function AiGlobalEventUnitElement:post_init(...)
	AiGlobalEventUnitElement.super.post_init(self, ...)
	if self._element.values.event then
		self._element.values.wave_mode = self._element.values.event
		self._element.values.event = nil
	end
end
function AiGlobalEventUnitElement:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("wave_mode", ElementAiGlobalEvent._wave_modes)
	self:_build_value_combobox("AI_event", ElementAiGlobalEvent._AI_events)
	self:_build_value_combobox("blame", ElementAiGlobalEvent._blames)
end
