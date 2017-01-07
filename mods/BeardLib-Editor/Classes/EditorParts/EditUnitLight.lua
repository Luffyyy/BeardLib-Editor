EditUnitLight = EditUnitLight or class(EditorPart)
EditUnitLight.DEFAULT_SHADOW_RESOLUTION = 128
EditUnitLight.DEFAULT_SPOT_PROJECTION_TEXTURE = "units/lights/spot_light_projection_textures/default_df"
function EditUnitLight:init()
end
function EditUnitLight:is_editable(parent, menu, name)
	local options = {}
	local units = parent._selected_units
	if alive(units[1]) then
		local lights = BeardLibEditor.Utils:GetLights(units[1]) or {}
		self._idstrings = {}
		for _, light in ipairs(lights) do
			self._idstrings[light.object:name()] = light.name
			table.insert(options, light.name)
		end
		if lights[1] then
			self._selected_units = units
		else
			return nil
		end
	else
		return nil
	end
	self.super.init_basic(self, parent, menu, name)
	self._menu = parent._menu
	local light_options = self:Group("Light")
	self._debug = self:Toggle("Debug", function(menu, item)
		self._debugging = item:Value()
	end, false, {group = light_options})
	self._lights = self:ComboBox("Lights", callback(self, self, "change_light"), options, 1, {help = "Select a light to edit from the combobox", group = light_options})
	self:Button("ChooseColor", callback(self, self, "show_color_dialog"), {group = light_options})
	self._enabled = self:Toggle("Enabled", callback(self, self, "update_enabled"), true, {group = light_options})
	self._near_range = self:NumberBox("NearRange[cm]", callback(self, self, "update_near_range"), 0, {min = 0, floats = 0, help = "Sets the near range of the light in cm", group = light_options})
	self._far_range = self:NumberBox("FarRange[cm]", callback(self, self, "update_far_range"), 0, {min = 0, floats = 0, help = "Sets the range of the light in cm", group = light_options})
	self._upper_clipping = self:NumberBox("UpperClipping[cm]", callback(self, self, "update_clipping", "x"), 0, {floats = 0, help = "Sets the upper clipping in cm", group = light_options})
	self._lower_clipping = self:NumberBox("LowerClipping[cm]", callback(self, self, "update_clipping", "y"), 0, {floats = 0, help = "Sets the lower clipping in cm", group = light_options})
	local intensity_options = {}
	for _, intensity in ipairs(LightIntensityDB:list()) do
		table.insert(intensity_options, intensity:s())
	end	
	self._intensity = self:ComboBox("Intensity", callback(self, self, "update_intensity"), intensity_options, 1, {help = "Select an intensity from the combobox", group = light_options})
	self._falloff = self:Slider("Falloff", callback(self, self, "update_falloff"), 1, {help = "Controls the light falloff exponent", floats = 1, min = 1, max = 10, group = light_options})
	self._start_angle = self:Slider("StartAngle", callback(self, self, "update_start_angle"), 1, {help = "Controls the start angle of the spot light", floats = 0, min = 1, max = 179, group = light_options})
	self._end_angle = self:Slider("EndAngle", callback(self, self, "update_end_angle"), 1, {help = "Controls the start angle of the spot light", floats = 0, min = 1, max = 179, group = light_options})
	local res = {
		16,
		32,
		64,
		128,
		256,
		512,
		1024,
		2048
	}
	self._shadow_resolution = self:ComboBox("ShadowResolution", callback(self, self, "update_resolution"), res, 4, {help = "Select an resolution from the combobox", group = light_options})
	local textures = BeardLibEditor.Utils:FromHashlist({
        path = "units/lights/spot_light_projection_textures",
        type = "texture"
    })
	self._spot_texture = self:ComboBox("SpotTexture", callback(self, self, "update_spot_projection_texture"), textures, table.get_key(textures, self.DEFAULT_SPOT_PROJECTION_TEXTURE),{
		help = "Select a spot projection texture from the combobox",
		group = light_options
	})
	self._lights:RunCallback()
	return self
