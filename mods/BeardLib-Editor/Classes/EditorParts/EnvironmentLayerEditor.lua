EnvironmentLayerEditor = EnvironmentLayerEditor or class(EditorPart)
local sky_rot_key = Idstring("sky_orientation/rotation"):key()
function EnvironmentLayerEditor:init(parent)
	self:init_basic(parent, "EnvironmentLayerEditor")
	self._menu = parent._menu
	MenuUtils:new(self)
	self._wind_speeds = {
	 	{speed = 0, beaufort = 0, description = "Calm"},
		{speed = 0.3, beaufort = 1, description = "Light air"},
		{speed = 1.6, beaufort = 2, description = "Light breeze"},
		{speed = 3.4, beaufort = 3, description = "Gentle breeze"},
		{speed = 5.5, beaufort = 4, description = "Moderate breeze"},
		{speed = 8, beaufort = 5, description = "Fresh breeze"},
		{speed = 10.8, beaufort = 6, description = "Strong breeze"},
		{speed = 13.9, beaufort = 7, description = "Near Gale"},
		{speed = 17.2, beaufort = 8, description = "Fresh Gale"},
		{speed = 20.8, beaufort = 9, description = "Strong Gale"},
		{speed = 24.5, beaufort = 10, description = "Whole storm"},
		{speed = 28.5, beaufort = 11,description = "Violent storm"},
		{speed = 32.7, beaufort = 12, description = "Hurricane"}
	}
	self:load()
	self._created_units = {}
	self._wind_speed = 6
	self._wind_speed_variation = 1
	self._environment_area_unit = "core/units/environment_area/environment_area"
	self._effect_unit = "core/units/effect/effect"
	self._cubemap_unit = "core/units/cubemap_gizmo/cubemap_gizmo"
	self._dome_occ_shape_unit = "core/units/dome_occ_shape/dome_occ_shape"
	--self._position_as_slot_mask = self._position_as_slot_mask + managers.slot:get_mask("statics")
	--self._owner:viewport():set_environment("core/environments/default")
	self._environment_modifier_id = managers.viewport:create_global_environment_modifier(sky_rot_key, true, callback(self, self, "sky_rotation_modifier"))
end
function EnvironmentLayerEditor:load()
	local environment = managers.worlddefinition._world_data.environment
	self._environment_values = environment.environment_values
	--CoreEws.change_combobox_value(self._environments_combobox, self._environment_values.environment)
	--self._sky_rotation:set_value(self._environment_values.sky_rot)
	--CoreEws.change_combobox_value(self._color_grading_combobox, self._environment_values.color_grading)
	--self._dome_occ_resolution_ctrlr:set_value(self._environment_values.dome_occ_resolution)
	self:_load_wind(environment.wind)
	--self:_load_effects(environment.effects) ?
	--self:_load_environment_areas() ?
	--self:_load_dome_occ_shapes(environment.dome_occ_shapes) ?
	for _, unit in ipairs(environment.units or {}) do
		self:set_up_name_id(unit)
		self._owner:register_unit_id(unit)
		table.insert(self._created_units, unit)
	end
end
function EnvironmentLayerEditor:_load_wind(wind)
	self._wind_rot = Rotation(wind.angle, 0, wind.tilt)
	self._wind_dir_var = wind.angle_var
	self._wind_tilt_var = wind.tilt_var
	self._wind_speed = wind.speed or self._wind_speed
	self._wind_speed_variation = wind.speed_variation or self._wind_speed_variation
--	self._wind_ctrls.wind_speed:set_value(self._wind_speed * 10)
--	self._wind_ctrls.wind_speed_variation:set_value(self._wind_speed_variation * 10)
	--self:update_wind_speed_labels()
	--self._wind_ctrls.wind_direction:set_value(wind.angle)
	--self._wind_ctrls.wind_variation:set_value(self._wind_dir_var)
