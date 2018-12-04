CubemapCreator = CubemapCreator or class(EditorPart)

function CubemapCreator:init(parent, menu, cam)
    self._parent = parent
	
	self._camera = cam
    self._cube_counter = 1
	self._creating_cube_map = false
	
	self:_init_paths()
end

function CubemapCreator:_init_paths()
	-- need to encase it in ""
	self._gen_path = string.format("\"%s\"", Path:Combine(Application:base_path(), BLE.ModPath, "Tools", "gen_cubemap.py"))
	self._cubelights_path = "levels/mods/" .. Global.game_settings.level_id .. "/cube_lights"
	self._cubemaps_path = "levels/mods/" .. Global.game_settings.level_id .. "/cubemaps"
	self._temp_path = BLE.ModPath .. "Tools/" .. "temp/"
	FileIO:MakeDir(self._temp_path)
end

function CubemapCreator:update(t, dt)
	if self._creating_cube_map then
        self:_create_cube_map()
        
		return
	elseif self._params and self._params.dome_occ then
		self:_tick_generate_dome_occlusion(t, dt)
	end

end

function CubemapCreator:create_projection_light(type)
	local lights = {}
	local units = {}

	if type == "all" then
		for _, unit in pairs(World:find_units_quick("all")) do
			if alive(unit) and unit:unit_data() and unit:unit_data().name then
				local light_name = BLE.Utils:HasProjectionLight(unit, "shadow_projection")

				if light_name then
					table.insert(units, {
						unit = unit,
						light_name = light_name
					})
				end
			end
		end
	elseif type == "selected" then
		local s_units = self:selected_units()
		for _, unit in pairs(s_units) do
			local light_name = BLE.Utils:HasProjectionLight(unit, "shadow_projection")

			if light_name then
				table.insert(units, {
					unit = unit,
					light_name = light_name
				})
			end
		end
	end

	self._saved_all_lights = {}

	
	for _, light in ipairs(CoreEditorUtils.all_lights()) do
		if alive(light) then
			table.insert(self._saved_all_lights, {
				light = light,
				enabled = light:enable()
			})
		end
	end

	for _, data in pairs(units) do
		local unit = data.unit
		local light = unit:get_object(Idstring(data.light_name))
		local enabled = light:enable()
		local resolution = unit:unit_data().projection_lights and unit:unit_data().projection_lights[data.light_name] and unit:unit_data().projection_lights[data.light_name].x
		resolution = resolution or EditUnitLight.DEFAULT_SHADOW_RESOLUTION
		table.insert(lights, {
			name = "",
			position = light:position(),
			unit = unit,
			light = light,
			enabled = enabled,
			spot = false,
			resolution = resolution,
			output_name = unit:unit_data().unit_id
		})
		light:set_enable(false)
	end

	if #lights == 0 then
		return
	end

	for _, data in pairs(self._saved_all_lights) do
		data.light:set_enable(false)
	end

	self:viewport():vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("projection_generation"))
	self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project"))

	local saved_environment = managers.viewport:default_environment()

	managers.viewport:set_default_environment("core/environments/default", nil, nil)
	self:create_cube_map({
		simple_postfix = true,
		cubes = lights,
		saved_environment = saved_environment,
		lights = true
	})
end

function CubemapCreator:create_cube_map(params)
	self._parent:set_camera_fov(500)
	self:viewport():set_width_mul_enabled(false)

	self._cubemap_params = params
	self._cubes_que = clone(params.cubes)

	if #self._cubes_que == 0 then
		table.insert(self._cubes_que, {
			name = "camera",
			position = self._camera:position()
		})
	end

	self._saved_resolution = RenderSettings.resolution	-- fixed aspect ratio
	self._saved_camera = {
		aspect_ratio = self._saved_resolution.x / self._saved_resolution.y,
		pos = self._camera:position(),
		rot = self._camera:rotation(),
		fov = self._parent:camera_fov(),
		near_range = self._camera:near_range(),
		far_range = self._camera:far_range()
	}

	self._camera:set_aspect_ratio(1)
	self._camera:set_width_multiplier(1)

	self._parent._menu:Toggle()

	self._saved_hidden_object = {}
	self._saved_hidden_units = {}
	self._saved_hidden_elements = {}
	
	local elements = self:GetPart("mission"):units()
	for _, unit in pairs(elements) do
        local element_unit = unit:mission_element()
        if element_unit and unit:enabled() then
			table.insert(self._saved_hidden_elements, element_unit)
			element_unit:set_enabled(false)
        end
    end
	for _, unit in pairs(World:find_units_quick("all")) do
		local ud = unit:unit_data()
		if type(ud) == "table" and (ud.only_visible_in_editor or ud.only_exists_in_editor or ud.hide_on_projection_light) then
			if unit:visible() then 
				table.insert(self._saved_hidden_units, unit)
				unit:set_visible(false)
			end
		end
	end

	if managers.viewport and managers.viewport._sun_flare_effect then
		managers.viewport._sun_flare_effect._sf_panel:hide()
	end

	self:next_cube()
