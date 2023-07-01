core:import("CoreEngineAccess")
require("core/lib/utils/dev/tools/material_editor/CoreSmartNode")
require("core/lib/utils/dev/tools/material_editor/CoreMaterialEditorUtils")

MaterialEditor = MaterialEditor or class(EditorPart)
MaterialEditor.MATERIAL_CONFIG_VERSION_TAG = "3"
MaterialEditor.RENDER_TEMPLATE_DATABASE_PATH = "shaders/base"
MaterialEditor.DECAL_MATERIAL_FILE = "settings/decals"

function MaterialEditor:init(editor, menu)
	self._parent = editor
	self._triggers = {}

	local panel_width = BLE.Options:GetValue("ParticleEditorPanelWidth")
	self._menu = menu:Menu({
		auto_foreground = true,
		align_method = "grid",
		background_color = BLE.Options:GetValue("BackgroundColor"),
		visible = false,
		scrollbar = false,
		w = panel_width,
	})

	self._output_menu = menu:Menu({
		auto_foreground = true,
		align_method = "grid",
		background_color = BLE.Options:GetValue("BackgroundColor"),
		visible = false,
		scrollbar = false,
		position = "Right",
		w = menu:ItemsWidth(1) - panel_width,
	})
	local output_group = self._output_menu:group("Output", {text = "XML Output", auto_height = false, stretch_to_bottom = true, scrollbar = true})
	self._output = output_group:lbl("")

	self._parameter_widgets = {
		scalar = MaterialEditorScalar,
		vector3 = MaterialEditorVector,
		color3 = MaterialEditorColor,
		vector2 = MaterialEditorVector,
		texture = MaterialEditorTexture,
		intensity = MaterialEditorDVValue,
		render_template = MaterialEditorRenderTemplate,
		decal = MaterialEditorDecal
	}

	self._configs = {}
	self:create_main_frame()
end

function MaterialEditor:update(t, dt)
	if not self:enabled() then
        return
    end

	--self:_find_selected_unit()
	self:GetPart("static"):update(t, dt)

	if not self._disable_live_feedback then
		self:_live_update()
	end
end

function MaterialEditor:mouse_pressed(button, x, y)
	if not self:enabled() or self._menu:ChildrenMouseFocused() or  managers.editor:mouse_busy() then
        return
    end

	if button == Idstring("0") then
		self:GetPart("static"):select_unit()
	end
end

function MaterialEditor:disable()
	MaterialEditor.super.disable(self)
	self._menu:SetVisible(false)
	self._output_menu:SetVisible(false)

	self._compilable_shaders = nil
	self._shader_defines = nil
	self._template_params = nil
	self._decal_materials = nil
end

function MaterialEditor:enable()
	MaterialEditor.super.enable(self)
	self._menu:SetVisible(true)
	self:bind_opt("Undo", ClassClbk(self, "on_undo"))
    self:bind_opt("Redo", ClassClbk(self, "on_redo"))
	self:bind_opt("ToggleGUI", ClassClbk(self, "ToggleGUI"))
	self:_load_shader_dropdown()
end

function MaterialEditor:ToggleGUI() 
	self._menu:SetVisible(not self._menu:Visible())
 end

function MaterialEditor:on_close_material()
	local cur = self:current_material()

	local function close()
		self:update_output("")
		self._configs_notebook:RemovePageWithItem(cur:panel())
		cur:close()
		table.delete(self._configs, cur)
		
		self:on_config_changed(self:current_material_index())
	end

	if cur then
		if cur:data_diff() then
			BLE.Utils:YesNoQuestion("All unsaved changes will be lost!", function()
				close()
			end)
		else
			close()
		end
	end
end

function MaterialEditor:on_close()
	local function close()
		for _, m in ipairs(self._configs) do
			if not m:close() then
				return
			end
		end
		self._configs_notebook:RemoveAllPages()
		self._configs = {}
		self._parent._editor_active = false
		self._parent:set_enabled()
	end

	local unsaved = false
	for _, m in ipairs(self._configs) do
		if m:data_diff() then
			unsaved = true
		end
	end
	if unsaved then
		BLE.Utils:YesNoQuestion("All unsaved changes will be lost!", function()
			close()
		end)
	else
		close()
	end