--	self._wind_ctrls.tilt_angle:set_value(wind.tilt)
	--self._wind_ctrls.tilt_variation:set_value(self._wind_tilt_var)
	self:set_wind()
end
function EnvironmentLayerEditor:save()
	local effects = {}
	local environment_areas = {}
	local environment_paths = {}
	local cubemap_gizmos = {}
	local dome_occ_shapes = {}
	for _, unit in ipairs(self._created_units) do
		if unit:name() == Idstring(self._effect_unit) then
			local effect = unit:unit_data().effect or "none"
			local name_id = unit:unit_data().name_id
			table.insert(effects, {
				name = effect,
				name_id = name_id,
				position = unit:position(),
				rotation = unit:rotation()
			})
		elseif unit:name() == Idstring(self._environment_area_unit) then
			local area = unit:unit_data().environment_area
			self:_update_filter_list(area)
			table.insert(environment_areas, area:save_level_data())
		elseif unit:name() == Idstring(self._cubemap_unit) then
			table.insert(cubemap_gizmos, unit:unit_data())
		elseif unit:name() == Idstring(self._dome_occ_shape_unit) then
			local shape = unit:unit_data().occ_shape
			table.insert(dome_occ_shapes, shape:save_level_data())
		end
	end
	return {
		environment_values = self._environment_values,
		wind = {
			angle = self._wind_rot:yaw(),
			angle_var = self._wind_dir_var,
			tilt = self._wind_rot:roll(),
			tilt_var = self._wind_tilt_var,
			speed = self._wind_speed,
			speed_variation = self._wind_speed_variation
		},
		effects = effects,
		environment_areas = environment_areas,
		cubemap_gizmos = cubemap_gizmos,
		dome_occ_shapes = dome_occ_shapes
	}
end
function EnvironmentLayerEditor:update(t, dt)
	if self._draw_wind:Value() then
		for i = -0.9, 1.2, 0.3 do
			for j = -0.9, 1.2, 0.3 do
				self:draw_wind(maangers.editor:screen_to_world(Vector3(j, i, 0), 1000))
			end
		end
	end
	for _, unit in ipairs(self._created_units) do
		if unit:unit_data().current_effect then
			World:effect_manager():move(unit:unit_data().current_effect, unit:position())
			World:effect_manager():rotate(unit:unit_data().current_effect, unit:rotation())
		end
		if unit:name() == Idstring(self._effect_unit) then
			Application:draw(unit, 0, 0, 1)
		end
		if unit:name() == Idstring(self._environment_area_unit) then
			local r, g, b = 0, 0.5, 0.5
			if alive(self._selected_unit) and unit == self._selected_unit then
				r, g, b = 0, 1, 1
			end
			Application:draw(unit, r, g, b)
			unit:unit_data().environment_area:draw(t, dt, r, g, b)
		end
		if self._draw_occ_shape:Value() and unit:name() == Idstring(self._dome_occ_shape_unit) then
			local r, g, b = 0.5, 0, 0.5
			if alive(self._selected_unit) and unit == self._selected_unit then
				r, g, b = 1, 0, 1
			end
			Application:draw(unit, r, g, b)
			unit:unit_data().occ_shape:draw(t, dt, r, g, b)
		end
	end
end
function EnvironmentLayerEditor:draw_wind(pos)
	local rot = Rotation(self._wind_rot:yaw(), self._wind_rot:pitch(), self._wind_rot:roll() * -1)
	self._pen:arrow(pos, pos + rot:x() * 300, 0.25)
	self._pen:arc(pos, pos + rot:x() * 100, self._wind_dir_var, rot:z(), 32)
	self._pen:arc(pos, pos + rot:x() * 100, -self._wind_dir_var, rot:z(), 32)
	self._pen:arc(pos, pos + rot:x() * 100, self._wind_tilt_var, rot:y(), 32)
	self._pen:arc(pos, pos + rot:x() * 100, -self._wind_tilt_var, rot:y(), 32)