end

function CubemapCreator:create_dome_occlusion(shape, res)
	managers.editor:disable_all_post_effects(true)
	self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("render_dome_occ"))

	self._aa_setting = managers.environment_controller:get_aa_setting()

	managers.environment_controller:set_aa_setting("AA_off")

	local saved_environment = managers.viewport:default_environment()
	local params = {
		res = res,
		shape = shape,
		saved_environment = saved_environment
	}

	self:_create_dome_occlusion(params)
end

function CubemapCreator:next_cube()
	if #self._cubes_que > 0 then
		local cube = table.remove(self._cubes_que, 1)

        self._camera:set_position(cube.position)
        self._camera:set_rotation(self._saved_camera.rot)

		local resolution = cube.resolution or 512

		self._parent:_set_fixed_resolution(Vector3(resolution + 4, resolution + 4, 0))

		local params = {
			done_callback = callback(self, self, "cube_map_done"),
			name = cube.name,
			simple_postfix = self._cubemap_params.simple_postfix,
			source_path = self._temp_path,
			output_path = self._cubelights_path,
			output_name = cube.output_name or "cubemap",
			unit = cube.unit,
			light = cube.light,
			spot = cube.spot
		}

		self:start_cube_map(params)

		return true
	end

	return false
end

function CubemapCreator:start_cube_map(params)
	self._params = params
	self._cubemap_name = params.name or ""
	self._simple_postfix = params.simple_postfix
	self._output_name = params.output_name
	self._error_when_done = false

	if params.light then
		self._light = World:create_light("omni")

		self._light:set_position(params.light:position())
		self._light:set_near_range(params.light:near_range())
		self._light:set_far_range(params.light:far_range())
		self._light:set_color(Vector3(1, 1, 1))

		--[[if self._params.spot then
			local rot = Rotation(self._params.unit:rotation():z(), Vector3(0, 0, 1))
			rot = Rotation(-rot:z(), rot:y())

			self._params.unit:set_rotation(rot)
		end]]
	end

	self._camera:set_fov(90) -- self._params.spot and self._params.light:spot_angle_end() or

	self._cube_counter = 0
	self._wait_frames = 10
	self._creating_cube_map = true
	self._cube_map_done_func = params.done_callback
	self._names = {}

	table.insert(self._names, self._cubemap_name .. (self._simple_postfix and "6.tga" or "_6_zpos.tga"))
	table.insert(self._names, self._cubemap_name .. (self._simple_postfix and "1.tga" or "_1_xneg.tga"))
	table.insert(self._names, self._cubemap_name .. (self._simple_postfix and "4.tga" or "_4_ypos.tga"))
	table.insert(self._names, self._cubemap_name .. (self._simple_postfix and "2.tga" or "_2_xpos.tga"))
	table.insert(self._names, self._cubemap_name .. (self._simple_postfix and "3.tga" or "_3_yneg.tga"))
	table.insert(self._names, self._cubemap_name .. (self._simple_postfix and "5.tga" or "_5_zneg.tga"))

	self._name_ordered = {}

	table.insert(self._name_ordered, self._names[2])
	table.insert(self._name_ordered, self._names[4])
	table.insert(self._name_ordered, self._names[5])
	table.insert(self._name_ordered, self._names[3])
	table.insert(self._name_ordered, self._names[6])
	table.insert(self._name_ordered, self._names[1])
end

function CubemapCreator:creating_cube_map()
	return self._creating_cube_map
end

