require("core/lib/utils/dev/tools/material_editor/CoreSmartNode")

MaterialEditorParameter = MaterialEditorParameter or class()
function MaterialEditorParameter:init(parent, editor, parameter_info, parameter_node)
	self:set_params(parent, editor, parameter_info, parameter_node)

	--self._panel = self._parent:pan(parameter_info and parameter_info.name or "parameter", {align_method = "grid", background_color = self._editor._bgcolor, offset = {0, 12}})

	self:load_value()
	self._editor:update_output()
end

function MaterialEditorParameter:set_params(parent, editor, parameter_info, parameter_node)
	self._parent = parent
	self._editor = editor
	self._parameter_info = parameter_info
	self._parameter_node = parameter_node
	self._node = parameter_node
	self._value = (parameter_info and parameter_info.ui_type == "intensity") and "sun" or (parameter_info and parameter_info.type == "scalar") and 1 or (parameter_info and parameter_info.default) or "[NONE]"
end

function MaterialEditorParameter:update_live()
	self._editor:update_output()
	self._editor:live_update_parameter(self._parameter_info.name, self._parameter_info.type, self._parameter_info.ui_type, self._value)
end

function MaterialEditorParameter:update(t, dt)
end

function MaterialEditorParameter:destroy()
	self._panel:Destroy()
end

function MaterialEditorParameter:panel()
	return self._panel
end

function MaterialEditorParameter:get_value()
	return self._value
end

function MaterialEditorParameter:create_node()
	if not self._parameter_info then
		return
	end
	
	if self._parameter_info.type == "vector3" then
		self._parameter_node = self._editor._current_material_node:make_child("variable")

		self._parameter_node:set_parameter("name", self._parameter_info.name)
		self._parameter_node:set_parameter("type", self._parameter_info.type)

		local str = math.vector_to_string(self._value)

		self._parameter_node:set_parameter("value", str)
	elseif self._parameter_info.type == "texture" then
		self._parameter_node = self._editor._current_material_node:make_child(self._parameter_info.name)
		local str = tostring(self._value)
		self._global_texture = false

		self._parameter_node:set_parameter("file", str)
	else
		self._parameter_node = self._editor._current_material_node:make_child("variable")

		self._parameter_node:set_parameter("name", self._parameter_info.name)
		self._parameter_node:set_parameter("type", self._parameter_info.type)

		local str = tostring(self._value)

		self._parameter_node:set_parameter("value", str)
	end
end

function MaterialEditorParameter:load_value()
	if not self._parameter_node then
		self:create_node()
	end
	self._node = self._parameter_node

	if self._parameter_info.type == "vector3" then
		self._value = math.string_to_vector(self._node:parameter("value"))
	elseif self._parameter_info.type == "texture" then
		self._value = self._node:parameter("file")
		self._global_texture = false

		if not self._value then
			self._global_texture = true
			self._value = self._node:parameter("global_texture")
			self._global_texture_type = "cube"
		end
		self._mip = self._node:parameter("mip") or 0
	elseif self._parameter_info.ui_type == "intensity" then
		self._value = self._node:parameter("value")
	else
		self._value = tonumber(self._node:parameter("value"))
	end
end

function MaterialEditorParameter:create_widget(widget)
	widget.offset[2] = 12
	widget:SetBorder({bottom = true, size = 1, color = widget.foreground:with_alpha(0.2)})

	self._panel = widget
end

------------------------------------- Render Template -------------------------------------------
MaterialEditorRenderTemplate = MaterialEditorRenderTemplate or class(MaterialEditorParameter)

function MaterialEditorRenderTemplate:init(parent, editor, parameter_node)
	MaterialEditorRenderTemplate.super.init(self, parent, editor, nil, parameter_node)

	self:create_widget(parent:simple_divgroup("render_template", {
		text = "Render Template",
		help = "render_template",
		align_method = "grid", 
		background_visible = true, 
		background_color = self._editor._bgcolor, 
		unhighlight_color = Color.transparent
	}))

    self._panel:GetToolbar():button("Customize", ClassClbk(self, "on_toggle_customize", false), {size_by_text = true})
    self._panel:GetToolbar():button("Apply", ClassClbk(self, "on_toggle_customize", true), {size_by_text = true, visible = false})
	self._panel:GetToolbar():tickbox("Unique", ClassClbk(self, "on_unique"), self._unique, {size_by_text = true})
    self._panel:lbl("Template", {text = self._value, offset = 0, enabled = false})

	self._shader_option_panel = self._panel:holder("Options", {offset = 0, auto_align = true, align_method = "grid"})