end

function EditUnitLight:change_light(menu, item) --
	if alive(self._selected_units[1]) then
		local light = self._selected_units[1]:get_object(Idstring(item:SelectedItem()))
		self:update_light_ctrls_from_light({name = self._idstrings[light:name()], object = light})
	end
end

function EditUnitLight:update_light_ctrls_from_light(light) 
	local name = light.name
	local obj = light.object
	--self._lights:SetSelectedItem(name)
	self._enabled:SetValue(obj:enable())
	--self._color_ctrlr:set_background_colour(obj:color().x * 255, obj:color().y * 255, obj:color().z * 255)
	self._near_range:SetValue(obj:near_range())
	self._far_range:SetValue(obj:far_range())
	local clipping_values = obj:clipping_values()
	self._lower_clipping:SetValue(clipping_values.x)
	self._upper_clipping:SetValue(clipping_values.y)
	local intensity = BeardLibEditor.Utils:GetIntensityPreset(obj:multiplier())
	obj:set_multiplier(LightIntensityDB:lookup(intensity))
	obj:set_specular_multiplier(LightIntensityDB:lookup_specular_multiplier(intensity))
	self._intensity:SetSelectedItem(intensity:s())
	self._falloff:SetValue(obj:falloff_exponent())
	self._start_angle:SetValue(obj:spot_angle_start())
	self._end_angle:SetValue(obj:spot_angle_end())
	local is_spot = string.match(obj:properties(), "omni") -- Not sure about this(see decompiled code).
	self._start_angle:SetEnabled(is_spot)
	self._end_angle:SetEnabled(is_spot)
	self._shadow_resolution:SetEnabled(BeardLibEditor.Utils:IsProjectionLight(self._selected_units[1], obj, "shadow_projection"))
	local resolution = self._selected_units[1]:unit_data().projection_lights
	resolution = resolution and resolution[name] and resolution[name].x or EditUnitLight.DEFAULT_SHADOW_RESOLUTION
	self._shadow_resolution:SetSelectedItem(resolution)
	self._spot_texture:SetEnabled(BeardLibEditor.Utils:IsProjectionLight(self._selected_units[1], obj, "projection") and is_spot)
	local projection_texture = self._selected_units[1]:unit_data().projection_textures
	projection_texture = projection_texture and projection_texture[name] or EditUnitLight.DEFAULT_SPOT_PROJECTION_TEXTURE
	self._spot_texture:SetSelectedItem(projection_texture)
end