end
function EnvironmentLayerEditor:_build_environment_combobox_and_list()
	local ctrlr, combobox_params = CoreEws.combobox_and_list({
		name = "Default",
		panel = self._env_panel,
		sizer = self._environment_sizer,
		options = managers.database:list_entries_of_type("environment"),
		value = self._environment_values.environment,
		value_changed_cb = function(params)
			self:change_environment(params.ctrlr)
		end
	})
	self._environments_combobox = combobox_params
	managers.viewport:editor_add_environment_created_callback(callback(self, self, "on_environment_list_changed"))
end
function EnvironmentLayerEditor:on_environment_list_changed()
	local list = managers.database:list_entries_of_type("environment")
	local selected_value = self._environments_combobox.ctrlr:get_value()
	CoreEws.update_combobox_options(self._environments_combobox, list)
	if table.contains(list, selected_value) then
		self._environments_combobox.ctrlr:set_value(selected_value)
	end
end
function EnvironmentLayerEditor:build_menu()
    local cubemaps = self:Group("Cubemaps")
    self:Button("GenerateAll", callback(self, self, "create_cube_map", "all"), {group = cubemaps})
    self:Button("GenerateSelected", callback(self, self, "create_cube_map", "selected"), {group = cubemaps})
    local environment = self:Group("Environment")
	--self:ComboBox("Environment", callback(self, self, "on_environment_list_changed"), self._environment_values.environment, {group = environment}) -- managers.database:list_entries_of_type("environment")
    --self:_build_environment_combobox_and_list() at end.
    local sky = self:Group("Sky") -- keep?
    self:Slider("SkyRotation", callback(self, self, "change_sky_rotation"), self._sky_rotation, {min = 0, max = 360, group = sky})
    local colors = {
        "color_off",
        "color_payday",
        "color_heat",
        "color_nice",
        "color_sin",
        "color_bhd",
        "color_xgen",
        "color_xxxgen",
        "color_matrix"
    }
    self:ComboBox("ColorGrading", callback(self, self, "change_color_grading"), colors, table.get_key(colors, self._environment_values.color_grading), {group = environment})
    self:ComboBox("Environment", callback(self, self, "set_environment_area"), Global.DBPaths.environment, table.get_key(Global.DBPaths.environment, self._environment_values.environment), {group = environment})
    local env_filter = self:Divider("Filter", {group = environment}) --?
    local filter_count = 0
    local environment_filter_row_sizer
    for name in table.sorted_map_iterator(managers.viewport:get_predefined_environment_filter_map()) do
        self:Toggle(name, callback(self, self, "set_env_filter", name), true, {group = environment})
    end
    -- ???
    self:NumberBox("FadeTime", callback(self, self, "set_transition_time"), managers.environment_area:default_transition_time(), {group = environment})
    self:NumberBox("Prio", callback(self, self, "set_prio"), managers.environment_area:default_prio(), {group = environment})
    self:Toggle("Permanent", callback(self, self, "set_permanent"), self.ENABLE_PERMANENT, {group = environment})
    -- ???
    local dome_occ = self:Group("DomeOcclusion") 
    self._draw_occ_shape = self:Toggle("Draw", nul, false, {group = dome_occ})
    self:Button("Generate", callback(self, self, "generate_dome_occ", "all"), {group = dome_occ})
    self:ComboBox("Resolution", callback(self, self, "set_dome_occ_resolution"), {64, 128, 256, 512, 1024}, self._environment_values.dome_occ_resolution, {group = dome_occ})
    local wind = self:Group("Wind")
    self._draw_wind = self:Toggle("Draw", nil, false, {group = wind})
    self:Slider("WindDirection", callback(self, self, "update_wind_direction"), 0, {min = 0, max = 360, floats = 0, group = wind})
    self:Slider("WindVariation", callback(self, self, "update_wind_variation"), 0, {min = 0, max = 180, floats = 0, group = wind})
    self:Slider("TiltAngle", callback(self, self, "update_tilt_angle"), 0, {min = -90, max = 90, floats = 0, group = wind})
    self:Slider("TiltVariation", callback(self, self, "update_tilt_variation"), 0, {min = -90, max = 90, floats = 0, group = wind})
    self:Slider("Speed", callback(self, self, "update_wind_speed"), self._wind_speed * 10, {min = 0, max = 408, floats = 0, group = wind})
    self._wind_text = self:Divider("Beaufort/WindDesc", {text = "Beaufort: " .. self:wind_beaufort(self._wind_speed) .. " Desc: " .. self:wind_description(self._wind_speed)})
    self:Slider("SpeedVariation", callback(self, self, "update_wind_speed_variation"), self._wind_speed_variation * 10, {min = 0, max = 408, floats = 0, group = wind})
    local effects = self:Group("Effects")
    self:Toggle("Enable", callback(self, self, "change_unit_effect"), true, {group = effects})
     
	--populate_unit_effects add this later
