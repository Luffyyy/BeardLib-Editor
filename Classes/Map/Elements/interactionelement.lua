EditorInteraction = EditorInteraction or class(MissionScriptEditor)
EditorInteraction.ON_EXECUTED_ALTERNATIVES = {"interacted", "interupt", "start"}
EditorInteraction.default_distance = 150
EditorInteraction.color = Color(0.15, 1, 0, 1)
EditorInteraction._axis = {
	x = Vector3(-1, 0, 0),
	y = Vector3(0, -1, 0),
	z = Vector3(0, 0, -1)
}
function EditorInteraction:init(...)
	local unit = "units/dev_tools/mission_elements/point_interaction/interaction_dummy"
	local assets = self:GetPart("assets")
	if not PackageManager:has(Idstring("unit"), Idstring(unit)) and assets then
		self:GetPart("assets"):quick_load_from_db("unit", unit)
	end
	self._brush = Draw:brush()
	return EditorInteraction.super.init(self, ...)
end

function EditorInteraction:create_element(...)
	self.super.create_element(self, ...)
	self._element.class = "ElementInteraction"
	self._element.values.tweak_data_id = "none"
	self._element.values.override_timer = -1 
	self._element.values.host_only = false
	self._element.values.debug_mode = false
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

function EditorInteraction:update_selected()
	if self._element.values.debug_mode then
	
		local data = tweak_data.interaction[self._element.values.tweak_data_id]

		if not data then
			return
		end

		local radius = self.default_distance

		if data.interact_distance then
			radius = data.interact_distance
		end

		local position = self._unit:position()
		local color = self.color

		if data.axis then
			local normal = self._axis[data.axis]
			normal = normal:rotate_with(self._unit:rotation())

			self:_draw_debug_halph_sphere(position, radius, color, normal)
		else
			self:_draw_debug_sphere(position, radius, color)
		end
	end
end

function EditorInteraction:_draw_debug_sphere(position, radius, color)
	self._brush:set_color(color)
	self._brush:sphere(position, radius, 4)
	Application:draw_sphere(position, radius, color.red, color.green, color.blue)
end

function EditorInteraction:_draw_debug_halph_sphere(position, radius, color, normal)
	self._brush:set_color(color)
	self._brush:half_sphere(position, radius, normal, 4)
	Application:draw_sphere(position, radius, color.red, color.green, color.blue)
end

function EditorInteraction:set_element_data(...)
	EditorInteraction.super.set_element_data(self, ...)
	self:update_interaction_unit()
	self:_set_text()
end

function EditorInteraction:update_positions(...)
	EditorInteraction.super.update_positions(self, ...)
	self:update_interaction_unit()
end

function EditorInteraction:_set_text()
	local selected = self._element.values.tweak_data_id
	local interaction = tweak_data.interaction[ selected ]

	if interaction then
		local text_id = "Text: " .. managers.localization:text(interaction.text_id)
		local action_text_id = "\nAction Text: " .. managers.localization:text(interaction.action_text_id)
		local timer = "\nTime: " .. (interaction.timer or "0") .. " second(s)"
		local distance = interaction.interact_distance or tweak_data.interaction.INTERACT_DISTANCE
		local distance_meter = distance / 100
		local interact_distance = "\nDistance: " .. distance .. "  (" .. distance_meter .. " meters)"
		local axis = "\nAxis: No Axis"
		if interaction.axis then
			axis = "\nAxis: " .. interaction.axis:upper()
		end
		local special_equipment_block = "\nSpecial Equipment Block: " .. (interaction.special_equipment_block or "none")
		local can_civ_mode = ""
		if interaction.can_interact_in_civilian or interaction.can_interact_in_civilian == false then
			can_civ_mode = "\nCan Interact In Civilian Mode: " .. tostring(interaction.can_interact_in_civilian)
		elseif interaction.can_interact_only_in_civilian or interaction.can_interact_only_in_civilian == false then
			can_civ_mode = "\nCan Interact In Civilian Mode ONLY: " .. tostring(interaction.can_interact_only_in_civilian)
		end

		local equip_text = ""
		if interaction.special_equipment then
			local special_equipment = "\nSpecial Equipment: " .. interaction.special_equipment
			local equipment_text_id = "\nEquipment Text ID: " .. managers.localization:text(interaction.equipment_text_id)
			local equipment_consume = "\nEquipment Consume: N/A"
			if interaction.equipment_consume or interaction.equipment_consume == false then
				equipment_consume = "\nEquipment Consume: " .. tostring(interaction.equipment_consume)
			end

			equip_text = "\n" .. special_equipment .. equipment_text_id .. equipment_consume
		end

		local sounds_text = ""
		if interaction.sound_start or interaction.sound_interupt or interaction.sound_done then
			local sound_start = "\nSound Start: " .. (interaction.sound_start or "none")
			local sound_interupt = "\nSound Interupt: " .. (interaction.sound_interupt or "none")
			local sound_done = "\nSound Done: " .. (interaction.sound_done or "none")

			sounds_text = "\n" .. sound_start .. sound_interupt .. sound_done
		end

		local text = text_id .. action_text_id .. timer .. interact_distance .. axis .. special_equipment_block .. can_civ_mode
		local interaction_details = text .. equip_text .. sounds_text
		self._text:SetText(interaction_details)
		self._text:SetVisible(true)
	else
		self._text:SetText("")
		self._text:SetVisible(false)
	end
	self._holder:AlignItems(true)
end

function EditorInteraction:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("debug_mode")
	self:ComboCtrl("tweak_data_id", table.list_add({"none"}, table.map_keys(tweak_data.interaction)))
	self:NumberCtrl("override_timer", {floats = 1, min = -1, help = "Can be used to override the interaction time specified in tweak data. -1 means that it should not override."})
	self:BooleanCtrl("host_only", {help="Only allow the host of the game to interact with this."})
	self._text = self:Text("")
	self:Info([[
This element creates an interaction.
Override time is optional and will replace tweak data timer (-1 means do not overrride). 
Use disabled/enabled state on element to set active state on interaction.
You can create a new interaction using BeardLib's InteractionModule.
]])
	self:update_interaction_unit()
	self:_set_text()
end