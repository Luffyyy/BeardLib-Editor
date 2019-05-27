if not Global.editor_mode then
	return
end

core:import("CoreMissionScriptElement")
ElementAiGlobalEvent = ElementAiGlobalEvent or class(CoreMissionScriptElement.MissionScriptElement)
--Report if outdated.
function ElementAiGlobalEvent:_finalize_values(values) end
function ElementAiGlobalEvent:on_executed(instigator)
	if not self._values.enabled then
		return 
	end
	local wave_mode = self._values.wave_mode
	local blame = self._values.blame
	local AI_event = self._values.AI_event
	if wave_mode and wave_mode ~= "none" then
		managers.groupai:state():set_wave_mode(wave_mode)
	end
	if not blame or blame == "none" then
		Application:error("ElementAiGlobalEvent needs to be updated with blame parameter, and not none", blame)
	end
	if AI_event and AI_event ~= "none" then
		if AI_event == "police_called" then
			managers.groupai:state():on_police_called(managers.groupai:state().analyse_giveaway(blame, instigator, {"vo_cbt"}))
		elseif AI_event == "police_weapons_hot" then
			managers.groupai:state():on_police_weapons_hot(managers.groupai:state().analyse_giveaway(blame, instigator, {"vo_cbt"}))
		elseif AI_event == "gangsters_called" then
			managers.groupai:state():on_gangsters_called(managers.groupai:state().analyse_giveaway(blame, instigator, {"vo_cbt"}))
		elseif AI_event == "gangster_weapons_hot" then
			managers.groupai:state():on_gangster_weapons_hot(managers.groupai:state().analyse_giveaway(blame, instigator, {"vo_cbt"}))
		end
	end
	ElementAiGlobalEvent.super.on_executed(self, instigator)
end