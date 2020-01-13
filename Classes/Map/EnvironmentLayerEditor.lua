EnvironmentLayerEditor = EnvironmentLayerEditor or class(LayerEditor)
local sky_rot_key = Idstring("sky_orientation/rotation"):key()
local EnvLayer = EnvironmentLayerEditor
function EnvLayer:init(parent)
	self:init_basic(parent, "EnvironmentLayerEditor")
	self._menu = parent._holder
	ItemExt:add_funcs(self)
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
	self._cubemap_units = {}
	self._created_units = {}
	self._wind_speed = 6
	self._wind_speed_variation = 1
	self._environment_area_unit = "core/units/environment_area/environment_area"
	self._effect_unit = "core/units/effect/effect"
	self._dome_occ_shape_unit = "core/units/dome_occ_shape/dome_occ_shape"
	self._cubemap_unit = "core/units/cubemap_gizmo/cubemap_gizmo"
end

function EnvLayer:loaded_continents()
	EnvLayer.super.loaded_continents(self)

	local data = self:data()
	data.environment_values.environment = managers.worlddefinition:convert_mod_path(data.environment_values.environment)
    for _, area in pairs(deep_clone(data.environment_areas)) do
        if type(area) == "table" and area.environment then
            area.environment = managers.worlddefinition:convert_mod_path(area.environment)
        end
    end
	self:_load_wind(data.wind)
	self:_load_effects(data.effects)
	self:_load_environment_areas()
	self:_load_dome_occ_shapes(data.dome_occ_shapes)
	self:find_cubemaps()
end

function EnvLayer:unit_spawned(unit)
	if unit:name() == self._cubemap_unit:id() and not table.contains(self._cubemap_units, unit) then
		table.insert(self._cubemap_units, unit)
	end
end

function EnvLayer:unit_deleted(unit)
	local ud = unit:unit_data()
	if ud then
		if ud.occ_shape then
			ud.occ_shape:set_unit()
			ud.occ_shape:destroy()
		end
		if ud.environment_area then
			ud.environment_area:set_unit()
			managers.environment_area:remove_area(ud.environment_area)
		end
		if ud.current_effect then
			World:effect_manager():kill(ud.current_effect)
		end
	end
	if unit:name() == self._cubemap_unit:id() then
		table.delete(self._cubemap_units, unit)
	end
end

function EnvLayer:find_cubemaps()
	self._cubemap_units = {}
	for _, unit in pairs(managers.worlddefinition._all_units) do
        if unit:name() == self._cubemap_unit:id() then
            table.insert(self._cubemap_units, unit)
        end
    end
end

function EnvLayer:data() return self._parent:data().environment end

function EnvLayer:is_my_unit(unit)
	if unit == self._environment_area_unit:id() or unit == self._effect_unit:id() or unit == self._dome_occ_shape_unit:id() then
		return true
	end
	return false
end

function EnvLayer:_load_wind(wind)
	self._wind_rot = self._wind_rot or Rotation(wind.angle, 0, wind.tilt)
	self._wind_dir_var = self._wind_dir_var or wind.angle_var
	self._wind_tilt_var = self._wind_tilt_var or wind.tilt_var
	self._wind_speed = self._wind_speed or wind.speed
	self._wind_speed_variation = self._wind_speed_variation or wind.speed_variation
	self:set_wind()
end

function EnvLayer:_load_effects(effects)
	for _, effect in ipairs(effects) do
		local unit = self:do_spawn_unit(self._effect_unit, {name_id = effect.name_id, effect = effect.effect, position = effect.position, rotation = effect.rotation})
		self:play_effect(unit, effect.name)
	end
	self:save()
end

function EnvLayer:_load_environment_areas()
	for _, area in ipairs(managers.environment_area:areas()) do
		local unit = self:do_spawn_unit(self._environment_area_unit, {environment_area = area, position = area:position(), rotation = area:rotation()})
		local new_name_id = unit:unit_data().environment_area:set_unit(unit)
		if new_name_id then
			unit:unit_data().name_id = new_name_id
		end
	end
	self:save()
