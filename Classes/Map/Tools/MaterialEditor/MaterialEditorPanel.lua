MaterialEditorPanel = MaterialEditorPanel or class()
MaterialEditorPanel.MATERIAL_VERSION_TAG = "2"
MaterialEditorPanel.DEFAULT_TEXTURE = "core/textures/default_texture_df"
MaterialEditorPanel.DEFAULT_COMPILABLE_SHADER = "generic"
MaterialEditorPanel.DEFAULT_RENDER_TEMPLATE = "generic:DIFFUSE_TEXTURE"

function MaterialEditorPanel:init(editor, parent, node, path)
	self._editor = editor

    self._undo_stack = CoreUndoStack:new(node:to_xml(), 20)
    
    self:create_panel(parent)  
end

function MaterialEditorPanel:create_panel(parent)
	self._panel = parent:Menu({auto_height = true, align_method = "grid"})
    self._bgcolor = BLE.Options:GetValue("BackgroundColor")

    self._gv_splitter = self._panel:pan("gvsplitter")
    local materials_panel = self:create_materials_panel(self._gv_splitter)
    --local parameters_panel = self:create_parameter_panel(self._gv_splitter)

	self:update_output()
end

function MaterialEditorPanel:panel()
	return self._panel
end

function MaterialEditorPanel:create_materials_panel(parent)
    local panel = parent:pan("materials", {align_method = "centered_grid"})
    self._material_group = panel:textbox("MaterialGroup", ClassClbk(self, "on_change_group"))

	local group = panel:divgroup("Materials", {auto_align = false, offset = 4})
	
    local widget = group:pan(name, {align_method = "grid", background_color = self._bgcolor})
    self._materials_group = widget:pan("", {max_height = 140})
	group:GetToolbar():tb_imgbtn("PasteMaterial", ClassClbk(self, "on_paste_as_material", name), nil, BLE.Utils.EditorIcons.paste, {help = "Paste Material"})
	group:GetToolbar():textbox("Search", function(item) 
		BLE.Utils:FilterList(self._materials_group, item) 
		parent:AlignItems(true)
	end, 
	"", {w = 200, lines = 1, text = "Search", control_slice = 0.8, highlight_color = false})

    local tetxbox = widget:textbox(" ", nil, nil, {control_slice = 1, shrink_width = 0.93})
    local add_button = widget:tb_btn("Add", ClassClbk(self, "on_add_material", tetxbox))
end

function MaterialEditorPanel:current_material_name()
	return self._current_material_node and self._current_material_node:parameter("name")
end

function MaterialEditorPanel:current_material_config()
	return self._temp_material_config_path or self._material_config_path
end

function MaterialEditorPanel:create_parameter_panel(parent)
    local panel = parent:GetItem("parameters") or parent:pan("parameters", {auto_align = false, align_method = "centered_grid"})
    panel:ClearItems()

	if self._current_material_node then
		local name = self._current_material_node:parameter("name")
		self._parameters_group = panel:divgroup("SelectedMaterial", {text = name})
		local TB = self._parameters_group:GetToolbar()
		TB:tb_imgbtn("CopyMaterial", ClassClbk(self, "on_copy_material", name), nil, BLE.Utils.EditorIcons.copy, {help = "Copy Material"})
		TB:tb_imgbtn("RenameMaterial", ClassClbk(self, "on_rename_material"), nil, BLE.Utils.EditorIcons.pen, {help = "Rename Material"})

		if self._material_parameter_widgets then
			for k, v in pairs(self._material_parameter_widgets) do
				v:destroy()
			end
		end
		self._material_parameter_widgets = {}

		local widget = self._editor._parameter_widgets.render_template:new(self._parameters_group, self, self._current_material_node)
		self._material_parameter_widgets.render_template = widget

		local params = self._editor:get_render_template_params(self._current_render_template_name)
		for i, param in ipairs(params) do
			local node = nil

			if param.type == "texture" then
				node = CoreMaterialEditor._get_node(self, self._current_material_node, param.name)
			else
				node = CoreMaterialEditor._find_node(self, self._current_material_node, "variable", "name", param.name)
			end

			local widget_class = self._editor._parameter_widgets[param.ui_type]

			if not widget_class then
				--out("[" .. self.TOOLHUB_NAME .. "] Could not find widget class for: " .. param.ui_type .. " Using: " .. param.type)

				widget_class = self._editor._parameter_widgets[param.type]

				--assert(widget_class)
			end

			if widget_class then
				local widget = widget_class:new(self._parameters_group, self, param, node)
				self._material_parameter_widgets[param.name] = widget
			end

			--assert(not self._material_parameter_widgets[param.name], string.format("A widget with name %s, already exist! (This might be a bug in the shader config file.)", param.name))

			--self._material_parameter_widgets[param.name:s()] = widget
		end

		widget = self._editor._parameter_widgets.decal:new(self._parameters_group, self, self._current_material_node)
		self._material_parameter_widgets.decal = widget
	end

	panel:AlignItems(true)
