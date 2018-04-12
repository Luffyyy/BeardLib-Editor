CubemapCreator = CubemapCreator or class(EditorPart)

function CubemapCreator:init(parent, menu, cam)
    self._parent = parent
	
	self._camera = cam
    self._cube_counter = 1
	self._creating_cube_map = false
end

function CubemapCreator:update(t, dt)
	if self._creating_cube_map then
        self:_create_cube_map()
        
		return
	end
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

	self._saved_camera = {
		aspect_ratio = self._camera:aspect_ratio(),
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

	self._saved_resolution = RenderSettings.resolution

	if managers.viewport and managers.viewport._sun_flare_effect then
		managers.viewport._sun_flare_effect._sf_panel:hide()
	end

	self:next_cube()
end

-- Lines: 143 to 163
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
			source_path = self._cubemap_params.source_path,
			output_path = self._cubemap_params.output_path,
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

-- Lines: 167 to 224
function CubemapCreator:cube_map_done()
	if self:next_cube() then
		return
	end

	if self._cubemap_params.saved_environment then
		managers.viewport:set_default_environment(self._cubemap_params.saved_environment, nil, nil)
	end

	--if self._saved_all_lights then
		--[[for _, data in pairs(self._saved_all_lights) do
			data.light:set_enable(data.enabled)
		end]]

		--self._saved_all_lights = nil
--	end

	if self._cubemap_params.lights then
		managers.editor:update_post_effects()
		self:viewport():vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("deferred_lighting"))
		self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project_empty"))
		self:_recompile(self._cubemap_params.output_path)

		for _, cube in ipairs(self._cubemap_params.cubes) do
			cube.light:set_enable(cube.enabled)

			local texture_path = managers.database:entry_path(self._cubemap_params.output_path .. cube.output_name)

			cube.light:set_projection_texture(Idstring(texture_path), not cube.spot, false)
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
	self._parent._vp:set_width_mul_enabled(true)
	self._parent._vp:pop_ref_fov()
end

function CubemapCreator:start_cube_map(params)
	self._params = params
	self._cubemap_name = params.name or ""
	self._simple_postfix = params.simple_postfix
	self._output_name = params.output_name
	self._output_name = self._output_name or "cubemap"

	--[[if params.light then
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
	end]]

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

-- Lines: 249 to 250
function CubemapCreator:creating_cube_map()
	return self._creating_cube_map
end

-- Lines: 253 to 297
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

	local x1, y1, x2, y2 = self:_get_screen_size()
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
		--self:_generate_cubemap(self._params.light and "cubemap_light" or "cubemap_reflection")
		self:_cubemap_done()

		return true
	end

	local path = self._params.source_path
    self._parent:Log("Path: " ..tostring(path) .. " Names: " ..tostring(self._names[self._cube_counter]))
    self._parent:Log("Screen size: " .. x1 .. " " .. y1 .. " " .. x2 .. " " .. y2)
	Application:screenshot(path .. self._names[self._cube_counter], x1, y1, x2, y2)

	return false
end

-- Lines: 300 to 309
function CubemapCreator:_cubemap_done()
	if alive(self._light) then
		World:delete_light(self._light)
	end

	self._creating_cube_map = nil

	if self._cube_map_done_func then
		self._cube_map_done_func()
    end
    self._parent._menu:Toggle()
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

function CubemapCreator:_generate_cubemap(file)
	local execute = managers.database:root_path() .. "aux_assets/engine/tools/" .. file .. ".bat "

	for i, _ in pairs(self._names) do
		local path = self._params.source_path or managers.database:root_path()
		execute = execute .. path .. self._name_ordered[i] .. " "
	end

	local output_path = (self._params.output_path or managers.database:root_path()) .. self._output_name .. " "
	execute = execute .. output_path .. " "

	os.execute(execute)
	self:_add_meta_data((self._params.output_path or managers.database:root_path()) .. self._output_name .. ".dds", "diffuse_colormap_gradient_alpha_manual_mips")
end

function CubemapCreator:_add_meta_data(file, meta)
	local execute = managers.database:root_path() .. "aux_assets/engine/tools/diesel_dds_tagger.exe "
	execute = execute .. file .. " " .. meta

	os.execute(execute)
end