end

function MaterialEditor:create_main_frame()
	ItemExt:add_funcs(self)
	self._menu:ClearItems()

	local file = self:popup("File")
	file:tb_btn("NewMaterialConfig", ClassClbk(self, "on_new"))
	file:tb_btn("OpenFromFile", ClassClbk(self, "on_open_file"))
	file:tb_btn("OpenFromDatabase", ClassClbk(self, "on_open_database"))
	file:tb_btn("OpenFromSelection", ClassClbk(self, "on_open_selection"))
    file:separator()
	file:tb_btn("Save", ClassClbk(self, "on_save"))
	file:tb_btn("SaveAs", ClassClbk(self, "on_save_as"))
	file:tb_btn("Close", ClassClbk(self, "on_close_material"))
    file:separator()
	file:tb_btn("Exit", ClassClbk(self, "on_close"))

	local edit = self:popup("Edit")
	edit:tb_btn("Undo(Ctrl-Z)", ClassClbk(self, "on_undo"))
	edit:tb_btn("Redo(Ctrl-Y)", ClassClbk(self, "on_redo"))

	local tools = self:popup("Tools")
	tools:tb_btn("ReloadMaterialConfig", ClassClbk(self, "on_reload"))
	--tools:tb_btn("IncludeInLevel", ClassClbk(self, "on_include")) Maybe added later
	tools:separator()
	tools:tickbox("Feedback", ClassClbk(self, "on_feedback"), true, {text = "Real Time Feedback"})
	tools:tickbox("ShowXMLOutput", ClassClbk(self, "on_show_output"), false)

	local help = self:popup("Help")
	help:tb_btn("How-To-UseGuide", SimpleClbk(os.execute, 'start "" "https://wiki.modworkshop.net/books/beardlib-editor-tutorials/page/material-config-editor"'))
	help:tb_btn("ProblemSolver", SimpleClbk(os.execute, 'start "" "https://www.payday2maps.net/totallynotasecretpage/"'))

	self._configs_notebook = self:notebook("MaterialConfigs", {page_changed = ClassClbk(self, "on_config_changed"), offset = 4, scrollbar = true, auto_height = false, stretch_to_bottom = true}) 
end


function MaterialEditor:add_config(node, path)
	--self._menu:ClearItems()

	local material_panel = MaterialEditorPanel:new(self, self._configs_notebook, node, path)
	if material_panel:load_node(node, path) then
		table.insert(self._configs, material_panel)

		if path then
			path = BLE.Utils:ShortPath(base_path(path), 3)
		else
			path = "New Material Config"
		end

		self._configs_notebook:AddItemPage(path, material_panel:panel())
		if self._configs_notebook:GetPageCount() > 1 then
			self._configs_notebook:SetPage(self._configs_notebook:GetCurrentPage() + 1)
		end
	else
		material_panel:close()
	end
end

function MaterialEditor:current_material()
	return self._configs[self:current_material_index()]
end

function MaterialEditor:current_material_index()
	return self._configs_notebook:GetCurrentPage()
end

function MaterialEditor:set_page_name(page, name)
	local i = self._configs_notebook:GetItemPage(page:panel())
	if i then
		self._configs_notebook:SetPageName(i, name)
	end
end

function MaterialEditor:on_new()
	--self:_save_current()

	self:add_config(self:_create_new_material_config())

	--if self:_load_node(path) then
	--	self:_update_interface_after_material_list_change()
	--	self:_reset_diff()
	--end
end

function MaterialEditor:on_open_file()
	BLE.FBD:Show({where = self._last_used_dir or string.gsub(Application:base_path(), "\\", "/"), extensions = {"material_config"}, file_click = function(f)
	    if not f  or not FileIO:Exists(f) then
			return
		end

		local node = SystemFS:parse_xml(f, "r")
		if node then
			self._last_used_dir = Path:GetDirectory(f)
			f = Path:GetFilePathNoExt(f)

			self:add_config(node, f)
			BLE.FBD:Hide()
		end
	end})