end

function MaterialEditorPanel:on_customize_render_template(customize)
	self._gv_splitter:GetItem("materials"):SetEnabled(not customize)
	self._parameters_group:GetToolbar():SetEnabled(not customize)
	for name, widget in pairs(self._material_parameter_widgets) do
		if name ~= "render_template" then
			widget._panel:SetEnabled(not customize)
		end
	end
end

function MaterialEditorPanel:close()
    self._panel:Destroy()

	if self._material_config_path then
		local file_name = Path:GetFileName(self._material_config_path)
		local file = Path:Combine(BLE.TempDir, file_name..".material_config")
		if FileIO:Exists(file) then
			FileIO:Delete(file)
		end
	end

	if self._material_parameter_widgets then
		for k, v in pairs(self._material_parameter_widgets) do
			v:destroy()
		end
	end

	return true
end

function MaterialEditorPanel:destroy()
	self:close()
end

function MaterialEditorPanel:on_save()
	local path = self._material_config_path

	if not self._material_config_file then
		local asset = BeardLibFileManager:Get("material_config", path)
		if asset and FileIO:Exists(asset.file) then
			self._material_config_file = asset.file
		else
			self:on_save_as()
			return
		end
	end
	
	self:save_to_disk(self._material_config_file)
end

function MaterialEditorPanel:save_to_disk(path, node)
	local node = node or self._material_config_node:to_real_node()
	local valid, str = self._editor:check_valid_xml_on_save(node)

	if not valid then
		BLE.Utils:Notify("Writing To Disk", "You have customized one or more texture channel(s) in the material but you have not specified any texture(s) for:\n\n" .. str .. "\n\nDefaulting to " .. self.DEFAULT_TEXTURE .. ".", function()
			self._editor:set_channels_default_texture(node)
			self:save_to_disk(path, node)
		end)
		return
	end

	if not self._material_config_path then
		self._material_config_path = path
	end

	self._editor._last_used_dir = Path:GetDirectory(path)
	self._material_config_file = path

	if FileIO:WriteTo(path, node:to_xml()) then
		self._text_in_node = node:to_xml()
		self._editor:set_page_name(self, BLE.Utils:ShortPath(self._material_config_path))

		BLE.Utils:Notify("Material Config Saved!", "All data in this material config was saved to:\n"..tostring(path))
		self:load_node(node, self._material_config_path)
	end
end

function MaterialEditorPanel:on_save_as()
	BLE.FBD:Show({where = self._editor._last_used_dir or string.gsub(Application:base_path(), "\\", "/"), save = true, extensions = {"material_config"}, file_click = function(f)
	    if not f then
			return
		end
		self:save_to_disk(f..".material_config")
		BLE.FBD:Hide()
    end})
end


function MaterialEditorPanel:load_node(node, path)
	local current_name = self:current_material_name()

	self._material_config_path = path
	self._material_config_node = CoreSmartNode:new(node)

    if not self:version_check(self._material_config_path, self._material_config_node, true) then
	    self._material_config_path = nil
		self._material_config_node = nil

		return false
	end

	self._text_in_node = self._material_config_node:to_xml()

    self._material_group:SetValue(node:parameter("group"))
	self:_update_interface_after_material_list_change(current_name)
	self:update_output()

	return true
end