end

function EnvironmentLayerEditor:create_cube_map(type)
	local cubes = {}
	if type == "all" then
		for _, unit in ipairs(self._created_units) do
			if unit:name() == Idstring(self._cubemap_unit) then
				table.insert(cubes, {
					position = unit:position(),
					name = unit:unit_data().name_id,
					output_name = "outputcube"
				})
			end
		end
	elseif type == "selected" and self._selected_unit:name() == Idstring(self._cubemap_unit) then
		table.insert(cubes, {
			position = self._selected_unit:position(),
			name = self._selected_unit:unit_data().name_id,
			output_name = "outputcube"
		})
	end
	local params = {cubes = cubes}
	params.output_path = managers.database:base_path() .. "environments\\cubemaps\\"
	managers.editor:create_cube_map(params)
end

function EnvironmentLayerEditor:change_environment(ctrlr)
	self._environment_values.environment = ctrlr:get_value()
	managers.viewport:set_default_environment(self._environment_values.environment, nil, nil)
end

function EnvironmentLayerEditor:change_color_grading(menu, item)
	self._environment_values.color_grading = item:SelectedItem()
	managers.environment_controller:set_default_color_grading(self._environment_values.color_grading)
	managers.environment_controller:refresh_render_settings()
end

function EnvironmentLayerEditor:set_environment_area()
	local area = self._selected_unit:unit_data().environment_area
	area:set_environment(self._environment_area_ctrls.environment_combobox.value)
end

function EnvironmentLayerEditor:set_permanent()
	local area = self._selected_unit:unit_data().environment_area
	area:set_permanent(self._environment_area_ctrls.permanent_cb:Value())
end

function EnvironmentLayerEditor:set_transition_time()
	local area = self._selected_unit:unit_data().environment_area
	local value = tonumber(self._environment_area_ctrls.transition_time:Value())
	value = math.clamp(value, 0, 100000000)
	self._environment_area_ctrls.transition_time:change_value(string.format("%.2f", value))
	area:set_transition_time(value)
end

function EnvironmentLayerEditor:set_prio()
	local area = self._selected_unit:unit_data().environment_area
	local value = tonumber(self._environment_area_ctrls.prio:Value())
	value = math.clamp(value, 1, 100000000)
	self._environment_area_ctrls.prio:change_value(tostring(value))
	area:set_prio(value)
end

function EnvironmentLayerEditor:set_env_filter(name)
	local area = self._selected_unit:unit_data().environment_area
	local filter_list = {}
	local filter_map = managers.viewport:get_predefined_environment_filter_map()
	for name, env_filter_cb in pairs(self._environment_area_ctrls.env_filter_cb_map) do
		if env_filter_cb:Value() then
			for _, data_path_key in ipairs(filter_map[name]) do
				table.insert(filter_list, data_path_key)
			end
		end
	end
	area:set_filter_list(filter_list)