end

function MaterialEditor:on_open_database(item, path)

	local function open(path)
		local node = BLE.Utils:ParseXml("material_config", path)
		if not node then
			local asset = BeardLibFileManager:Get("material_config", path)
			if asset and FileIO:Exists(asset.file) then
				node = SystemFS:parse_xml(asset.file, "r")
			end
		end

		if node then
			self:add_config(node, path)
			BLE.ListDialog:Hide()
		end
	end

	if path then
		open(path)
	else
		local list = BLE.Utils:GetEntries({type = "material_config", filenames = false})
		BLE.ListDialog:Show({
			list = list,
			callback = function(path)
				open(path)
			end
		})
	end
end

function MaterialEditor:on_open_selection(item)
	local unit = self._parent:selected_unit()
	if alive(unit) and unit:unit_data() then

		--Try unhashing the material config
		local material_ids = unit:material_config()
		local config = BLE.Utils:Unhash(material_ids, "material_config")
		if config and config ~= material_ids:key() then
			self:on_open_database(item, config)
			return
		end

		--If cannot unhash for some reason, try to manually find the config path in the object file
		if unit:unit_data().material_variation then
			self:on_open_database(item, unit:unit_data().material_variation)
			return
		end

		local unit = unit:unit_data().name
		local object = ""
		local node = BLE.Utils:ParseXml("unit", unit)
		if not node then
			local asset = BeardLibFileManager:Get("unit", unit)
			if asset and FileIO:Exists(asset.file) then
				node = SystemFS:parse_xml(asset.file, "r")
			end
		end
		if node then
			for child in node:children() do
				if child:name() == "object" and child:has_parameter("file") then
					object = child:parameter("file")
					break
				end
			end
		end

		local onode = BLE.Utils:ParseXml("object", object)
		if not onode then
			local asset = BeardLibFileManager:Get("object", object)
			if asset and FileIO:Exists(asset.file) then
				onode = SystemFS:parse_xml(asset.file, "r")
			end
		end
		if onode then
			for child in onode:children() do
				if child:name() == "diesel" and child:has_parameter("materials") then
					self:on_open_database(item, child:parameter("materials"))
					break
				end
			end
		end
	end
end


function MaterialEditor:_create_new_material_config()
	local node = Node("materials")

	node:set_parameter("version", self.MATERIAL_CONFIG_VERSION_TAG)
	return node
end

function MaterialEditor:on_undo()
	local cur = self:current_material()

	if cur then
		cur:undo()
	end
end

function MaterialEditor:on_redo()
	local cur = self:current_material()

	if cur then
		cur:redo()
	end
end

function MaterialEditor:on_config_changed(new_page)
	local old_page = self._old_page

	if new_page and new_page > 0 and new_page <= #self._configs then
		local new_material = self._configs[new_page]

		new_material:update_output(false)
		self._old_page = new_page
	end
end

function MaterialEditor:on_include()
	local cur = self:current_material()

	if cur then

	end
end

function MaterialEditor:on_reload()
	local cur = self:current_material()

	if cur then
		cur:on_reload()
	end
end

function MaterialEditor:on_feedback()
	self._disable_live_feedback = not self._disable_live_feedback
end

function MaterialEditor:on_preview()
	local cur = self:current_material()

	if cur then
		cur:on_preview()
	end
end

function MaterialEditor:on_show_output(item)
	self._output_menu:SetVisible(item:Value())

	local cur = self:current_material()
	if cur then
		cur:update_output()
	else
		self:update_output("")
	end
end

function MaterialEditor:update_output(text)
	if self._output_menu:Visible() then
		self._output:SetText(text)
	end
end

function MaterialEditor:on_save()
	local cur = self:current_material()

	if cur then
		cur:on_save()
	end
end

function MaterialEditor:on_save_as()
	local cur = self:current_material()

	if cur then
		cur:on_save_as()
	end
end