function MaterialEditorPanel:version_check(path, node, show_popup)
	if node:parameter("version") ~= MaterialEditor.MATERIAL_CONFIG_VERSION_TAG then
		if show_popup then
            BLE.Utils:Notify("ERROR!", "This material config is not of the expected version.")
		end

		return false
	end

	--if path == managers.database:base_path() .. self.PROJECT_GLOBAL_GONFIG_NAME or path == managers.database:base_path() .. self.CORE_GLOBAL_GONFIG_NAME then
	--	if show_popup then
	--		EWS:MessageDialog(self._main_frame, "This is the global material file! You can't open it like this.", "Open Material Config", "OK,ICON_ERROR"):show_modal()
	--	end

	--	return false
	--end

	return true
end

function MaterialEditorPanel:on_material_selected(name, item)
	local selected = name or item:Name()
	local mat = self._material_nodes[selected]
	if not mat then
		return
	end
	
	local ver = mat:parameter("version")

	if ver ~= self.MATERIAL_VERSION_TAG or mat == self._current_material_node then
		return
	end

	self._current_material_node = mat

    for _, mat in ipairs(self._materials_group:Items()) do
        mat:SetBorder({left = mat:Name() == selected})
    end
	--self:_load_shader_options()
	self:_find_render_template()
end

function MaterialEditorPanel:on_add_material(item)
    local name = item:Value()
    if name == "" then
        BLE.Utils:Notify("ERROR!", "Name cannot be empty!")
        return
    end
    if CoreMaterialEditor._find_node(self, self._material_config_node, "material", "name", name) then
        BLE.Utils:Notify("ERROR!", "Material with that name already exists!")
        return
    end
    local mat = self._material_config_node:make_child("material")

    mat:set_parameter("name", name)
    mat:set_parameter("render_template", self.DEFAULT_RENDER_TEMPLATE)
    mat:set_parameter("version", self.MATERIAL_VERSION_TAG)
    self:_update_interface_after_material_list_change(name)
    self:update_output()
end

function MaterialEditorPanel:on_rename_material()
	BLE.InputDialog:Show({title = "Rename Material", text = self._current_material_node:parameter("name"), callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = ClassClbk(self, "on_rename_material")})
            return
        end
        if CoreMaterialEditor._find_node(self, self._material_config_node, "material", "name", name) then
            BLE.Dialog:Show({title = "ERROR!", message = "A material with that name already exists!", callback = ClassClbk(self, "on_rename_material")})
           return
        end
		self._current_material_node:set_parameter("name", name)
		self:_update_interface_after_material_list_change(name)
    end})
end

function MaterialEditorPanel:on_copy_material()
	Application:set_clipboard(tostring(self._current_material_node:to_xml()))
	BLE.Utils:Notify("Copy Material", "Material copied to clipboard.")
end

function MaterialEditorPanel:on_paste_as_material()
	local paste = Application:get_clipboard()
	local node = Node.from_xml(paste)
	
	
	if not node then
		BLE.Utils:Notify("ERROR!", "No valid data to paste.")
		return
	end
	
	local ver = node:parameter("version")
	if ver ~= self.MATERIAL_VERSION_TAG then
		BLE.Utils:Notify("ERROR!", "Pasted data is not the expected material format.")
		return
	end

	local function paste(node, name)
		self._material_config_node:add_child(CoreSmartNode:new(node)):set_parameter("name", name)
		self:_update_interface_after_material_list_change(name)
		self:update_output()
		self:on_shader_option_chaged()
	end

	BLE.InputDialog:Show({title = "Pasted Material name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = ClassClbk(self, "on_paste_as_material")})
            return
        end

		local mat = CoreMaterialEditor._find_node(self, self._material_config_node, "material", "name", name)
		if mat then
			BLE.Utils:YesNoQuestion("A material with that name already exists! Overwrite?", function()
				self._material_config_node:remove_child_at(self._material_config_node:index_of_child(mat))
				paste(node, name)
			end)
		else
			paste(node, name)
		end
    end})
end

