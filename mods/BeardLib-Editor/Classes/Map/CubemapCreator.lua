CubemapCreator = CubemapCreator or class(EditorPart)

function CubemapCreator:init(parent, menu, cam)
    self._parent = parent
	
	self._camera = cam
    self._cube_counter = 1
	self._creating_cube_map = false
	
	self:_init_paths()
end

function CubemapCreator:_init_paths()
	self._gen_path = "\"" .. Application:base_path() .. BLE.ModPath:gsub("/", "\\") .. "Tools".. "\\gen_cubemap.py" .. "\""
	self._cubelights_path = "levels/mods/" .. Global.game_settings.level_id .. "/cube_lights"
	self._temp_path = BLE.ModPath .. "Tools/" .. "temp/"
	FileIO:MakeDir(self._temp_path)
end

function CubemapCreator:update(t, dt)
	if self._creating_cube_map then
        self:_create_cube_map()
        
		return
	end
end

function CubemapCreator:create_projection_light(type)
	local lights = {}
	local units = {}

	if type == "all" then
		for _, unit in pairs(World:find_units_quick("all")) do
			if alive(unit) and unit.unit_data and unit:get_object(Idstring("lo_omni")) then
				table.insert(units, {
					unit = unit,
					light_name = "lo_omni"
				})
			end
		end
	elseif type == "selected" then
		local s_units = self:selected_units()

		for _, unit in pairs(s_units) do
			if unit:get_object(Idstring("lo_omni")) then
				table.insert(units, {
					unit = unit,
					light_name = "lo_omni"
				})
			end
		end
	end

	self._saved_all_lights = {}

	
	for _, unit in pairs(World:find_units_quick("all")) do	-- TODO replace with something better
		if alive(unit) and unit.unit_data and #unit:get_objects_by_type(Idstring("light")) > 0 then
			for _, light in pairs(lights) do
				table.insert(self._saved_all_lights, {
					light = light,
					enabled = light:enable()
				})
			end
		end
	end

	for _, data in pairs(units) do
		local unit = data.unit
		local light = unit:get_object(Idstring(data.light_name))
		local enabled = light:enable()
		local resolution = unit:unit_data().projection_lights and unit:unit_data().projection_lights[light:name():s()] and unit:unit_data().projection_lights[light:name():s()].x
		resolution = resolution or EditUnitLight.DEFAULT_SHADOW_RESOLUTION

		table.insert(lights, {
			name = "",
			position = light:position(),
			unit = unit,
			light = light,
			enabled = enabled,
			spot = string.find(light:properties(), "spot") and true or false,
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

	self._parent._vp:vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("projection_generation"))
	self._parent._vp:vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project"))

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
	self._parent._vp:set_width_mul_enabled(false)

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
		if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
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

function CubemapCreator:next_cube()
	if #self._cubes_que > 0 then
		local cube = table.remove(self._cubes_que, 1)

        self._camera:set_position(cube.position)
        self._camera:set_rotation(self._saved_camera.rot)

		local resolution = cube.resolution or 512

		self._parent:_set_fixed_resolution(Vector3(resolution, resolution, 0))

		local params = {
			done_callback = callback(self, self, "cube_map_done"),
			name = cube.name,
			simple_postfix = self._cubemap_params.simple_postfix,
			source_path = self._temp_path,
			output_path = self._cubelights_path,
			output_name = cube.output_name,
			unit = cube.unit,
			light = cube.light,
			spot = cube.spot
		}

		self:start_cube_map(params)

		return true
	end

	return false
end

function CubemapCreator:cube_map_done()
	if self:next_cube() then
		return
	end

	if self._error_when_done then
		BLE.Utils:Notify("Error", "Something went wrong during the creation of cubemaps! Check the BLT log for more info.")
		self._error_when_done = false
	end
	
	if self._cubemap_params.saved_environment then
		managers.viewport:set_default_environment(self._cubemap_params.saved_environment, nil, nil)
	end

	if self._saved_all_lights then
		for _, data in pairs(self._saved_all_lights) do
			data.light:set_enable(data.enabled)
		end

		self._saved_all_lights = nil
	end

	--[[if self._cubemap_params.lights then
		self._parent._vp:vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("deferred_lighting"))
		self._parent._vp:vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project_empty"))

		for _, cube in pairs(self._cubemap_params.cubes) do
			cube.light:set_enable(cube.enabled)
		end
	end]]

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
	self._parent._vp:set_width_mul_enabled(true)
	self._parent._vp:pop_ref_fov()

	self._parent._menu:Toggle()