function MaterialEditor:_load_shader_dropdown()
	self._compilable_shaders = {}
	self._shader_defines = {}
	self._template_params = {}
	if blt.asset_db.has_file(self.RENDER_TEMPLATE_DATABASE_PATH, "render_template_database") then
		local database = blt.asset_db.read_file(self.RENDER_TEMPLATE_DATABASE_PATH, "render_template_database")
		database = database and ScriptSerializer:from_custom_xml(database)
		if database and database.render_templates then
			for _, template in ipairs(database.render_templates) do
				local defines = string.split(template.name, ":")
				local shader = defines[1]
				if not table.contains(self._compilable_shaders, shader) then
					table.insert(self._compilable_shaders, shader)
				end
				table.remove(defines, 1)

				for _, define in ipairs(defines) do
					if not table.contains(self._shader_defines, define) then
						table.insert(self._shader_defines, define)
					end
				end
				self._template_params[template.name] = BeardLib.Utils:RemoveMetas(template.shader_input_declaration)
			end
		end
		table.sort(self._shader_defines)
	end
end

function MaterialEditor:get_render_template_params(render_template_name)
	return self._template_params[render_template_name]
end

function MaterialEditor:get_render_templates()
	return table.map_keys(self._template_params)
end

function MaterialEditor:get_compilable_shaders()
	return self._compilable_shaders
end

function MaterialEditor:get_shader_defines()
	return self._shader_defines
end

function MaterialEditor:load_decal_materials()
	if not self._decal_materials then
		self._decal_materials = {""}

		--local root = DB:load_node("decals", self.DECAL_MATERIAL_FILE)
		local root = BLE.Utils:ParseXml("decals", self.DECAL_MATERIAL_FILE)

		if root and root:num_children() > 0 then
			for material in root:children() do
				if material:name() == "material" then
					table.insert(self._decal_materials, material:parameter("name"))
				end
			end
		end
	end

	return self._decal_materials
end


function MaterialEditor:get_material()
	local cur = self:current_material()
	if cur and cur:current_material_config() then
		local config_name = Idstring(cur:current_material_config())
		local material_name = cur:current_material_name()
		if config_name and material_name then
			local units_in_world = World:find_units_quick("all")

			for _, unit_in_world in ipairs(units_in_world) do
				if unit_in_world:material_config() == config_name then
					local material = unit_in_world:material(Idstring(material_name))

					if material then
						return material
					end
				end
			end
		end
	end
end

function MaterialEditor:_update_material(param)
	local material = self:get_material()
	if material then
		if param.param_type == "texture" then
			local name_ids = Idstring(param.name)
			Application:set_material_texture(material, name_ids, Idstring(param.value), material:texture_type(name_ids), 0)
		elseif param.param_type == "vector3" or param.param_type == "scalar" then
			if param.name == "diffuse_color" then
				material:set_diffuse_color(param.value)
			elseif param.param_ui_type == "intensity" then
				material:set_variable(Idstring(param.name), LightIntensityDB:lookup(Idstring(param.value)))
			else
				material:set_variable(Idstring(param.name), param.value)
			end
		end
	end
end

function MaterialEditor:_live_update()
	if self._live_update_parameter_list then
		for _, param in ipairs(self._live_update_parameter_list) do
			self:_update_material(param)
		end

		self._live_update_parameter_list = {}
	end
end

function MaterialEditor:check_valid_xml_on_save(node)
	local str = nil

	for mat in node:children() do
		for var in mat:children() do
			if var:parameter("file") == "[NONE]" then
				str = (str and (str..", ") or "") .. var:name()
			end
		end
	end

	return str == nil, str
end

function MaterialEditor:set_channels_default_texture(node)
	for mat in node:children() do
		for var in mat:children() do
			if var:parameter("file") == "[NONE]" then
				var:set_parameter("file", MaterialEditorPanel.DEFAULT_TEXTURE)
			end
		end
	end
end

function MaterialEditor:live_update_parameter(name, param_type, param_ui_type, value)
	self._live_update_parameter_list = self._live_update_parameter_list or {}
	table.insert(self._live_update_parameter_list, {
		name = name,
		param_type = param_type,
		param_ui_type = param_ui_type,
		value = value
	})
end