function MaterialEditorPanel:on_remove_material(name)
    BLE.Utils:YesNoQuestion("Do you want to remove the selected material?", function()
		local cur_name = self:current_material_name()
        local mat = self._material_nodes[name]
		self._material_config_node:remove_child_at(self._material_config_node:index_of_child(mat))
		
		self:_update_interface_after_material_list_change(cur_name ~= name and cur_name)
		self:create_parameter_panel(self._gv_splitter)
		self:update_output()
    end)
end

function MaterialEditorPanel:on_change_material_index(direction, item)
	local index = self._materials_group:GetIndex(item)
	local new_index = direction and index - 1 or index + 1

	if new_index > 0 and new_index <= self._material_config_node:num_children() then
		item:SetIndex(new_index)
		item.indx = new_index

		local node = self._material_config_node._children[index]
		table.delete(self._material_config_node._children, node)
		table.insert(self._material_config_node._children, new_index, node)

		self:update_output()
	end
end

function MaterialEditorPanel:on_change_group(item)
    local name = item:Value()
    if name == "" then 
		self._material_config_node:clear_parameter("group")
	else
    	self._material_config_node:set_parameter("group", name)
	end
    self:update_output()
end

function MaterialEditorPanel:update_output(clear, undoredo)
    if self._material_config_node then
        local new_xml = self._material_config_node:to_xml()

    	if self._material_config_node then
			self._editor:update_output(new_xml)
    	end


        local name = self._material_config_path
        if name then
            name = BLE.Utils:ShortPath(name)
        else
            name = "New Material Config"
        end

        if new_xml ~= self._text_in_node then
            name = name .. "*"
        end

		if not undoredo then
			BeardLib:AddDelayedCall("MaterialUndo"..name, 0.2, function()
				self._undo_stack:push(new_xml)
            end, true)
        end
        
        self._editor:set_page_name(self, name)

		local name = self:current_material_name()
        if clear and name then
            self:_update_interface_after_material_list_change(name)
        end
    end

	self._panel:AlignItems(true)
end

function MaterialEditorPanel:undo()
	self:undoredo("undo")
end

function MaterialEditorPanel:redo()
	self:undoredo("redo")
end

function MaterialEditorPanel:undoredo(f)
	local undo_state = self._undo_stack[f](self._undo_stack)

	if undo_state then
		local node = Node.from_xml(undo_state)
		self._material_config_node = CoreSmartNode:new(node)
		self:on_shader_option_chaged()
		self:update_output(true, true)
	end
end

function MaterialEditorPanel:data_diff()
	return self._text_in_node ~= self._material_config_node:to_xml()
end

function MaterialEditorPanel:load_shader_options()
	local shaders = clone(self._editor:get_compilable_shaders())
	local defines = clone(self._editor:get_shader_defines())

	return {shaders = shaders, defines = defines}
	--self._compilable_shader_combo_box:set_value(v.shader)
	--self:_build_shader_options()
	--self:_set_shader_options(v.defines)
end

function MaterialEditorPanel:load_decal_materials()
	return self._editor:load_decal_materials()
end

function MaterialEditorPanel:_find_render_template()
	if not self._current_material_node then
		return
	end
	--local t = {}
	--for k, v in pairs(self._shader_defines) do
	--	if v._checked then
	--		table.insert(t, v._define_node:parameter("name"))
	--	end
	--end

	self._current_render_template_name = self._current_material_node:parameter("render_template") --RenderTemplateDatabase:render_template_name_from_defines(rt_name, t)
	self._current_render_template = RenderTemplateDatabase:render_template(self._current_render_template_name:id())

	if self._current_render_template then
		self._current_material_node:set_parameter("render_template", self._current_render_template_name)
		--self:_load_parent_dropdown()
		self:create_parameter_panel(self._gv_splitter)
	end

	self:clean_parameters()
	self:update_output()
end

function MaterialEditorPanel:clean_parameters()
	if self._current_render_template then
		local remove_list = {}
		local variables = self._editor:get_render_template_params(self._current_render_template_name)

		for param in self._current_material_node:children() do
			local found = nil

			for _, var in ipairs(variables) do
				if param:parameter("type") ~= "texture" and param:parameter("name") == var.name:s() or param:name() == var.name:s() then
					found = true

					break
				end
			end

			if not found then
				table.insert(remove_list, param)
			end
		end

		for _, param in ipairs(remove_list) do
			self._current_material_node:remove_child_at(self._current_material_node:index_of_child(param))
		end
	end
