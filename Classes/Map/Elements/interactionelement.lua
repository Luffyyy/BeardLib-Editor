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
	self:update_interaction_details()
end

function EditorInteraction:update_positions(...)
	EditorInteraction.super.update_positions(self, ...)
	self:update_interaction_unit()
end

function EditorInteraction:clean_tweakdata()
	local tweakdata = table.map_keys(tweak_data.interaction)
	local invalid_tweakdata_ids = {
		CULLING_DISTANCE = true,
		INTERACT_DISTANCE = true,
		MAX_INTERACT_DISTANCE = true
	}

	for i = #tweakdata, 1, -1 do
		value = tweakdata[i]
		if invalid_tweakdata_ids[value] then
			table.remove(tweakdata, i)
		end
	end

	return tweakdata
end

function EditorInteraction:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("debug_mode")
	self:ComboCtrl("tweak_data_id", table.list_add({"none"}, self:clean_tweakdata()))
	self:NumberCtrl("override_timer", {floats = 1, min = -1, help = "Can be used to override the interaction time specified in tweak data. -1 means that it should not override."})
	self:BooleanCtrl("host_only", {help="Only allow the host of the game to interact with this."})
	self:Info([[
This element creates an interaction.
Override time is optional and will replace tweak data timer (-1 means do not overrride). 
Use disabled/enabled state on element to set active state on interaction.
You can create a new interaction using BeardLib's InteractionModule.
]])

	self.details_grp = self:group("InteractionDetails")
	local style_item = {border_size = 1, border_color = Color.white:with_alpha(0.1)}
	local style_table = {
		border_size = style_item.border_size,
		border_color = style_item.border_color,
		full_bg_color = Color.black:with_alpha(0),
		border_bottom = true
	}
	local style_separator = {border_size = 2, border_color = style_item.border_color:with_alpha(0.25)}
	-- basic info
	self.details_grp:ulbl("Timer:", style_item)
	self.details_grp:ulbl("Distance:", style_item)
	self.details_grp:ulbl("Axis:", style_item)
	self.details_grp:ulbl("Start Active:", style_separator)
	-- text
	self.details_grp:ulbl("Text:", style_item)
	self.details_grp:ulbl("Action Text:", style_item)
	self.details_grp:ulbl("Blocked Hint:", style_separator)
	-- equipment
	self.details_grp:ulbl("Special Equipment:", style_item)
	self.details_grp:holder("Possible Special Equipment:", style_table)
	self.details_grp:ulbl("Equipment Text:", style_item)
	self.details_grp:ulbl("Equipment Consume:", style_item)
	self.details_grp:ulbl("Dont Need Equipment:", style_separator)
	-- sounds
	self.details_grp:ulbl("Sound Start:", style_item)
	self.details_grp:ulbl("Sound Interupt:", style_item)
	self.details_grp:ulbl("Sound Done:", style_separator)
	-- extra
	self.details_grp:ulbl("Can Interact In Civilian Mode:", style_item)
	self.details_grp:holder("Special Equipment Block:", style_table)
	self.details_grp:ulbl("Required Deployable:", style_item)
	self.details_grp:ulbl("Deployable Consume:", style_item)
	self.details_grp:ulbl("Requires Upgrade:", style_separator)
	-- pretty much irrelevant, but decided to include anyway
	self.details_grp:ulbl("Contour:", style_item)
	self.details_grp:ulbl("No Contour:", style_item)
	self.details_grp:lbl("Icon:", style_item)

	for _, item in ipairs(self.details_grp._my_items) do
		item:SetParam("range_color", {{0, Color.white:with_alpha(0.6)}, {item.name:len(), Color.white}})
	end
	
	self:update_interaction_unit()
	self:update_interaction_details()
end