function CubemapCreator:_create_cube_map()
	if self._wait_frames > 0 then
		self._wait_frames = self._wait_frames - 1
        return false
	end

	self._cube_counter = self._cube_counter + 1

	--[[if self._params.spot then
		if self._cube_counter == 1 then
			self:_create_spot_projection()
		elseif self._cube_counter == 2 then
			self:_generate_spot_projection()
		else
			self:_cubemap_done()
		end

		return true
	end]]

	if self._cube_counter == 1 then
        self._camera:set_rotation(Rotation(Vector3(0, 0, 1), Vector3(0, -1, 0)))
        self._wait_frames = 50
	elseif self._cube_counter == 2 then
        self._camera:set_rotation(Rotation(Vector3(-1, 0, 0), Vector3(0, -1, 0)))
        self._wait_frames = 50
	elseif self._cube_counter == 3 then
        self._camera:set_rotation(Rotation(Vector3(0, 1, 0), Vector3(0, 0, -1)))
        self._wait_frames = 50
	elseif self._cube_counter == 4 then
        self._camera:set_rotation(Rotation(Vector3(1, 0, 0), Vector3(0, -1, 0)))
        self._wait_frames = 50
	elseif self._cube_counter == 5 then
        self._camera:set_rotation(Rotation(Vector3(0, -1, 0), Vector3(0, 0, 1)))
        self._wait_frames = 50
	elseif self._cube_counter == 6 then
        self._camera:set_rotation(Rotation(Vector3(0, 0, -1), Vector3(0, -1, 0)))
        self._wait_frames = 50
	elseif self._cube_counter == 7 then
		self:_generate_cubemap(self._params.light and "light" or "reflect")
		self:_cubemap_done()

		return true
	end

	local x1, y1, x2, y2 = self:_get_screen_size()

	local path = self._params.source_path
	Application:screenshot(path .. self._names[self._cube_counter], x1, y1, x2, y2)

	return false
end

function CubemapCreator:_create_spot_projection()
	local res = RenderSettings.resolution

	self._camera:set_rotation(Rotation(-self._params.light:rotation():z(), Vector3(0, 0, 1)))

	local path = self._params.source_path

	Application:screenshot(path .. self._name_ordered[1], 0, 0, res.x, res.y)
end

function CubemapCreator:_create_dome_occlusion(params)
	self._dome_occlusion_params = params
	self._params = table.merge(params, {
		source_path = self._temp_path,
		output_path = self._cubelights_path,
		output_name = "dome_occlusion",
		dome_occ = true
	})

	self._saved_resolution = RenderSettings.resolution
	self._saved_camera = {
		aspect_ratio = self._saved_resolution.x / self._saved_resolution.y,
		pos = self._camera:position(),
		rot = self._camera:rotation(),
		fov = self._parent:camera_fov(),
		near_range = self._camera:near_range(),
		far_range = self._camera:far_range()
	}

	assert(self:viewport():push_ref_fov(500))
	self:viewport():set_width_mul_enabled(false)
	self._parent:_set_fixed_resolution(Vector3(self._params.res, self._params.res, 0))


	self._camera:set_aspect_ratio(1)
	self._camera:set_width_multiplier(1)

	self._parent._menu:Toggle()

	self._saved_hidden_object = {}
	self._saved_hidden_units = {}
	self._saved_hidden_elements = {}
	
	local elements = self:GetPart("mission"):units()
	for _, unit in pairs(elements) do
        local element_unit = unit:mission_element()
        if element_unit and unit:enabled() then
			table.insert(self._saved_hidden_elements, element_unit)
			element_unit:set_enabled(false)
        end
    end
	for _, unit in pairs(World:find_units_quick("all")) do
		local ud = unit:unit_data()
		if type(ud) == "table" and (ud.only_visible_in_editor or ud.only_exists_in_editor or ud.hide_on_projection_light) then
			if unit:visible() then 
				table.insert(self._saved_hidden_units, unit)
				unit:set_visible(false)
			end
		end
	end

	if managers.viewport and managers.viewport._sun_flare_effect then
		managers.viewport._sun_flare_effect._sf_panel:hide()
	end

	local shape = self._params.shape
	local corner = shape:position()
	local w = shape:depth()
	local d = shape:width()
	local h = shape:height()
	local x = corner.x + w / 2
	local y = corner.y - d / 2
	local fov = 4
	local far_range = math.max(w, d) / 2 / math.tan(fov / 2)
	local z = corner.z + far_range

	self._camera:set_far_range(far_range + 10000)
	self._parent:set_camera(Vector3(x, y, z), Rotation(0, -90, 0))
	self._parent:set_camera_fov(fov)

	local deferred_processor = self:viewport():vp():get_post_processor_effect("World", Idstring("depth_projection"))

	if not deferred_processor then
		self:dome_occlusion_done()

		return
	end

	local post_dome_occ = deferred_processor:modifier(Idstring("post_dome_occ"))
	self._dome_occ_corner = corner
	self._dome_occ_size = Vector3(w, d, h)
	local dome_occ_feed = post_dome_occ:material()

	if dome_occ_feed then
		dome_occ_feed:set_variable(Idstring("dome_occ_pos"), self._dome_occ_corner)
		dome_occ_feed:set_variable(Idstring("dome_occ_size"), self._dome_occ_size)
	end

	self._params.step = 0

	self:generate_dome_occlusion(self._temp_path)
