EditorInteraction = EditorInteraction or class(MissionScriptEditor)
EditorInteraction.ON_EXECUTED_ALTERNATIVES = {"interacted", "interupt", "start"}
function EditorInteraction:init(...)
	local unit = "units/dev_tools/mission_elements/point_interaction/interaction_dummy"
	local assets = self:Manager("world")._assets_manager
	if not PackageManager:has(Idstring("unit"), Idstring(unit)) and assets then
		BeardLibEditor.Utils:QuickDialog({title = "An error appears!", message = "This element requires the interaction dummy unit to be loaded or else it won't work!"}, {{"Load it", function()
            assets:find_package(unit, true)
		end}})
		return
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
	if element then
		if element._unit then
			element._unit:set_position(self._element.values.position)
			element._unit:set_rotation(self._element.values.rotation)
			element._unit:set_moving()
            element._unit:set_tweak_data(self._element.values.tweak_data_id)
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
	self:Text("This element creates an interaction. Override time is optional and will replace tweak data timer (-1 means do not overrride). Use disabled/enabled state on element to set active state on interaction.")
end