end

function MaterialEditorRenderTemplate:load_value()
	self._node = self._parameter_node
	self._value = self._node:parameter("render_template")
	self._render_template = RenderTemplateDatabase:render_template_name_to_defines(self._value)
	self._unique = self._node:parameter("unique")
end

function MaterialEditorRenderTemplate:on_unique(item)
	self._unique = item:Value()

	if self._unique then
		self._node:set_parameter("unique", "true")
	else
		self._node:clear_parameter("unique")
	end

	self:update_live()
end

function MaterialEditorRenderTemplate:on_toggle_customize(apply)
	self._customize = not self._customize
	self._editor:on_customize_render_template(self._customize)
	self._panel:GetItem("Apply"):SetVisible(self._customize)
	self._panel:GetItem("Customize"):SetText(self._customize and "Cancel" or "Customize")
	self._panel:GetItem("Template"):SetVisible(not self._customize)
	self._shader_option_panel:ClearItems()

	if apply then
		self._node:set_parameter("render_template", self._value)
		self._editor:on_shader_option_chaged()
	else
		self:load_value()

		if self._customize then
			local shader_options = self._editor:load_shader_options()
			
			self:build_shader_options(shader_options)
			self:set_shader_options()
	
		end
	end

	self:update_live()
end

function MaterialEditorRenderTemplate:build_shader_options(shader_options)
	local inherit_values = {size = self._shader_option_panel.size * 0.8, font = tweak_data.menu.pd2_medium_font}

	self._shader_option_panel:combobox("CompilableShader", ClassClbk(self, "set_shader_options"), shader_options.shaders, table.get_key(shader_options.shaders, self._render_template.shader))
	self._shader_option_panel:pan("SelectedDefines", {align_method = "grid", inherit_values = inherit_values})
	self._shader_option_panel:pan("RenderTemplates", {max_height = 225, inherit_values = inherit_values})
	local available = self._shader_option_panel:combobox("AvailableDefines", nil, shader_options.defines, 1, {
		text = " ", 
		control_slice = 1, 
		searchbox = true, 
		context_scroll_width = 4,
		shrink_width = 0.93
	})
	self._shader_option_panel:tb_btn("Add", ClassClbk(self, "change_available_defines", true, available))
end

function MaterialEditorRenderTemplate:set_shader_options()
	local shader_name = self._shader_option_panel:GetItem("CompilableShader"):SelectedItem()
	local selected = self._shader_option_panel:GetItem("SelectedDefines")
	local available = self._shader_option_panel:GetItem("AvailableDefines")
	local shader_options = self._editor:load_shader_options()
	self._render_template.shader = shader_name

	selected:ClearItems()
	for _, define in ipairs(self._render_template.defines) do
		selected:button(define, ClassClbk(self, "change_available_defines", false), {
			text = define,
			size_by_text = true,
			border_bottom = true,
			border_color = selected.accent_color,
			border_size = 2
		})
		table.delete(shader_options.defines, define)
	end

	available:SetItems(shader_options.defines)
	available:UpdateValueText()
	self:set_render_template_options()
end

function MaterialEditorRenderTemplate:set_render_template_options()
	local templates = self._shader_option_panel:GetItem("RenderTemplates")
	templates:ClearItems()

	local matches, exact_match = self._editor:find_matching_render_templates(self._render_template)
	if exact_match ~= "" then
		self._value = exact_match

		self._render_template = RenderTemplateDatabase:render_template_name_to_defines(exact_match)
	end

	for _, template in ipairs(matches) do
		local range_color = {}
		local v = RenderTemplateDatabase:render_template_name_to_defines(template)

		for _, define in ipairs(v.defines) do
			if not table.contains(self._render_template.defines, define) then
				local s, e = string.find(template, define)
				table.insert(range_color, {s-1, e, Color.white:with_alpha(0.4)})
			end
		end

		templates:button(template, ClassClbk(self, "on_render_template"), {
			text = template, 
			border_left = template == self._value, 
			border_size = 2,
			border_color = templates.accent_color,
			index = template == self._value and 1 or nil,
			range_color = range_color,
			offset = {1, 4}
		})
	end
	self._parent:AlignItems(true)
end