end

function CubemapCreator:generate_dome_occlusion(path)
	local x1, y1, x2, y2 = self:_get_screen_size()

	Application:screenshot(path .. self._params.output_name .. ".tga", x1, y1, x2, y2)
end

function CubemapCreator:_tick_generate_dome_occlusion(t, dt)
    if self._params and self._params.dome_occ then
        self._params.step = self._params.step + 1

        if self._params.step == 2 then
            self:_generate_cubemap("dome_occ")
        elseif self._params.step == 3 then
            self:dome_occlusion_done()
        end
    end
end

function CubemapCreator:cube_map_done()
	if self:next_cube() then
		return
	end

	if self._error_when_done then
		BLE.Utils:Notify("Error", "Something went wrong during the creation of cubemaps! Check the log in the Tools folder for more info.")
		self._error_when_done = false
	end
	
	if self._cubemap_params.saved_environment then
		managers.viewport:set_default_environment(self._cubemap_params.saved_environment, nil, nil)
	end

	if self._saved_all_lights then
		for k, data in pairs(self._saved_all_lights) do
			data.light:set_enable(data.enabled)
		end

		self._saved_all_lights = nil
	end

	if self._cubemap_params.lights then
		managers.editor:update_post_effects()
		self:viewport():vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("deferred_lighting"))
		self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project_empty"))
		
		for _, cube in pairs(self._cubemap_params.cubes) do
			cube.light:set_enable(cube.enabled)
		end
	end

	for _, unit in pairs(self._saved_hidden_units) do
		unit:set_visible(true)
	end

	for _, element_unit in pairs(self._saved_hidden_elements) do
		element_unit:set_enabled(true)
	end

	if managers.viewport and managers.viewport._sun_flare_effect then
		managers.viewport._sun_flare_effect._sf_panel:show()
	end

	if self._saved_camera then
        self._camera:set_position(self._saved_camera.pos)
        self._camera:set_rotation(self._saved_camera.rot)
		self._parent:set_camera_fov(self._saved_camera.fov)
		self._camera:set_aspect_ratio(self._saved_camera.aspect_ratio)
		self._camera:set_near_range(self._saved_camera.near_range)
		self._camera:set_far_range(self._saved_camera.far_range)

		self._saved_camera = nil
	end

	self._parent:_set_fixed_resolution(self._saved_resolution)
	self:viewport():set_width_mul_enabled(true)
	self:viewport():pop_ref_fov()

	self._parent._menu:Toggle()

	self._params = nil
end

function CubemapCreator:dome_occlusion_done()
	if not self._params.dome_occ then
		Application:error("CoreEditor:dome_occlusion_done. Generate has not been started")

		return
	end

	if self._params.saved_environment then
		managers.viewport:set_default_environment(self._params.saved_environment, nil, nil)
	end

	managers.editor:update_post_effects()
	self:viewport():vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("deferred_lighting"))
	self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project_empty"))
	--managers.environment_controller:set_dome_occ_params(self._dome_occ_corner, self._dome_occ_size, managers.database:entry_path(self._params.output_path_file))

	for _, obj in ipairs(self._saved_hidden_object) do
		obj:set_visibility(true)
	end

	for _, unit in ipairs(self._saved_hidden_units) do
		unit:set_visible(true)
	end

	if self._saved_camera then
        self._camera:set_position(self._saved_camera.pos)
        self._camera:set_rotation(self._saved_camera.rot)
		self._parent:set_camera_fov(self._saved_camera.fov)
		self._camera:set_aspect_ratio(self._saved_camera.aspect_ratio)
		self._camera:set_near_range(self._saved_camera.near_range)
		self._camera:set_far_range(self._saved_camera.far_range)

		self._saved_camera = nil
	end

	self._parent:_set_fixed_resolution(self._saved_resolution)
	self:viewport():set_width_mul_enabled(true)
	self:viewport():pop_ref_fov()

	self._parent._menu:Toggle()

	self._params = nil
