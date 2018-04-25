EditUnitLight = EditUnitLight or class(EditUnit)
EditUnitLight.DEFAULT_SHADOW_RESOLUTION = 128
EditUnitLight.DEFAULT_SPOT_PROJECTION_TEXTURE = "units/lights/spot_light_projection_textures/default_df"
function EditUnitLight:editable(unit)	
	self._lights = BLE.Utils:GetLights(unit) or {}
	return #self._lights > 0
end

function EditUnitLight:build_menu(units)
	local options = {}
	self._idstrings = {}
	for _, light in ipairs(self._lights) do
		self._idstrings[light.object:name():key()] = light.name
		table.insert(options, light.name)
	end
	local light_options = self:Group("Light")
	self._debug = self:Toggle("Debug", function(item)
		self._debugging = item:Value()
	end, false, {group = light_options})
	self._lights_combo = self:ComboBox("Lights", callback(self, self, "set_unit_data_parent"), options, 1, {help = "Select a light to edit from the combobox", group = light_options})
	self._color = self:ColorBox("Color", callback(self, self, "set_unit_data_parent"), nil, {group = light_options})
	self._enabled = self:Toggle("Enabled", callback(self, self, "set_unit_data_parent"), true, {group = light_options})
	self._near_range = self:NumberBox("NearRange[cm]", callback(self, self, "set_unit_data_parent"), 0, {min = 0, floats = 0, help = "Sets the near range of the light in cm", group = light_options})
	self._far_range = self:NumberBox("FarRange[cm]", callback(self, self, "set_unit_data_parent"), 0, {min = 0, floats = 0, help = "Sets the range of the light in cm", group = light_options})
	self._upper_clipping = self:NumberBox("UpperClipping[cm]", callback(self, self, "set_unit_data_parent"), 0, {floats = 0, help = "Sets the upper clipping in cm", group = light_options})
	self._lower_clipping = self:NumberBox("LowerClipping[cm]", callback(self, self, "set_unit_data_parent"), 0, {floats = 0, help = "Sets the lower clipping in cm", group = light_options})

	self._intensity = self:ComboBox("Intensity", callback(self, self, "set_unit_data_parent"), BLE.Utils.IntensityOptions, 1, {help = "Select an intensity from the combobox", group = light_options})
	self._falloff = self:Slider("Falloff", callback(self, self, "set_unit_data_parent"), 1, {help = "Controls the light falloff exponent", floats = 1, min = 1, max = 10, group = light_options})
	self._start_angle = self:Slider("StartAngle", callback(self, self, "set_unit_data_parent"), 1, {help = "Controls the start angle of the spot light", floats = 0, min = 1, max = 179, group = light_options})
	self._end_angle = self:Slider("EndAngle", callback(self, self, "set_unit_data_parent"), 1, {help = "Controls the start angle of the spot light", floats = 0, min = 1, max = 179, group = light_options})
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
	self._shadow_resolution = self:ComboBox("ShadowResolution", callback(self, self, "set_unit_data_parent"), res, 4, {help = "Select an resolution from the combobox", group = light_options})
	self._spot_texture = self:PathItem("SpotTexture", callback(self, self, "set_unit_data_parent"), self.DEFAULT_SPOT_PROJECTION_TEXTURE, "texture", false, nil, false, {
		group = light_options,
		sort_func = function(list)
			local begins = string.begins
			local spot = "units/lights/spot_light_projection_textures"
			table.sort(list, function(a,b)
				if begins(a, spot) and not begins(b, spot) then
					return true
				end
				return false
			end)
		end
	})
end