function EditUnitLight:update_falloff(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_falloff_exponent(item.value)
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_enabled(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_enable(item.value)
	end
	self._parent:set_unit_data()
end

function EditUnitLight:show_color_dialog() --
	local colordlg = EWS:ColourDialog(self._panel, true, self._color_ctrlr:background_colour() / 255)
	if colordlg:show_modal() then
		self._color_ctrlr:set_background_colour(colordlg:get_colour().x * 255, colordlg:get_colour().y * 255, colordlg:get_colour().z * 255)
		for _, light in ipairs(self:_selected_lights()) do
			light:set_color(self._color_ctrlr:background_colour() / 255)
		end
	end
end

function EditUnitLight:update_intensity(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_multiplier(LightIntensityDB:lookup(Idstring(item.value)))
		light:set_specular_multiplier(LightIntensityDB:lookup_specular_multiplier(Idstring(item.value)))
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_near_range(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_near_range(item.value)
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_far_range(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_far_range(item.value)
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_clipping(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		local clipping_values = light:clipping_values()
		if value == "x" then
			light:set_clipping_values(clipping_values:with_x(item.value))
		elseif value == "y" then
			light:set_clipping_values(clipping_values:with_y(item.value))
		elseif value == "z" then
			light:set_clipping_values(clipping_values:with_z(item.value))
		end
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_start_angle(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_spot_angle_start(item.value)
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_end_angle(menu, item)
	for _, light in ipairs(self:_selected_lights()) do
		light:set_spot_angle_end(item.value)
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_resolution(menu, item) 
	local value = item.value
	for _, light in ipairs(self:_selected_lights()) do
		unit:unit_data().projection_lights = unit:unit_data().projection_lights or {}
		unit:unit_data().projection_lights[self._idstrings(light:name())] = {x = value, y = value}
	end
	self._parent:set_unit_data()
end

function EditUnitLight:update_spot_projection_texture(menu, item) 
	local value = "units/lights/spot_light_projection_textures/" .. item.value
	for _, light in ipairs(self:_selected_lights()) do
		light:set_projection_texture(Idstring(value), false, false)
		unit:unit_data().projection_textures = unit:unit_data().projection_textures or {}
		unit:unit_data().projection_textures[self._idstrings(light:name())] = value
	end
	self._parent:set_unit_data()
end

function EditUnitLight:_selected_lights() 
	local lights = {}
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) then
			local light = self:_reference_light(unit)
			if light then
				table.insert(lights, light)
			end
		end
	end
	return lights
end

function EditUnitLight:_reference_light(unit)
	if alive(unit) then
		return unit:get_object(Idstring(self._lights:SelectedItem()))
	end
end

function EditUnitLight:_is_type(type)
	return string.find(self:_reference_light(self._selected_units[1]):properties(), type)
end

function EditUnitLight:update(t, dt)
	if not self._debugging then
		return
	end
	for _, light in ipairs(self:_selected_lights()) do
		if not light:enable() then
			return
		end
		local c = light:color()
		local clipping_values = light:clipping_values()
		if self:_is_type("omni") then
			self._brush:set_color(Color(0.15, c.x * 1, c.y * 1, c.z * 1))
			self._brush:sphere(light:position(), light:far_range(), 4)
			self._brush:set_color(Color(0.15, c.x * 0.5, c.y * 0.5, c.z * 0.5))
			self._brush:sphere(light:position(), light:near_range(), 4)
			Application:draw_sphere(light:position(), light:near_range(), c.x * 0.5, c.y * 0.5, c.z * 0.5)
			Application:draw_sphere(light:position(), light:far_range(), c.x * 1, c.y * 1, c.z * 1)
		else
			local far_radius = math.tan(light:spot_angle_end() / 2) * light:far_range()
			local near_radius = math.tan(light:spot_angle_end() / 2) * light:near_range()
			self._brush:set_color(Color(0.25, c.x * 1, c.y * 1, c.z * 1))
			self._brush:cone(light:position(), light:position() - light:rotation():z() * light:far_range(), far_radius)
			self._brush:set_color(Color(0.25, c.x * 0.25, c.y * 0.25, c.z * 0.25))
			self._brush:cone(light:position(), light:position() - light:rotation():z() * light:near_range(), near_radius)
			Application:draw_cone(light:position(), light:position() - light:rotation():z() * light:far_range(), far_radius, c.x * 1, c.y * 1, c.z * 1)
			Application:draw_cone(light:position(), light:position() - light:rotation():z() * light:near_range(), near_radius, c.x * 0.5, c.y * 0.5, c.z * 0.5)
		end
		self._brush:set_color(Color(0.5, c.x * 1, c.y * 0.5, c.z * 0))
		self._brush:disc(light:position() + Vector3(0, 0, clipping_values.x), light:far_range())
		self._pen:circle(light:position() + Vector3(0, 0, clipping_values.x), light:far_range())
		self._brush:set_color(Color(0.5, c.x * 1, c.y * 0.2, c.z * 0))
		self._brush:disc(light:position() + Vector3(0, 0, clipping_values.y), light:far_range())
		self._pen:circle(light:position() + Vector3(0, 0, clipping_values.y), light:far_range())		
	end
end