end

function CubemapCreator:_cubemap_done()
	if alive(self._light) then
		World:delete_light(self._light)
	end

	self._creating_cube_map = nil

	if self._cube_map_done_func then
		self._cube_map_done_func()
    end
end

function CubemapCreator:_generate_cubemap(file)
	local exe_path = string.format('%s %s -i ', self._gen_path, file)

	local input_path
	if not self._params.dome_occ then
		for i, _ in pairs(self._names) do
			-- absolute paths have to have "" around them because of spaces in the base_path
			input_path = string.format("\"%s\" ", Path:Combine(Application:base_path(), self._temp_path, self._name_ordered[i]))
			exe_path = exe_path .. input_path
		end
	else
		input_path = string.format("\"%s\" ", Path:Combine(Application:base_path(), self._temp_path, self._params.output_name))
		exe_path = exe_path .. input_path
	end

	exe_path = exe_path .. string.format("-o %s%s", self._params.output_name, self._params.dome_occ and ".tga" or ".dds")
	exe_path = string.format("\"%s\"", exe_path)
	if os.execute(exe_path) == 0 then 
		self._parent:Log("Cubemap path is: " .. tostring(Path:Combine("assets", self._params.output_path, self._params.output_name .. ".texture")))
		self:_move_output(self._params.output_name)
		
		if self._params.dome_occ or #self._cubes_que < 1 then
			self:notify_success(file)
		end
	else
		self._error_when_done = true
	end
end

function CubemapCreator:_generate_spot_projection() -- Not implemented yet
	local exe_path = self._gen_path .. " light -i "
	exe_path = exe_path .. self._params.source_path .. self._name_ordered[1] .. " "
	exe_path = exe_path .. "-o " .. self._params.output_name .. ".dds "
	os.execute(exe_path)
	self:_move_output(self._params.output_path)
end

function CubemapCreator:_move_output(output_path)
	local output = self._params.output_name .. ".texture"
	local map_path = Path:Combine(BeardLib.config.maps_dir, BLE.MapProject:current_mod().Name) --mapproject comes into scope after init so i putit there
	local final_path = Path:Combine(map_path, "assets", self._params.output_path, output )
	if self._names then
		for i=1, 6 do
			FileIO:Delete(self._params.source_path .. self._names[i])
		end
	end
	-- Moving from temp to assets
	if FileIO:Exists(final_path) then
		FileIO:Delete(final_path)
	end
	FileIO:MakeDir(Path:Combine(map_path, "assets", self._params.output_path))
	FileIO:MoveTo(self._params.source_path .. output, final_path)

	-- Updating Add.xml
	local file_path = Path:Combine(self._params.output_path, tostring(self._params.output_name))
	local xml_path = Path:Combine(map_path, "levels", Global.game_settings.level_id, "add.xml")
	local add = FileIO:ReadScriptData(xml_path, "custom_xml")
	for _, tbl in pairs(add) do
		if tbl.path == file_path then 
			log(file_path)
			return
		end
	end
	table.insert(add, {_meta = "texture", path = file_path})
	FileIO:WriteScriptData(xml_path, add, "custom_xml")
	
end

function CubemapCreator:notify_success(type)
	type = type == "light" and "Cubelight(s)" or "Cubemap(s)"
	BLE.Utils:Notify("Info", type .. " successfully created! Check console log for paths.\nDO NOT rename the cubemap files or delete the cubemap gizmos these cubemaps were built on!")
end

function CubemapCreator:viewport()
	return self._parent._vp
end

function CubemapCreator:_get_screen_size()
	local res = Application:screen_resolution()
	local diff = res.x - res.y
	local x1 = diff / 2
	local y1 = 0
	local x2 = res.x - diff / 2
	local y2 = res.y

	return x1, y1, x2, y2
end