function MaterialEditorRenderTemplate:on_render_template(item)
	self._value = item:Name()

	self._render_template = RenderTemplateDatabase:render_template_name_to_defines(self._value)
	self:set_shader_options()
end

function MaterialEditorRenderTemplate:change_available_defines(add, item)
	local available = self._shader_option_panel:GetItem("AvailableDefines")

	if add then
		table.insert(self._render_template.defines, item:SelectedItem())
	else
		table.delete(self._render_template.defines, item:Name())
	end

	self:set_shader_options()
end

function MaterialEditorRenderTemplate:update_live()
	self._editor:update_output()
	self._editor:live_update_parameter("render_template", "render_template", nil, self._value)
end

------------------------------------- Scalar -------------------------------------------
MaterialEditorScalar = MaterialEditorScalar or class(MaterialEditorParameter)

function MaterialEditorScalar:init(parent, editor, parameter_info, parameter_node)
	MaterialEditorScalar.super.init(self, parent, editor, parameter_info, parameter_node)

    self:create_widget(parent:slider(parameter_info.name, ClassClbk(self, "on_slider"), self._value, {
		text = parameter_info.ui_name, 
		help = parameter_info.name, 
		min = parameter_info.min, 
		max = parameter_info.max, 
		step = parameter_info.step,
		background_color = self._editor._bgcolor
	}))
end

function MaterialEditorScalar:on_slider(item)
	self._value = item:Value()

	self._parameter_node:set_parameter("value", tostring(self._value))
	self:update_live()
end

------------------------------------- Intensity -------------------------------------------
MaterialEditorDVValue = MaterialEditorDVValue or class(MaterialEditorParameter)

function MaterialEditorDVValue:init(parent, editor, parameter_info, parameter_node)
	MaterialEditorDVValue.super.init(self, parent, editor, parameter_info, parameter_node)

	self:create_widget(parent:combobox(parameter_info.name, ClassClbk(self, "on_combobox_changed"), BLE.Utils.IntensityOptions, 1, {
		text = parameter_info.ui_name, 
		help = parameter_info.name,
		background_color = self._editor._bgcolor
	}))
	self._panel:SetSelectedItem(self._value)
end

function MaterialEditorDVValue:on_combobox_changed(item)
	self._value = item:SelectedItem()

	self._parameter_node:set_parameter("value", tostring(self._value))
	self:update_live()
end

------------------------------------- Texture -------------------------------------------
MaterialEditorTexture = MaterialEditorTexture or class(MaterialEditorParameter)

function MaterialEditorTexture:init(parent, editor, parameter_info, parameter_node)
	MaterialEditorTexture.super.init(self, parent, editor, parameter_info, parameter_node)

	self._requested_textures = {}
	--self:create_widget(parent:pathbox(parameter_info.name, ClassClbk(self, "on_commit"), self._value, "texture", {background_color = self._editor._bgcolor}))
	self:create_widget(parent:simple_divgroup(parameter_info.name, {
		text = parameter_info.ui_name, 
		help = parameter_info.name,
		align_method = "grid", 
		background_visible = true, 
		background_color = self._editor._bgcolor, 
		unhighlight_color = Color.transparent
	}))

	self._text = self._panel:textbox("File", ClassClbk(self, "on_text"), "", {control_slice = 0.9, visible = not self._global_texture})
	local global_textures = {"current_global_texture", "current_global_world_overlay_texture", "current_global_world_overlay_mask_texture"}
	self._global = self._panel:combobox("GlobalTexture", ClassClbk(self, "on_pick_global_texture"), global_textures, 1, {control_slice = 0.8, visible = self._global_texture})
	if self._global_texture then
		self._global:SetSelectedItem(self._value)
	end

	self._panel:AlignItems()

	local h = self._panel:ItemsHeight(1)
	local off_x, off_y = unpack(self._text.offset)
	local w = self._panel:ItemsWidth(1) - (h + off_y) * 3

	self._panel:tickbox("UsesGlobalTexture", ClassClbk(self, "on_toggle_global_texture"), self._global_texture, {w = w / 2 - off_y, index = 1})
	self._panel:numberbox("MipLevel", ClassClbk(self, "on_mip"), self._mip, {w = w / 2 - off_y, index = 2, min = 0, floats = 0})
	self._browse = self._panel:button("BrowseTextures", ClassClbk(self, "on_browse"), {w = w - off_y, index = 3})

	self._preview_border = self._panel:Panel():rect({name = "texture_preview_border", w = (h + off_y) * 3, h = (h + off_y) * 3, color = Color.white, layer = 10})
	self._preview_border:set_righttop(self._panel.panel:w() - off_x, off_y)

	self._panel:GetToolbar():lbl("", {w = self._preview_border:w()})
	self._panel:GetToolbar():tb_visbtn("ToggleBorder", ClassClbk(self, "on_toggle_border"), true, {help = "Toggle preview background"})

	self._text:SetValue(self._value)
	self:update_texture()