end

function EnvironmentLayerEditor:_update_filter_list(area)
	local filter_list = area:filter_list()
	local filter_map = managers.viewport:get_predefined_environment_filter_map()
	local categories = {}
	for _, key in ipairs(filter_list) do
		for category, filters in pairs(filter_map) do
			for _, filter in ipairs(filters) do
				if filter == key then
					categories[category] = true
				end
			end
		end
	end
	local new_list = {}
	for c, _ in pairs(categories) do
		table.list_append(new_list, filter_map[c])
	end
	new_list = table.list_union(new_list, filter_list)
	area:set_filter_list(new_list)
end

function EnvironmentLayerEditor:generate_dome_occ()
	local shape
	for _, unit in ipairs(self:created_units()) do
		if unit:name() == Idstring(self._dome_occ_shape_unit) then
			shape = unit:unit_data().occ_shape
		else
		end
	end
	if not shape then
		managers.editor:Error("No dome occ unit in level!")
		return
	end
	local res = self._environment_values.dome_occ_resolution or 256
	managers.editor:init_create_dome_occlusion(shape, res)
end

function EnvironmentLayerEditor:set_dome_occ_resolution()
	self._environment_values.dome_occ_resolution = tonumber(self._dome_occ_resolution_ctrlr:get_value())
end

function EnvironmentLayerEditor:update_wind_direction(menu, item)
	local dir = item:Value()
	self._wind_rot = Rotation(dir, 0, self._wind_rot:roll())
	self:set_wind()
end

function EnvironmentLayerEditor:set_wind()
	Wind:set_direction(self._wind_rot:yaw(), self._wind_dir_var, 5)
	Wind:set_tilt(self._wind_rot:roll(), self._wind_tilt_var, 5)
	Wind:set_speed_m_s(self._wind_speed, self._wind_speed_variation, 5)
	Wind:set_enabled(true)
end

function EnvironmentLayerEditor:update_wind_variation(menu, item)
	self._wind_dir_var = item:Value()
	self:set_wind()
end

function EnvironmentLayerEditor:update_tilt_angle(menu, item)
	local dir = item:Value()
	self._wind_rot = Rotation(self._wind_rot:yaw(), 0, dir)
	self:set_wind()
end

function EnvironmentLayerEditor:update_tilt_variation(menu, item)
	self._wind_tilt_var = item:Value()
	self:set_wind()
end

function EnvironmentLayerEditor:update_wind_speed(menu, item)
	self._wind_speed = item:Value() / 10
	self:update_wind_speed_labels()
	self:set_wind()
end

function EnvironmentLayerEditor:update_wind_speed_variation(menu, item)
	self._wind_speed_variation = item:Value() / 10
	self:update_wind_speed_labels()
	self:set_wind()
end

function EnvironmentLayerEditor:update_wind_speed_labels()
	self._wind_text:SetText("Beaufort: " .. self:wind_beaufort(self._wind_speed) .. " Desc: " .. self:wind_description(self._wind_speed))
end

function EnvironmentLayerEditor:sky_rotation_modifier()
	return self._environment_values.sky_rot, true
end

function EnvironmentLayerEditor:change_sky_rotation(menu, item)
	self._environment_values.sky_rot = item:Value()
	managers.viewport:update_global_environment_value(sky_rot_key)
end

function EnvironmentLayerEditor:kill_effect(unit)
	if unit:name() == Idstring(self._effect_unit) and unit:unit_data().current_effect then
		World:effect_manager():kill(unit:unit_data().current_effect)
		unit:unit_data().current_effect = nil
	end
end
function EnvironmentLayerEditor:change_unit_effect()
	self:kill_effect(self._selected_unit)
	self._unit_effects:SelectedItem()
	self._selected_unit:unit_data().effect = effect
	if DB:has("effect", effect) then
		self._selected_unit:unit_data().current_effect = World:effect_manager():spawn({
			effect = Idstring(effect),
			position = unit:position(),
			rotation = unit:rotation()
		})
	end