function EditorInteraction:update_interaction_details()
	local selected = self._element.values.tweak_data_id
	local interaction = tweak_data.interaction[ selected ]
	local details_grp = self.details_grp

	if interaction then
		details_grp:SetVisible(true)

		local det_timer = details_grp:GetItem("Timer:")
		local det_interact_distance = details_grp:GetItem("Distance:")
		local det_axis = details_grp:GetItem("Axis:")
		local det_start_active = details_grp:GetItem("Start Active:")
		local det_text = details_grp:GetItem("Text:")
		local det_action_text = details_grp:GetItem("Action Text:")
		local det_blocked_hint = details_grp:GetItem("Blocked Hint:")
		local det_special_equipment = details_grp:GetItem("Special Equipment:")
		local det_possible_special_equipment_table = details_grp:GetItem("Possible Special Equipment:")
		local det_equipment_text = details_grp:GetItem("Equipment Text:")
		local det_equipment_consume = details_grp:GetItem("Equipment Consume:")
		local det_dont_need_equipment = details_grp:GetItem("Dont Need Equipment:")
		local det_sound_start = details_grp:GetItem("Sound Start:")
		local det_sound_interupt = details_grp:GetItem("Sound Interupt:")
		local det_sound_done = details_grp:GetItem("Sound Done:")
		local det_civ_mode = details_grp:GetItem("Can Interact In Civilian Mode:")
		local det_special_equipment_block_table = details_grp:GetItem("Special Equipment Block:")
		local det_required_deployable = details_grp:GetItem("Required Deployable:")
		local det_deployable_consume = details_grp:GetItem("Deployable Consume:")
		local det_requires_upgrade = details_grp:GetItem("Requires Upgrade:")
		local det_contour = details_grp:GetItem("Contour:")
		local det_no_contour = details_grp:GetItem("No Contour:")
		local det_icon = details_grp:GetItem("Icon:")

		local timer = interaction.timer and tostring(interaction.timer) .. " second(s)" or "0 seconds"
		if self._element.values.override_timer ~= -1 then
			timer = timer .. "    *Overridden to  " .. tostring(self._element.values.override_timer) .. "  second(s)"
		end
		local distance = interaction.interact_distance or tweak_data.interaction.INTERACT_DISTANCE
		local distance_meters = distance / 100
		local axis = interaction.axis and interaction.axis:upper() or ""
		local start_active = interaction.start_active or interaction.start_active == false and tostring(interaction.start_active) or "true"
		local text_id_localized = "\"" .. managers.localization:text(interaction.text_id) .. "\""
		local action_text_localized = interaction.action_text_id and "\"" .. managers.localization:text(interaction.action_text_id) .. "\"" or ""
		local blocked_hint = interaction.blocked_hint and interaction.blocked_hint or ""
		local special_equipment = interaction.special_equipment and interaction.special_equipment or ""
		local special_equipment_localized = interaction.special_equipment and "  (" .. managers.localization:text(tweak_data.equipments.specials[special_equipment].text_id) .. ")" or ""
		local possible_special_equipment = interaction.possible_special_equipment and true or false
		local equipment_text = interaction.equipment_text_id and "\"" .. managers.localization:text(interaction.equipment_text_id) .. "\"" or ""
		local equipment_consume = interaction.equipment_consume or interaction.equipment_consume == false and tostring(interaction.equipment_consume) or ""
		local sound_start = interaction.sound_start and interaction.sound_start or ""
		local sound_interupt = interaction.sound_interupt and interaction.sound_interupt or ""
		local sound_done = interaction.sound_done and interaction.sound_done or ""
		local can_civ_mode = interaction.can_interact_in_civilian and tostring(interaction.can_interact_in_civilian) or "false"
		local can_civ_mode_only = interaction.can_interact_only_in_civilian and tostring(interaction.can_interact_only_in_civilian) or "false"
		local civ_mode = "Can Interact In Civilian Mode:  " .. can_civ_mode
		local civ_mode_color_range = civ_mode:len() - can_civ_mode:len()
		if interaction.can_interact_only_in_civilian then
			civ_mode = "Can Interact ONLY In Civilian Mode:  " .. can_civ_mode_only
			civ_mode_color_range = civ_mode:len() - can_civ_mode_only:len()
		end
		det_civ_mode:SetParam("range_color", {{0, Color.white:with_alpha(0.6)}, {civ_mode_color_range, Color.white}})
		local special_equipment_block_type = type(interaction.special_equipment_block)
		local special_equipment_block
		if special_equipment_block_type ~= "table" then
			special_equipment_block = interaction.special_equipment_block or ""
		end
		local required_deployable = interaction.required_deployable and interaction.required_deployable or ""
		local deployable_consume = interaction.deployable_consume or interaction.deployable_consume == false and tostring(interaction.deployable_consume) or ""
		local requires_upgrade = interaction.requires_upgrade and interaction.requires_upgrade.upgrade or ""
		local dont_need_equipment = interaction.dont_need_equipment or interaction.dont_need_equipment == false and tostring(interaction.dont_need_equipment) or ""
		local contour = interaction.contour and interaction.contour or ""
		local no_contour = interaction.no_contour or interaction.no_contour == false and tostring(interaction.no_contour) or ""
		local icon = interaction.icon and interaction.icon or ""

		details_grp:SetText("Interaction Details:  " .. selected .. "  ")
		det_timer:SetText("Time:  " .. timer)
		det_interact_distance:SetText("Distance:  " .. distance .. "  (" .. distance_meters .. " meters)")
		det_axis:SetText("Axis:  " .. axis)
		det_start_active:SetText("Start Active:  " .. tostring(start_active))
		det_text:SetText("Text:  " .. text_id_localized)
		det_action_text:SetText("Action Text:  " .. action_text_localized)
		det_blocked_hint:SetText("Blocked Hint:  " .. blocked_hint)
		det_special_equipment:SetText("Special Equipment:  " .. special_equipment .. special_equipment_localized)
		det_equipment_text:SetText("Equipment Text:  " .. equipment_text)
		det_equipment_consume:SetText("Equipment Consume:  " .. tostring(equipment_consume))
		det_sound_start:SetText("Sound Start:  " .. sound_start)
		det_sound_interupt:SetText("Sound Interupt:  " .. sound_interupt)
		det_sound_done:SetText("Sound Done:  " .. sound_done)
		det_civ_mode:SetText(civ_mode)
		det_required_deployable:SetText("Required Deployable:  " .. required_deployable)
		det_deployable_consume:SetText("Deployable Consume:  " .. tostring(deployable_consume))
		det_requires_upgrade:SetText("Requires Upgrade:  " .. requires_upgrade)
		det_dont_need_equipment:SetText("Dont Need Equipment:  " .. tostring(dont_need_equipment))
		det_contour:SetText("Contour:  " .. contour)
		det_no_contour:SetText("No Contour:  " .. tostring(no_contour))
		det_icon:SetText("Icon:  " .. icon)
		
		if special_equipment_block_type == "table" then
			self:fill_details_table(det_special_equipment_block_table, interaction.special_equipment_block, "Special Equipment Block:")
		else
			self:fill_details_table(det_special_equipment_block_table, nil, "Special Equipment Block:  " .. special_equipment_block, special_equipment_block:len())
		end

		if possible_special_equipment then
			self:fill_details_table(det_possible_special_equipment_table, interaction.possible_special_equipment, "Possible Special Equipment:")
		end
		det_possible_special_equipment_table:SetVisible(possible_special_equipment)

	else
		details_grp:SetVisible(false)

	end

	self._holder:AlignItems(true)
end

function EditorInteraction:fill_details_table(menu, table, header, value_length)
	menu:ClearItems()
	local color_range = header:len() - (value_length or 0)
	menu:lbl(header, {
		offset = {0, 0},
		range_color = { {0, Color.white:with_alpha(0.6)}, {color_range, Color.white} }
	})

	if type(table) ~= "table" then
		return
	end

	local style = {
		text = "",
		border_bottom = true,
		border_size = 1,
		border_color = Color.white:with_alpha(0.1),
		size_by_text = true,
		offset = {menu.w / 15, 0},
	}

	for _, id in ipairs(table) do
		style.text = id
		if _ == #table then
			style.border_bottom = false
		end
		menu:ulbl(id, style)
	end
end