end

function MaterialEditorPanel:find_matching_render_templates(defines, ignore_difference)
	local render_templates = self._editor:get_render_templates()
	local exact_match = ""
	local matches = {}

	for _, template in ipairs(render_templates) do
		local v = RenderTemplateDatabase:render_template_name_to_defines(template)
		local difference = math.abs(#v.defines - #defines.defines)
		if v.shader == defines.shader and table.contains_all(v.defines, defines.defines) and (ignore_difference or difference <= 2) then
			table.insert(matches, template)
			if difference == 0 then
				exact_match = template
			end
		end
	end
	table.sort(matches, function(a,b)
		return #a < #b
	end)

	if #matches == 0 and not ignore_difference then
		matches, exact_match = self:find_matching_render_templates(defines, true)
	end

	return matches, exact_match
end

function MaterialEditorPanel:on_reload()
	self:on_shader_option_chaged()
end

local ids_config = Idstring("material_config")
function MaterialEditorPanel:on_shader_option_chaged()
	self:_find_render_template()

	if self._material_config_path and PackageManager:has(ids_config, Idstring(self._material_config_path)) then
		self:create_temp_material_config()
	end
end

function MaterialEditorPanel:create_temp_material_config()
	local node = self._material_config_node:to_real_node()
	local file_name = Path:GetFileName(self._material_config_path)
	local file = Path:Combine(BLE.TempDir, file_name..".material_config")
	local path = Path:Combine("temp", file_name)

	FileIO:MakeDir(BLE.TempDir)

	if FileIO:Exists(file) then
		FileIO:Delete(file)
		BeardLib.Managers.File:RemoveFile("material_config", path)
	end

	if FileIO:WriteTo(file, node:to_xml()) then
		BeardLib.Managers.File:AddFile("material_config", path, file)
		self:refresh_temp_material_config(path)
	end
end

function MaterialEditorPanel:refresh_temp_material_config(path)
	local ids_temp = Idstring(path)
	local ids_config = Idstring(self._material_config_path)
	local config_name = self._temp_material_config_path and ids_temp or ids_config

	if config_name then
		local units_in_world = World:find_units_quick("all")

		for _, unit_in_world in ipairs(units_in_world) do
			if unit_in_world:material_config() == config_name then
				managers.dyn_resource:change_material_config(ids_config, unit_in_world, true)
				call_on_next_update(function() 
					managers.dyn_resource:change_material_config(ids_temp, unit_in_world, true)
				end)
			end
		end
	end
	self._temp_material_config_path = path
end

function MaterialEditorPanel:_update_interface_after_material_list_change(listbox_select_material)
	self._current_material_node = nil
	self:_load_material_list(listbox_select_material)
end

function MaterialEditorPanel:_load_material_list(listbox_select_material)
	local current_name = listbox_select_material or self:current_material_name()
	self._material_nodes = {}

	self._materials_group:ClearItems("material")

	if self._material_config_node then
		for material in self._material_config_node:children() do
			if material:name() == "material" then
				local name = material:parameter("name")
				self._material_nodes[name] = material
				local button = self._materials_group:button(name, ClassClbk(self, "on_material_selected", name), {label = "material"})
                button:tb_imgbtn("RemoveMaterial", ClassClbk(self, "on_remove_material", name), nil, BLE.Utils.EditorIcons.cross, {highlight_color = Color.red, help = "Remove Material"})
				button:tb_imgbtn("MoveDown", ClassClbk(self, "on_change_material_index", false, button), nil, BLE.Utils.EditorIcons.arrow_down, {help = "Move Material Down"})
				button:tb_imgbtn("MoveUp", ClassClbk(self, "on_change_material_index", true, button), nil, BLE.Utils.EditorIcons.arrow_up, {help = "Move Material Up"})

				if listbox_select_material == name then
					-- Nothing
				end
			end
		end
		if current_name then
			self:on_material_selected(current_name)
		end
	end
end

function MaterialEditorPanel:live_update_parameter(name, param_type, param_ui_type, value)
	self._editor:live_update_parameter(name, param_type, param_ui_type, value)
end