end
function EnvironmentLayerEditor:update_unit_settings()
	self._unit_effects:set_enabled(false)
	if alive(self._selected_unit) and self._selected_unit:name() == Idstring(self._effect_unit) then
		self._unit_effects:set_enabled(true)
		self._unit_effects:set_value(self._selected_unit:unit_data().effect or "none")
	end
	self:set_environment_area_parameters()
end
function EnvironmentLayerEditor:set_environment_area_parameters()
	CoreEws.set_combobox_and_list_enabled(self._environment_area_ctrls.environment_combobox, false)
	self._environment_area_ctrls.permanent_cb:set_enabled(false)
	self._environment_area_ctrls.transition_time:set_enabled(false)
	self._environment_area_ctrls.prio:set_enabled(false)
	for _, env_filter_cb in pairs(self._environment_area_ctrls.env_filter_cb_map) do
		env_filter_cb:set_enabled(false)
	end
	if self._current_shape_panel then
		self._current_shape_panel:set_visible(false)
	end
	if alive(self._selected_unit) and self._selected_unit:name() == Idstring(self._environment_area_unit) then
		local area = self._selected_unit:unit_data().environment_area
		if area then
			self._current_shape_panel = area:panel(self._env_panel, self._environment_sizer)
			self._current_shape_panel:set_visible(true)
			CoreEws.set_combobox_and_list_enabled(self._environment_area_ctrls.environment_combobox, true)
			CoreEws.change_combobox_value(self._environment_area_ctrls.environment_combobox, area:environment())
			self._environment_area_ctrls.permanent_cb:set_enabled(self.ENABLE_PERMANENT)
			self._environment_area_ctrls.permanent_cb:set_value(self.ENABLE_PERMANENT and area:permanent())
			self._environment_area_ctrls.transition_time:set_enabled(true)
			self._environment_area_ctrls.transition_time:set_value(string.format("%.2f", area:transition_time()))
			self._environment_area_ctrls.prio:set_enabled(true)
			self._environment_area_ctrls.prio:set_value(tostring(area:prio()))
			local filter_map = managers.viewport:get_predefined_environment_filter_map()
			local filter_list = area:filter_list()
			for name, env_filter_cb in pairs(self._environment_area_ctrls.env_filter_cb_map) do
				env_filter_cb:set_enabled(true)
				env_filter_cb:set_value(filter_list and table.is_list_value_union(filter_map[name], filter_list))
			end
		end
	end
	if alive(self._selected_unit) and self._selected_unit:name() == Idstring(self._dome_occ_shape_unit) then
		local shape = self._selected_unit:unit_data().occ_shape
		if shape then
			self._current_shape_panel = shape:panel(self._env_panel, self._dome_occ_sizer)
			self._current_shape_panel:set_visible(true)
		end
	end
	self._env_panel:layout()
	self._ews_panel:fit_inside()
	self._ews_panel:refresh()
end
function EnvironmentLayerEditor:wind_description(speed)
	local description
	for _, data in ipairs(self._wind_speeds) do
		if speed < data.speed then
			return description
		end
		description = data.description
	end
	return description
end
function EnvironmentLayerEditor:wind_beaufort(speed)
	local beaufort
	for _, data in ipairs(self._wind_speeds) do
		if speed < data.speed then
			return beaufort
		end
		beaufort = data.beaufort
	end
	return beaufort
end
function EnvironmentLayerEditor:reset_environment_values()
	self._environment_values.environment = managers.viewport:game_default_environment()
	self._environment_values.sky_rot = 0
	managers.viewport:update_global_environment_value(CoreEnvironmentFeeder.SkyRotationFeeder.DATA_PATH_KEY)
	self._environment_values.color_grading = managers.environment_controller:game_default_color_grading()
	self._environment_values.dome_occ_resolution = 256
end