end

function EnvLayer:_load_dome_occ_shapes(dome_occ_shapes)
	if not dome_occ_shapes then
		return
	end
	for _, dome_occ_shape in ipairs(dome_occ_shapes) do
		local unit = self:do_spawn_unit(self._dome_occ_shape_unit, {position = dome_occ_shape.position, rotation = dome_occ_shape.rotation})
		unit:unit_data().occ_shape = CoreShapeManager.ShapeBox:new(dome_occ_shape)
		unit:unit_data().occ_shape:set_unit(unit)
	end
	self:save()
end

function EnvLayer:save()
	local effects = {}
	local environment_areas = {}
	local environment_paths = {}
	local cubemap_gizmos = {}
	local dome_occ_shapes = {}
	for _, unit in ipairs(self._created_units) do
		if alive(unit) then
			if unit:name() == self._effect_unit:id() then
				local effect = unit:unit_data().effect or "none"
				local name_id = unit:unit_data().name_id or "none"
				table.insert(effects, {
					name = effect,
					name_id = name_id,
					position = unit:position(),
					rotation = unit:rotation()
				})
			elseif unit:name() == self._environment_area_unit:id() then
				local area = unit:unit_data().environment_area
				self:_update_filter_list(area)
				table.insert(environment_areas, area:save_level_data())
			elseif unit:name() == self._dome_occ_shape_unit:id() then
				local shape = unit:unit_data().occ_shape
				table.insert(dome_occ_shapes, shape:save_level_data())
			end
		end
	end
	local data = self:data()
	self._parent:data().environment = {
		environment_values = data.environment_values,
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

function EnvLayer:reset_selected_units()
	for k, unit in ipairs(clone(self._created_units)) do
		if not alive(unit) then
			table.remove(self._created_units, k)
		end
	end
	self:save()
end

function EnvLayer:update(t, dt)
	if self._draw_wind and self._draw_wind:Value() then
		for i = -0.9, 1.2, 0.3 do
			for j = -0.9, 1.2, 0.3 do
				self:draw_wind(managers.editor:screen_to_world(Vector3(j, i, 0), 1000))
			end
		end
	end

	if self:Val("EnvironmentUnits") then
		local selected_units = self:selected_units()
		for _, unit in pairs(self._cubemap_units) do
			if alive(unit) then
				Application:draw_sphere(unit:position(), 30, 1, 1, 1)
			end
		end
		for _, unit in pairs(self._created_units) do
			if alive(unit) then
				if unit:unit_data().current_effect then
					World:effect_manager():move(unit:unit_data().current_effect, unit:position())
					World:effect_manager():rotate(unit:unit_data().current_effect, unit:rotation())
				end
				if unit:name() == Idstring(self._effect_unit) then
					local r,g,b = 0, 0, 1
					if table.contains(selected_units, unit) then
						r, g, b = 0, 1, 1
					end
					Application:draw(unit, r, g, b)
				end
				if unit:name() == Idstring(self._environment_area_unit) then
					local r, g, b = 0, 0.5, 0.5
					if table.contains(selected_units, unit) then
						r, g, b = 0, 1, 1
					end
					Application:draw(unit, r, g, b)
					unit:unit_data().environment_area:draw(t, dt, r, g, b)
				end		
				if unit:name() == Idstring(self._dome_occ_shape_unit) then
					local r, g, b = 0.5, 0, 0.5
					if table.contains(selected_units, unit) then
						r, g, b = 1, 0, 1
					end
					Application:draw(unit, r, g, b)
					unit:unit_data().occ_shape:draw(t, dt, r, g, b)
				end
			end
		end
	end
end

function EnvLayer:draw_wind(pos)
	local rot = Rotation(self._wind_rot:yaw(), self._wind_rot:pitch(), self._wind_rot:roll() * -1)
	self._pen:arrow(pos, pos + rot:x() * 300, 0.25)
	self._pen:arc(pos, pos + rot:x() * 100, self._wind_dir_var, rot:z(), 32)
	self._pen:arc(pos, pos + rot:x() * 100, -self._wind_dir_var, rot:z(), 32)
	self._pen:arc(pos, pos + rot:x() * 100, self._wind_tilt_var, rot:y(), 32)
	self._pen:arc(pos, pos + rot:x() * 100, -self._wind_tilt_var, rot:y(), 32)
end

function EnvLayer:build_menu()
	local data = self:data()
	local environment_values = data.environment_values

    local environment_group = self:group("Environment")
	environment_group:pathbox("Environment", ClassClbk(self, "change_environment"), environment_values.environment, "environment", {not_close = true})
    local sky = self:group("Sky")
    sky:slider("SkyRotation", ClassClbk(self, "change_sky_rotation"), environment_values.sky_rot, {min = 0, max = 360})
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

	environment_group:button("BuildCubemaps", function()
		local cubes = self:selected_unit() and "selected" or "all"
		if not self:selected_unit() then 
			BLE.Utils:YesNoQuestion("No cubemap gizmos were selected. Would you like to build cubemaps for all gizmos in the level?",
			function()
				self:create_cube_map("all")
			end)
		else
			BLE.Utils:YesNoQuestion("Would you like to build cubemaps for all selected gizmos in the level?",
			function()
				self:create_cube_map("selected")
			end)
		end
	end)
	environment_group:button("BuildProjectionLights", function()
		local lights = self:selected_unit() and self:selected_unit():get_object(Idstring("lo_omni")) or nil
		if not lights then 
			BLE.Utils:YesNoQuestion("No lights were selected. Would you like to build projection lights for all lights in the level?",
			function()
				self:GetPart("cubemap_creator"):create_projection_light("all")
			end)
		else 
			BLE.Utils:YesNoQuestion("Would you like to build projection lights for all selected lights in the level?",
			function()
				self:GetPart("cubemap_creator"):create_projection_light("selected") 
			end)
		end
	end)
    environment_group:combobox("ColorGrading", ClassClbk(self, "change_color_grading"), colors, table.get_key(colors, environment_values.color_grading))

	local utils = self:GetPart("world")
    environment_group:button("SpawnEffect", ClassClbk(utils, "BeginSpawning", self._effect_unit))
    environment_group:button("SpawnEnvironmentArea", ClassClbk(utils, "BeginSpawning", self._environment_area_unit))

	local dome_occ = self:group("DomeOcclusion", {visible = true}) 
    --self._draw_occ_shape = dome_occ:tickbox("Draw", nil, false)
    dome_occ:button("SpawnDomeOcclusion", ClassClbk(utils, "BeginSpawning", self._dome_occ_shape_unit))	
	dome_occ:button("Generate", ClassClbk(self, "generate_dome_occ", "all"))
    local res = {64, 128, 256, 512, 1024, 2048, 4096}
    dome_occ:combobox("Resolution", ClassClbk(self, "set_dome_occ_resolution"), res, table.get_key(res, environment_values.dome_occ_resolution or 256))

	local wind = self:group("Wind")
    self._draw_wind = wind:tickbox("Draw", nil, false)
    wind:slider("WindDirection", ClassClbk(self, "update_wind_direction"), 0, {min = 0, max = 360, floats = 0})
    wind:slider("WindVariation", ClassClbk(self, "update_wind_variation"), 0, {min = 0, max = 180, floats = 0})
    wind:slider("TiltAngle", ClassClbk(self, "update_tilt_angle"), 0, {min = -90, max = 90, floats = 0})
    wind:slider("TiltVariation", ClassClbk(self, "update_tilt_variation"), 0, {min = -90, max = 90, floats = 0})
    wind:slider("Speed", ClassClbk(self, "update_wind_speed"), self._wind_speed * 10, {min = 0, max = 408, floats = 0})
    self._wind_text = self:divider("Beaufort/WindDesc")
    self:update_wind_speed_labels()
    wind:slider("SpeedVariation", ClassClbk(self, "update_wind_speed_variation"), self._wind_speed_variation * 10, {min = 0, max = 408, floats = 0})
end

function EnvLayer:build_unit_menu()
	local S = self:GetPart("static")
	S._built_multi = false
	S.super.build_default_menu(S)
	local unit = self:selected_unit()
	if alive(unit) then
		S:build_positions_items(true)
		S:update_positions()
		if unit:name() == self._effect_unit:id() then
			S:SetTitle("Effect Selection")
            local effect = S:group("Effect", {index = 1})
		    effect:textbox("Name", ClassClbk(self, "set_unit_name_id"), unit:unit_data().name_id or "")
			self._unit_effects = effect:pathbox("Effect", ClassClbk(self, "change_unit_effect"), self:selected_unit():unit_data().effect or "none", "effect")	
		elseif unit:name() == self._environment_area_unit:id() then
			S:SetTitle("Environment Area Selection")
			local area = unit:unit_data().environment_area
		    self._environment_area_ctrls = {env_filter_cb_map = {}}
            local ctrls = self._environment_area_ctrls
            local area_pan = S:group("Environment Area", {index = 1})
		    area_pan:textbox("Name", ClassClbk(self, "set_unit_name_id"), unit:unit_data().name_id or "")

            local env = area:environment() or managers.viewport:game_default_environment()
		    ctrls.environment_path = area_pan:pathbox("AreaEnvironment", ClassClbk(self, "set_environment_area"), env, "environment", {
				text = "Environment",
                control_slice = 0.6,
			})
		    ctrls.transition_time = area_pan:numberbox("FadeTime", ClassClbk(self, "set_transition_time"), area:transition_time() or managers.environment_area:default_transition_time(), {
                floats = 2,
            })
		    ctrls.prio = area_pan:numberbox("Prio", ClassClbk(self, "set_prio"), area:prio() or managers.environment_area:default_prio())
		    ctrls.permanent_cb = area_pan:tickbox("Permanent", ClassClbk(self, "set_permanent"), area:permanent() or self.ENABLE_PERMANENT)

		    local env_filter = area_pan:divgroup("Filter", {align_method = "grid"})
		    local filter_count = 0
		    local filter_map = managers.viewport:get_predefined_environment_filter_map()
		    local filter_list = area:filter_list()
		    for name in table.sorted_map_iterator(managers.viewport:get_predefined_environment_filter_map()) do
		        ctrls.env_filter_cb_map[name] = env_filter:tickbox(name, ClassClbk(self, "set_env_filter", name), filter_list and table.is_list_value_union(filter_map[name], filter_list), {
                    size_by_text = true
                })
		    end
		    if area then
		    	area:create_panel(S, S:GetItem("Transform"))
		    end  
		elseif unit:name() == self._dome_occ_shape_unit:id() then
			S:SetTitle("Dome Occlusion Selection")
			local area = unit:unit_data().occ_shape
			if area then
				area:create_panel(S, S:GetItem("Transform"))
			end
		end
	end
end

function EnvLayer:update_positions() self:set_unit_pos() end

function EnvLayer:set_unit_pos(item)
	local unit = self:selected_unit()
	local S = self:GetPart("static")
	if unit then
		unit:set_position(S:GetItem("Position"):Value())
		unit:set_rotation(S:GetItem("Rotation"):Value())
		unit:unit_data().position = unit:position()
		unit:unit_data().rotation = unit:rotation()		
	end
	self:save()
end

function EnvLayer:set_unit_name_id(item)
	local unit = self:selected_unit()
	if unit then
		unit:unit_data().name_id = item:Value()
	end
	self:save()
end

function EnvLayer:change_environment(item)
	local environment_values = self:data().environment_values
	environment_values.environment = item:Value()
	managers.viewport:set_default_environment(environment_values.environment, nil, nil)
	self:save()
end

function EnvLayer:change_color_grading(item)
	local environment_values = self:data().environment_values
	environment_values.color_grading = item:SelectedItem()
	managers.environment_controller:set_default_color_grading(environment_values.color_grading)
	managers.environment_controller:refresh_render_settings()
	self:save()
end

function EnvLayer:set_environment_area(env)
	local area = self:selected_unit():unit_data().environment_area
	area:set_environment(self._environment_area_ctrls.environment_path.Value())
	self:save()
end

function EnvLayer:set_permanent()
	local area = self:selected_unit():unit_data().environment_area
	area:set_permanent(self._environment_area_ctrls.permanent_cb:Value())
	self:save()
end

function EnvLayer:set_transition_time()
	local area = self:selected_unit():unit_data().environment_area
	local value = tonumber(self._environment_area_ctrls.transition_time:Value())
	value = math.clamp(value, 0, 100000000)
	self._environment_area_ctrls.transition_time:SetValue(value)
	area:set_transition_time(value)
	self:save()
end

function EnvLayer:set_prio()
	local area = self:selected_unit():unit_data().environment_area
	local value = tonumber(self._environment_area_ctrls.prio:Value())
	value = math.clamp(value, 1, 100000000)
	self._environment_area_ctrls.prio:SetValue(value)
	area:set_prio(value)
	self:save()
end

function EnvLayer:set_env_filter(name)
	local area = self:selected_unit():unit_data().environment_area
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
	self:save()
end

function EnvLayer:_update_filter_list(area)
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

--Unfuctional, when attempting to copy ovk's code everything seems to work fine but the result of the dome occlusion is weird
--and makes the shadows look wrong so sadly I would probably not bother with dome occlusion.
function EnvLayer:generate_dome_occ()
	local shape
	for _, unit in ipairs(self._created_units) do
		if unit:name() == Idstring(self._dome_occ_shape_unit) then
			shape = unit:unit_data().occ_shape

			break
		end
	end

	if not shape then
		managers.editor:Error("No dome occ unit in level!")
		return
	end
	local res = self:data().environment_values.dome_occ_resolution or 256

	self:GetPart("cubemap_creator"):create_dome_occlusion(shape, res)
end

function EnvLayer:set_dome_occ_resolution(item)
	self:data().environment_values.dome_occ_resolution = tonumber(item:SelectedItem())
	self:save()
end

function EnvLayer:update_wind_direction(item)
	local dir = item:Value()
	self._wind_rot = Rotation(dir, 0, self._wind_rot:roll())
	self:set_wind()
end

function EnvLayer:set_wind()
	Wind:set_direction(self._wind_rot:yaw(), self._wind_dir_var, 5)
	Wind:set_tilt(self._wind_rot:roll(), self._wind_tilt_var, 5)
	Wind:set_speed_m_s(self._wind_speed, self._wind_speed_variation, 5)
	Wind:set_enabled(true)
	self:save()
end

function EnvLayer:update_wind_variation(item)
	self._wind_dir_var = item:Value()
	self:set_wind()
end

function EnvLayer:update_tilt_angle(item)
	local dir = item:Value()
	self._wind_rot = Rotation(self._wind_rot:yaw(), 0, dir)
	self:set_wind()
end

function EnvLayer:update_tilt_variation(item)
	self._wind_tilt_var = item:Value()
	self:set_wind()
end

function EnvLayer:update_wind_speed(item)
	self._wind_speed = item:Value() / 10
	self:update_wind_speed_labels()
	self:set_wind()
end

function EnvLayer:update_wind_speed_variation(item)
	self._wind_speed_variation = item:Value() / 10
	self:update_wind_speed_labels()
	self:set_wind()
end

function EnvLayer:update_wind_speed_labels()
	self._wind_text:SetText("Beaufort Scale: " .. self:wind_beaufort(self._wind_speed) .. "(" .. self:wind_description(self._wind_speed)..")")
end

function EnvLayer:change_sky_rotation(item)
 	self:data().environment_values.sky_rot = item:Value()
	self:save()
	managers.viewport:first_active_viewport()._env_handler:editor_set_value(sky_rot_key, item:Value()) -- I guess this works
end

function EnvLayer:kill_effect(unit)
	if unit:name() == Idstring(self._effect_unit) and unit:unit_data().current_effect then
		World:effect_manager():kill(unit:unit_data().current_effect)
		unit:unit_data().current_effect = nil
	end
end

function EnvLayer:change_unit_effect()
	local unit = self:selected_unit()
	self:kill_effect(unit)
	self:play_effect(unit, self._unit_effects:Value())
	self:save()
end

function EnvLayer:play_effect(unit, effect)
	unit:unit_data().effect = effect
	if PackageManager:has(Idstring("effect"), effect:id()) then
		unit:unit_data().current_effect = World:effect_manager():spawn({
			effect = effect:id(),
			position = unit:position(),
			rotation = unit:rotation()
		})
	end
end

function EnvLayer:do_spawn_unit(unit_path, mud)
	local unit = World:spawn_unit(unit_path:id(), mud.position or Vector3(), mud.rotation or Rotation())
	table.merge(unit:unit_data(), mud)
	local ud = unit:unit_data()
	ud.name = unit_path
	ud.environment_unit = true
	ud.position = unit:position()
	ud.rotation = unit:rotation()
	ud.env_unit = true
	table.insert(self._created_units, unit)
	if alive(unit) then
		if unit:name() == Idstring(self._environment_area_unit) then
			local area = ud.environment_area
			if area and not alive(area:unit()) then
				area:set_unit(unit)
			end
			if not area or area:unit() ~= unit then
				ud.environment_area = managers.environment_area:add_area(area and area:save_level_data() or {})
				ud.environment_area:set_unit(unit)
			end
		end
		if unit:name() == Idstring(self._dome_occ_shape_unit) then
			if not ud.occ_shape then
				ud.occ_shape = CoreShapeManager.ShapeBox:new({})
				ud.occ_shape:set_unit(unit)
			end
		end
	end
	self:save()
	return unit
end

function EnvLayer:wind_description(speed)
	local description
	for _, data in ipairs(self._wind_speeds) do
		if speed < data.speed then
			return description
		end
		description = data.description
	end
	return description
end

function EnvLayer:wind_beaufort(speed)
	local beaufort
	for _, data in ipairs(self._wind_speeds) do
		if speed < data.speed then
			return beaufort
		end
		beaufort = data.beaufort
	end
	return beaufort
end

function EnvLayer:reset_environment_values()
	local environment_values = self:data().environment_values
	environment_values.environment = managers.viewport:game_default_environment()
	environment_values.sky_rot = 0
	managers.viewport:update_global_environment_value(CoreEnvironmentFeeder.SkyRotationFeeder.DATA_PATH_KEY)
	environment_values.color_grading = managers.environment_controller:game_default_color_grading()
	environment_values.dome_occ_resolution = 256
end


function EnvLayer:create_cube_map(selection, type)
	local cubes = {}

	if selection == "all" then
		for _, unit in pairs(World:find_units_quick("all")) do
			if alive(unit) and unit:name() == self._cubemap_unit:id() then
				table.insert(cubes, {
					output_name = unit:unit_data().unit_id,
					position = unit:position(),
					name = unit:unit_data().name_id,
					resolution = unit:unit_data().cubemap_resolution
				})
			end
		end
	elseif selection == "selected" then
		for _, unit in pairs(self:selected_units()) do
			if unit:name() == self._cubemap_unit:id() then
				table.insert(cubes, {
					output_name = unit:unit_data().unit_id,
					position = unit:position(),
					name = unit:unit_data().name_id,
					resolution = unit:unit_data().cubemap_resolution
				})
			end
		end
	end

	if next(cubes) == nil then
		BLE.Utils:Notify("Info", "No cubemap gizmos were found.\nYou need to have at least cubemap gizmo to build cubemaps")
		return
	end

	local params = {
		cubes = cubes,
		source_path = BLE.ModPath .. "\\Tools" .. "\\temp\\"
	}

	self:GetPart("cubemap_creator"):create_cube_map(params)
end