end

function MaterialEditorTexture:on_text(item)
	self._value = item:Value()

	self._node:clear_parameter("global_texture")
	self._node:clear_parameter("type")
	self._node:set_parameter("file", self._value)

	if self._parameter_info.name == "reflection_texture" then
		self._node:set_parameter("type", "cubemap")
	end

	self:update_texture()
	self:update_live()
end

function MaterialEditorTexture:on_pick_global_texture(item)
	local value = item:SelectedItem()

	self._value = value
	self._global_texture = true
	self._global_texture_type = value == "current_global_texture" and "cube" or "texture"

	self._node:clear_parameter("file")
	self._node:set_parameter("global_texture", self._value)
	self._node:set_parameter("type", self._global_texture_type)
	self:update_texture()
	self:update_live()
end

function MaterialEditorTexture:on_toggle_global_texture(item)
	local value = item:Value()

	self._text:SetVisible(not value)
	self._global:SetVisible(value)
	self._browse:SetEnabled(not value)

	if value then
		self:on_pick_global_texture(self._global)
	else
		self:on_text(self._text)
	end
end

function MaterialEditorTexture:on_toggle_border(item)
	local value = item:Value()
	self._border_hidden = not value

	self._preview_border:set_visible(value)
	if self._preview then
		self._preview:set_blend_mode(value and "mul" or "normal")
	end
end

function MaterialEditorTexture:on_mip(item)
	self._mip = math.round(item:Value())

	if self._mip == 0 then
		self._node:clear_parameter("mip")
	else
		self._node:set_parameter("mip", self._mip)
	end

	self:update_live()
end

function MaterialEditorTexture:on_browse()
	local list = BLE.Utils:GetEntries({
		type = "texture", filenames = false
	})
	BLE.ListDialog:Show({
		list = list,
		callback = function(path)
			if path then
				self._global_texture = false
				self._value = path
		
				self._node:clear_parameter("global_texture")
				self._node:clear_parameter("type")
				self._node:set_parameter("file", self._value)
		
				if self._parameter_info.name == "reflection_texture" then
					self._node:set_parameter("type", "cubemap")
				end
		
				self._text:SetValue(self._value)
				self:update_texture()
				self:update_live()
			end
		end
	})
end

function MaterialEditorTexture:update_texture()
	if self._preview then
		self._panel:Panel():remove(self._preview)
	end

	local texture_path = self._value
	if DB:has(Idstring("texture"), texture_path) then
		local texture_count = managers.menu_component:request_texture(texture_path, ClassClbk(self, "texture_done_clbk"))
		table.insert(self._requested_textures, {
			texture_count = texture_count,
			texture = texture_path
		})
	elseif self._global_texture then
		self:texture_done_clbk(self._editor.DEFAULT_TEXTURE)
	else
		self:texture_done_clbk("")
	end
end

function MaterialEditorTexture:texture_done_clbk(texture_ids)
	if self._preview then
		self._panel:Panel():remove(self._preview)
	end
	self._preview = self._panel:Panel():bitmap({name = "texture_preview", texture = texture_ids, blend_mode = self._border_hidden and "normal" or "mul", layer = 11})
	self._preview:set_size(self._preview_border:size())
	self._preview:set_center(self._preview_border:center())

	for i, data in ipairs(self._requested_textures) do
		if not Idstring(data.texture) == texture_ids then
			managers.menu_component:unretrieve_texture(data.texture, data.texture_count)
			table.remove(self._requested_textures, i)
		end
	end
end

function MaterialEditorTexture:destroy()
	MaterialEditorTexture.super.destroy(self)

	for i, data in ipairs(self._requested_textures) do
		managers.menu_component:unretrieve_texture(data.texture, data.texture_count)
		table.remove(self._requested_textures, i)
	end
	self._requested_textures = nil