function EditUnitLight:update_light()
	local unit = self:selected_unit()
	local light = self:selected_light()
	local name = self._idstrings[light:name():key()]
	self._lights_combo:SetSelectedItem(name)
	self._enabled:SetValue(light:enable())
	self._near_range:SetValue(light:near_range())
	self._far_range:SetValue(light:far_range())
	local clipping_values = light:clipping_values()
	self._lower_clipping:SetValue(clipping_values.y)
	self._upper_clipping:SetValue(clipping_values.x)
	local intensity = BLE.Utils:GetIntensityPreset(light:multiplier())
	light:set_multiplier(LightIntensityDB:lookup(intensity))
	light:set_specular_multiplier(LightIntensityDB:lookup_specular_multiplier(intensity))
	for k, i in pairs(BLE.Utils.IntensityOptions) do
		if Idstring(i) == intensity then
			self._intensity:SetValue(k)
		end
	end
	self._falloff:SetValue(light:falloff_exponent())
	self._start_angle:SetValue(light:spot_angle_start())
	self._end_angle:SetValue(light:spot_angle_end())
	self._color:SetValue(light:color())
	local is_spot = not (string.find(light:properties(), "omni") and true or false)

	self._start_angle:SetEnabled(is_spot)
	self._end_angle:SetEnabled(is_spot)
	self._shadow_resolution:SetEnabled(BLE.Utils:IsProjectionLight(unit, light, "shadow_projection"))
	local resolution = unit:unit_data().projection_lights
	resolution = resolution and resolution[name] and resolution[name].x or EditUnitLight.DEFAULT_SHADOW_RESOLUTION
	self._shadow_resolution:SetSelectedItem(resolution)
	--self._spot_texture:SetEnabled(BLE.Utils:IsProjectionLight(unit, light, "projection") and is_spot)
	self._spot_texture:SetEnabled(is_spot)
	local projection_texture = unit:unit_data().projection_textures
	projection_texture = projection_texture and projection_texture[name] or EditUnitLight.DEFAULT_SPOT_PROJECTION_TEXTURE
	self._spot_texture:SetValue(projection_texture)
end 

function EditUnitLight:set_unit_data()	
	local unit = self:selected_unit()
	local light = self:selected_light()
	local clipping_values = light:clipping_values()
	light:set_enable(self._enabled:Value())
	light:set_multiplier(LightIntensityDB:lookup(Idstring(self._intensity:SelectedItem())))
	light:set_specular_multiplier(LightIntensityDB:lookup_specular_multiplier(Idstring(self._intensity:SelectedItem())))
	light:set_near_range(self._near_range:Value())
	light:set_far_range(self._far_range:Value())
	light:set_falloff_exponent(self._falloff:Value())
	light:set_clipping_values(clipping_values:with_x(self._upper_clipping:Value()))
	light:set_clipping_values(clipping_values:with_y(self._lower_clipping:Value()))
	light:set_spot_angle_start(self._start_angle:Value())
	light:set_spot_angle_end(self._end_angle:Value())	
	light:set_color(self._color:VectorValue())
	if self._shadow_resolution:Enabled() then
		local res = self._shadow_resolution:SelectedItem()	
		unit:unit_data().projection_lights = unit:unit_data().projection_lights or {}
		unit:unit_data().projection_lights[self._idstrings[light:name():key()]] = {x = res, y = res}
	end
	if self._spot_texture:Enabled() then
		local tex = self._spot_texture:Value()
		light:set_projection_texture(Idstring(tex), false, false)
		unit:unit_data().projection_textures = unit:unit_data().projection_textures or {}
		unit:unit_data().projection_textures[self._idstrings[light:name():key()]] = tex		
	end
	self:update_light()
end


function EditUnitLight:set_menu_unit(units) self:update_light() end
function EditUnitLight:selected_light() return self:_reference_light(self:selected_unit()) end

function EditUnitLight:_reference_light(unit)
	if alive(unit) then
		return unit:get_object(Idstring(self._lights_combo:SelectedItem()))
	end
end

function EditUnitLight:_is_type(type)
	return string.find(self:_reference_light(self._selected_units[1]):properties(), type)
end

function EditUnitLight:update(t, dt)
	if not self._debugging then
		return
	end
	local light = self:selected_light()
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