end

function CubemapCreator:start_cube_map(params)
	self._params = params
	self._cubemap_name = params.name or ""
	self._simple_postfix = params.simple_postfix
	self._output_name = params.output_name
	self._output_name = self._output_name or "cubemap"
	self._error_when_done = false

	if params.light then
		self._light = World:create_light("omni")

		self._light:set_position(params.light:position())
		self._light:set_near_range(params.light:near_range())
		self._light:set_far_range(params.light:far_range())
		self._light:set_color(Vector3(1, 1, 1))

		if self._params.spot then
			local rot = Rotation(self._params.unit:rotation():z(), Vector3(0, 0, 1))
			rot = Rotation(-rot:z(), rot:y())

			self._params.unit:set_rotation(rot)
		end
	end

	self._camera:set_fov(self._params.spot and self._params.light:spot_angle_end() or 90)

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

	local path = self._params.source_path
	local res = RenderSettings.resolution
	Application:screenshot(path .. self._names[self._cube_counter], 0, 0, res.x, res.y)

	return false
end

function CubemapCreator:_create_spot_projection()
	local res = RenderSettings.resolution

	self._camera:set_rotation(Rotation(-self._params.light:rotation():z(), Vector3(0, 0, 1)))

	local path = self._params.source_path

	Application:screenshot(path .. self._name_ordered[1], 0, 0, res.x, res.y)
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
	local exe_path = self._gen_path .. " " .. file .. " -i "

	for i, _ in pairs(self._names) do
		exe_path = exe_path   .. self._name_ordered[i] .. " "
	end

	exe_path = exe_path .. "-o " .. self._output_name .. ".dds"
	if os.execute(exe_path) == 0 then 
		self._parent:Log("Cubemap path is: " .. tostring(Path:Combine("assets", self._params.output_path, self._output_name .. ".texture")))
		self:_move_output(self._output_name)
		
		if #self._cubes_que < 1 then
			self:notify_success()
		end
	else
		self._error_when_done = true
	end
end

function CubemapCreator:_generate_spot_projection() -- Not implemented yet
	local exe_path = self._gen_path .. " light -i "
	exe_path = exe_path .. self._params.source_path .. self._name_ordered[1] .. " "
	exe_path = exe_path .. "-o " .. self._output_name .. ".dds "
	os.execute(exe_path)
	self:_move_output(self._params.output_path)
end

function CubemapCreator:_move_output(output_path)
	local output = self._output_name .. ".texture"
	local map_path = Path:Combine(BeardLib.config.maps_dir, BLE.MapProject:current_mod().Name) --mapproject comes into scope after init so i putit there
	local final_path = Path:Combine(map_path, "assets", self._params.output_path, output )
	for i=1, 6 do
		FileIO:Delete(self._params.source_path .. self._names[i])
	end
	
	-- Moving from temp to assets
	if FileIO:Exists(final_path) then
		FileIO:Delete(final_path)
	end
	FileIO:MakeDir(Path:Combine(map_path, "assets", self._params.output_path))
	FileIO:MoveTo(self._params.source_path .. output, final_path)

	-- Updating Add.xml
	local file_path = Path:Combine(self._params.output_path, tostring(self._output_name))
	local xml_path = Path:Combine(map_path, "levels", Global.game_settings.level_id, "add.xml")
	local add = FileIO:ReadScriptDataFrom(xml_path, "custom_xml")
	for _, tbl in pairs(add) do
		if tbl.path == file_path then 
			log(file_path)
			return
		end
	end
	table.insert(add, {_meta = "texture", path = file_path})
	FileIO:WriteScriptDataTo(xml_path, add, "custom_xml")
	
end

function CubemapCreator:notify_success()
	BLE.Utils:Notify("Info", "Cubemap(s) successfully created! Check console log for paths.\nDO NOT rename the cubemap files or delete the lights these cubemaps were built on!")
end
