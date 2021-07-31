EditorInteraction = EditorInteraction or class(MissionScriptEditor)
EditorInteraction.ON_EXECUTED_ALTERNATIVES = {"interacted", "interupt", "start"}
function EditorInteraction:init(...)
	local unit = "units/dev_tools/mission_elements/point_interaction/interaction_dummy"
	local assets = self:GetPart("assets")
	if not PackageManager:has(Idstring("unit"), Idstring(unit)) and assets then
		self:GetPart("assets"):quick_load_from_db("unit", unit)
	end
	return EditorInteraction.super.init(self, ...)
end

function EditorInteraction:create_element(...)
	self.super.create_element(self, ...)
	self._element.class = "ElementInteraction"
	self._element.values.tweak_data_id = "none"
	self._element.values.override_timer = -1 
end

function EditorInteraction:update_interaction_unit(pos, rot)
	local element = managers.mission:get_element_by_id(self._element.id)
	if alive(self._last_alert) then
		self._last_alert:Destroy()
	end
	if element then
		if tweak_data.interaction[self._element.values.tweak_data_id] then
			if not alive(element._unit) then
				element._unit = CoreUnit.safe_spawn_unit("units/dev_tools/mission_elements/point_interaction/interaction_dummy", self._element.values.position, self._element.values.rotation)
				element._unit:interaction():set_mission_element(element)
			end
			element._unit:interaction():set_tweak_data(self._element.values.tweak_data_id)
		else
			local msg = "Current tweak data ID does not exist"
			if self._element.values.tweak_data_id == "none" then
				msg = "No interaction tweak data ID set"
			end
			self._last_alert = self:Alert(msg..". \nThe element will not work.")
			self._holder:AlignItems(true)
		end
		if alive(element._unit) then
			element._unit:set_position(self._element.values.position)
			element._unit:set_rotation(self._element.values.rotation)
			element._unit:set_moving()
			element._unit:interaction():set_override_timer_value(self._element.values.override_timer ~= -1 and self._element.values.override_timer or nil)
		end
	end
end

function EditorInteraction:set_element_data(...)
	EditorInteraction.super.set_element_data(self, ...)
	self:update_interaction_unit()
end

function EditorInteraction:update_positions(...)
	EditorInteraction.super.update_positions(self, ...)
	self:update_interaction_unit()
end

function EditorInteraction:_build_panel()
	self:_create_panel()
	self:ComboCtrl("tweak_data_id", table.list_add({"none"}, table.map_keys(tweak_data.interaction)))
	self:NumberCtrl("override_timer", {floats = 1, min = -1, help = "Can be used to override the interaction time specified in tweak data. -1 means that it should not override."})
	self:Info([[
This element creates an interaction.
Override time is optional and will replace tweak data timer (-1 means do not overrride). 
Use disabled/enabled state on element to set active state on interaction.
You can create a new interaction using BeardLib's InteractionModule.
]])
	self:update_interaction_unit()
end