end


------------------------------------- Vector -------------------------------------------
MaterialEditorVector = MaterialEditorVector or class(MaterialEditorParameter)

function MaterialEditorVector:init(parent, editor, parameter_info, parameter_node)
	MaterialEditorVector.super.init(self, parent, editor, parameter_info, parameter_node)

	self:create_widget(parent:Vector3(parameter_info.name, ClassClbk(self, "on_text_ctrl"), self._value, {
		text = parameter_info.ui_name, 
		help = parameter_info.name,
		vector2 = parameter_info.ui_type == "vector2",
		step = parameter_info.step and parameter_info.step.x,
		background_visible = true,
		background_color = self._editor._bgcolor,
		unhighlight_color = Color.transparent
	}))

	self._panel:GetItem("X").help = tostring(self._parameter_info.min.x).." - "..tostring(self._parameter_info.max.x)
	self._panel:GetItem("X").step = parameter_info.step and parameter_info.step.x
	self._panel:GetItem("Y").help = tostring(self._parameter_info.min.x).." - "..tostring(self._parameter_info.max.x)
	self._panel:GetItem("Y").step = parameter_info.step and parameter_info.step.y
	self._panel:GetItem("Z").help = tostring(self._parameter_info.min.z).." - "..tostring(self._parameter_info.max.z)
	self._panel:GetItem("Z").step = parameter_info.step and parameter_info.step.z
end

function MaterialEditorVector:on_text_ctrl(item)
	local value = item:Value()
	self._value = self:to_slider_range(value)

	self._parameter_node:set_parameter("value", math.vector_to_string(self._value))
	item:SetValue(self._value)
	self:update_live()
end

function MaterialEditorVector:to_slider_range(v)
	local x = math.clamp(v.x, self._parameter_info.min.x, self._parameter_info.max.x)
	local y = math.clamp(v.y, self._parameter_info.min.y, self._parameter_info.max.y)
	local z = math.clamp(v.z, self._parameter_info.min.z, self._parameter_info.max.z)

	return Vector3(x, y, z)
end

------------------------------------- Color -------------------------------------------
MaterialEditorColor = MaterialEditorColor or class(MaterialEditorParameter)

function MaterialEditorColor:init(parent, editor, parameter_info, parameter_node)
	MaterialEditorColor.super.init(self, parent, editor, parameter_info, parameter_node)

	self:create_widget(parent:colorbox(parameter_info.name, ClassClbk(self, "on_color"), self._value, {
		text = parameter_info.ui_name, 
		help = parameter_info.name,
		use_alpha = false,
		background_visible = true,
		background_color = self._editor._bgcolor
	}))
end

function MaterialEditorColor:on_color(item)
	local color = item:Value()
	self._value = Vector3(color.r, color.g, color.b)

	self._parameter_node:set_parameter("value", math.vector_to_string(self._value))
	self:update_live()
end

------------------------------------- Decal -------------------------------------------
MaterialEditorDecal = MaterialEditorDecal or class(MaterialEditorParameter)

function MaterialEditorDecal:init(parent, editor, parameter_node)
	self:set_params(parent, editor, parameter_node)

	self:create_widget(parent:combobox("decal_material", ClassClbk(self, "on_combo_box_change"), {""}, 1, {
		text = "Decal Material",
		help = "decal_material",
		use_alpha = false,
		background_visible = true,
		background_color = self._editor._bgcolor
	}))

	self:fill_decal_materials()
	self._editor:update_output()
end

function MaterialEditorDecal:set_params(parent, editor, parameter_node)
	self._parent = parent
	self._editor = editor
	self._parameter_node = parameter_node
	self._node = parameter_node
	self._value = self._editor._current_material_node:parameter("decal_material") or ""
	--self._parent_node = self._editor._parent_materials[self._editor._parent_combo_box:get_value()]
end

function MaterialEditorDecal:on_combo_box_change(item)
	self._value = item:SelectedItem()

	if self._value == "" then
		self._editor._current_material_node:clear_parameter("decal_material")
	else
		self._editor._current_material_node:set_parameter("decal_material", self._value)
	end

	self._editor:update_output()
end

function MaterialEditorDecal:fill_decal_materials()
	self._panel:ClearItems()
	local decals = self._editor:load_decal_materials()

	if decals then
		self._panel:SetItems(decals)
		self._panel:SetSelectedItem(self._value)
	end
end