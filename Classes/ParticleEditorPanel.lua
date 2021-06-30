local stack_members = {
	initializer = {},
	simulator = {},
	visualizer = {}
}
local stack_member_names = {
	initializer = {},
	simulator = {},
	visualizer = {}
}

function CoreParticleEditorPanel:create_panel(parent)
	self._stacklist_boxes = {}
	self._stack_member_combos = {}
	self._stack_panels = {}
	self._panel = parent:Menu({auto_align = false, auto_height = true, align_method = "grid"})

	self._gv_splitter = self._panel:pan("gvsplitter") --EWS:SplitterWindow(splitter, "", "SP_NOBORDER")
	self._top_splitter = self._panel:pan("splitter") -- EWS:SplitterWindow(self._panel, "", "SP_NOBORDER")
	local effect_panel = self:create_effect_panel(self._gv_splitter)
	self._status_box = self:create_status_box(self._gv_splitter)
	local atom_panel = self:create_atom_panel(self._top_splitter)
	--local top_sizer = EWS:BoxSizer("VERTICAL")

	--self._panel:set_sizer(top_sizer)
	--top_sizer:add(splitter, 1, 0, "EXPAND")
	--splitter:set_sash_gravity(0)
	--splitter:split_vertically(gv_splitter, atom_panel, 100)
	--gv_splitter:set_sash_gravity(0)
	--gv_splitter:split_horizontally(effect_panel, self._status_box, 100)
	self:update_atom_combo()

	if #self._effect._atoms > 0 then
		self._atom_combo:SetValue(1)
		self:on_select_atom()
	else
		self._atom = nil
	end

	--self._stack_notebook:connect("EVT_COMMAND_NOTEBOOK_PAGE_CHANGED", ClassClbk(self, "clear_box_help"), "")
	self:update_view(true)
end

function CoreParticleEditorPanel:update_atom_combo()
	self._atom_combo:Clear()

	for _, atom in ipairs(self._effect._atoms) do
		self._atom_combo:Append(atom._name)
	end
end

function CoreParticleEditorPanel:create_effect_panel(parent)
	local panel = parent:pan("effect", {align_method = "centered_grid"})
    self._render_selected_only_check = panel:tickbox("RemderSelectedAtomOnly", ClassClbk(self, "on_set_selected_only"))
    self._atom_textctrl = panel:textbox("AtomSelector", ClassClbk(self, "on_rename_atom"), nil, {enabled = false})
    self._atom_combo = panel:combobox("AtomSelector", ClassClbk(self, "on_select_atom"))
    local buttons_panel = panel:pan("buttons", {align_method = "grid_from_right"})
	buttons_panel:tb_btn("Add", ClassClbk(self, "on_add_atom"))
	buttons_panel:tb_btn("Remove", ClassClbk(self, "on_remove_atom"))
	buttons_panel:tb_btn("Copy", ClassClbk(self, "on_copy_atom"))
    buttons_panel:tb_btn("Paste", ClassClbk(self, "on_paste_atom"))

	--[[local atoms_sizer = EWS:StaticBoxSizer(panel, "VERTICAL", "Atoms")

	row_sizer:add(EWS:StaticText(panel, "Atom:", "", ""), 0, 0, "EXPAND")
	row_sizer:add(self._atom_combo, 0, 0, "EXPAND")
	row_sizer:add(remove_button, 0, 0, "EXPAND")
	row_sizer:add(copy_button, 0, 0, "EXPAND")
	row_sizer:add(paste_button, 0, 0, "EXPAND")
	atoms_sizer:add(row_sizer, 0, 0, "EXPAND")
	row_sizer = EWS:BoxSizer("HORIZONTAL")
    
	row_sizer:add(EWS:StaticText(panel, "Rename/add atom:", "", ""), 0, 0, "LEFT,ALIGN_CENTER_VERTICAL")
	row_sizer:add(self._atom_textctrl, 0, 2, "LEFT")
	row_sizer:add(add_button, 0, 2, "LEFT")
	atoms_sizer:add(row_sizer, 0, 0, "EXPAND")
	atoms_sizer:add(self._render_selected_only_check, 0, 0, "EXPAND")
	top_sizer:add(atoms_sizer, 0, 0, "EXPAND")
    
    ]]
    
--	self:create_graph_view(self._editor._main_frame)
	--top_sizer:add(self._effect_properties_panel, 0, 0, "EXPAND")
	--panel:set_sizer(top_sizer)

    
	return panel
end

function CoreParticleEditorPanel:on_rename_atom()
	if self._effect:find_atom(self._atom_textctrl:get_value()) or #self._effect._atoms == 0 then
		return
	end

	self._atom:set_name(self._atom_textctrl:get_value())
	self:update_atom_combo()
	self._atom_combo:SetSelectedItem(self._atom_textctrl:get_value(), true)
end

function CoreParticleEditorPanel:on_add_atom()
    BLE.InputDialog:Show({title = "Atom name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = ClassClbk(self, "on_add_atom")})
            return
        end
        if self._effect:find_atom(name) then
            BLE.Dialog:Show({title = "ERROR!", message = "Atom with that name already exists!", callback = ClassClbk(self, "on_add_atom")})
           return
        end
        self._effect:add_atom(CoreEffectAtom:new(name))
        self:update_atom_combo()
        self._atom_combo:SetSelectedItem(name)
        self:on_select_atom()
    end})
end

function CoreParticleEditorPanel:update_status_box()
    local s = ""
    s = s ..self._box_status .. "\n"
    s = s .. "\n"
    s = s .. self._box_help_header .. "\n"
    s = s .. self._box_help .. "\n"
	self._status_box:SetText(s)
end

function CoreParticleEditorPanel:create_graph_view(parent)
	-- If anyone could code this, that'd be pretty poggers ♥
	--[[self._graph_view_dialog = EWS:Dialog(parent, "Stacks And Channels Overview", "", Vector3(-1, -1, 0), Vector3(500, 400, 0), "CAPTION,RESIZE_BORDER")
	self._graph = EWS:Graph()
	local gv = EWS:GraphView(self._graph_view_dialog, "", self._graph)

	gv:set_clipping(false)
	gv:toggle_style("SUNKEN_BORDER")

	self._graph_view = gv
	local top_sizer = EWS:BoxSizer("VERTICAL")

	top_sizer:add(gv, 1, 0, "EXPAND")
	self._graph_view_dialog:set_sizer(top_sizer)

	if self._editor._view_menu:is_checked("SHOW_STACK_OVERVIEW") then
		self:show_stack_overview(true)
	end]]
end

function CoreParticleEditorPanel:create_atom_panel(parent)
    local panel = parent:pan("atom")
	local notebook = panel:notebook("Effect/Stacks Properties")
	self._atom_panel = notebook:pan("Atom", {auto_height = false, h = 435})
	self._effect_properties_panel = notebook:pan("EffectProperties", {auto_height = false, h = 435})

	local initializer_page = self:create_stack_panel(notebook, "initializer")
	local simulator_page = self:create_stack_panel(notebook, "simulator")
	local visualizer_page = self:create_stack_panel(notebook, "visualizer")


	notebook:AddItemPage("Effect", self._effect_properties_panel)
	notebook:AddItemPage("Atom", self._atom_panel)
	notebook:AddItemPage("Initializer Stack", initializer_page)
	notebook:AddItemPage("Simulator Stack", simulator_page)
	notebook:AddItemPage("Visualizer Stack", visualizer_page)
	notebook:SetPage(1)
 
    self._stack_notebook = notebook
--	local top_sizer = EWS:BoxSizer("HORIZONTAL")

--	top_sizer:add(notebook, 1, 0, "EXPAND")
--	panel:set_sizer(top_sizer)

	return panel
end


function CoreParticleEditorPanel:create_stack_panel(parent, stacktype)
	local panel = parent:pan(stacktype, {align_method = "grid_from_right", auto_height = false, h = 435})
	self._stacklist_boxes[stacktype] = panel:pan("list")
	local stack_member_combo = panel:ComboBox({text = " ", control_slice = 1})
	local member_names = stack_member_names[stacktype]
	local last = nil

	for _, mn in ipairs(member_names) do
		stack_member_combo:Append(mn.ui_name)
		last = mn.ui_name
	end

	stack_member_combo:set_value(last)

	self._stack_member_combos[stacktype] = stack_member_combo
	panel:tb_btn("Up", ClassClbk(self, "on_stack_up", stacktype))
	panel:tb_btn("Down", ClassClbk(self, "on_stack_down", stacktype))
	panel:tb_btn("Add", ClassClbk(self, "on_stack_add", stacktype))
	panel:tb_btn("Copy", ClassClbk(self, "on_stack_copy", stacktype))
	panel:tb_btn("Paste", ClassClbk(self, "on_stack_paste", stacktype))

	self._stack_panels[stacktype] = panel:pan("Affector")

	return panel
end

function CoreParticleEditorPanel:create_status_box(parent)
	return parent:divider("")
end

function CoreParticleEditorPanel:on_select_atom()
	local atom = self._effect:find_atom(self._atom_combo:SelectedItem())
	self._atom = atom

	if atom then
		self._atom_textctrl:SetValue(atom:name())
	end

	self:update_view(true, true)
end

function CoreParticleEditorPanel:update_view(clear, undoredo)
	local n = Node("effect")

	self._atom_textctrl:SetEnabled(self._atom ~= nil)

	self._effect:save(n)

	local new_xml = n:to_xml()

	if not undoredo then
		self._undo_stack:push({
			name = self._effect:name(),
			xml = new_xml
		})
	end

	local name = self._effect:name()
	if name == "" then
		name = "New Effect"
	else
		name = BLE.Utils:ShortPath(name)
	end

	if new_xml ~= self._last_saved_xml then
		name = name .. "*"
	end
	
	self._editor:set_page_name(self, name)

	if clear then
		self._atom_panel:ClearItems()

		if self._atom then
			self._atom:fill_property_container_sheet(self._atom_panel, self)
		end
	elseif self._atom then
		--self:fill_timelines()
	end

	if clear then
		self._effect_properties_panel:ClearItems()

		if self._effect then
			self._effect:fill_property_container_sheet(self._effect_properties_panel, self)
		end
	end

	if clear then
		for stacktype, c in pairs(self._stacklist_boxes) do
			c:ClearItems()
			self._stack_panels[stacktype]:ClearItems()

			if self._atom then
				for i, m in ipairs(self._atom:stack(stacktype):stack()) do
					local btn = c:button(m:ui_name(), ClassClbk(self, "on_select_stack_member"), {divider_type = #m._properties == 0, stack_index = i, stack_type = stacktype})
					btn:tb_imgbtn("Remove", ClassClbk(self, "on_stack_remove"), nil, BLE.Utils:GetIcon("minus"))
					if c._prev_stack_item and c._prev_stack_item.stack_index == i and c._prev_stack_item.stack_type == stacktype then
						btn:RunCallback()
					end
				end
			end
		end
	end

	local valid = self._effect:validate()
	self._valid_effect = valid.valid

	
	if not valid.valid then
		self._box_status = valid.message
	else
		self._box_status = "Effect is valid"
	end

    --self._status_box:SetVisible(not valid.valid)

	self:update_status_box()

	--if self._editor._view_menu:is_checked("SHOW_STACK_OVERVIEW") then
	--	self:update_graph_view()
	--end

	self:safety_backup()

	if valid.valid then
		self:update_effect_instance()
	end
	
	self._panel:AlignItems(true, true)
end

function CoreParticleEditorPanel:update(t, dt)
	if self._valid_effect then
		if self._dirty_effect then
			self:reload_effect_definition()

			self._dirty_effect = false
		end

		if (not self._effect_id or not World:effect_manager():alive(self._effect_id)) and self._frames_since_spawn > 1 then
			local quality = self._quality
			quality = quality or 0.5
			self._quality = nil
            local gizmo = self._editor:effect_gizmo()
			self._effect_id = World:effect_manager():spawn({
				effect = Idstring("unique_test_effect_name"),
				parent = gizmo:get_object(Idstring("rp_root_point")),
				custom_quality = quality
			})
			self._frames_since_spawn = 0
		else
			self._frames_since_spawn = self._frames_since_spawn + 1
		end
	elseif self._effect_id then
		World:effect_manager():kill(self._effect_id)

		self._effect_id = nil
	end

	--[[if self._editor._view_menu:is_checked("SHOW_STACK_OVERVIEW") then
		self._graph_view:update_graph(dt)
	end]]
end
function CoreParticleEditorPanel:set_init_positions()
end

local effect_ids = Idstring("effect")
local unique_ids = Idstring("unique_test_effect_name")

function CoreParticleEditorPanel:reload_effect_definition()
	local n = Node("effect")

	if self._render_selected_only_check:get_value() and self._atom then
		self._atom:save(n)
	else
		self._effect:save(n)
	end

    local file = io.open("tmpeffect", "w")
    if file then
        file:write(n:to_xml())
        file:close()
        DB:remove_entry(effect_ids, unique_ids)
        local dyn = managers.dyn_resource
        if dyn:has_resource(effect_ids, unique_ids, dyn.DYN_RESOURCES_PACKAGE) then
            local key = dyn._get_resource_key(effect_ids, unique_ids, dyn.DYN_RESOURCES_PACKAGE)
            local entry = dyn._dyn_resources[key]
            entry.ref_c = 1 --Forces it to unload if for some reason it's loaded twice
            dyn:unload(effect_ids, unique_ids, dyn.DYN_RESOURCES_PACKAGE, false)
        end
        DelayedCalls:Remove("ReloadEffectSomething")
        DelayedCalls:Add("ReloadEffectSomething", 0.1, function()
			DB:create_entry(effect_ids, unique_ids, "tmpeffect")
            managers.dyn_resource:load(effect_ids, unique_ids, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
            self._effect_id = nil
        end)
    end
end

function CoreParticleEditorPanel:close()
	local n = Node("effect")

	self:on_lose_focus()
	self._effect:save(n)

	if n:to_xml() ~= self._last_saved_xml then
        local n = self._effect:name()

        if n == "" then
            n = "New Effect"
        end

        BLE.Utils:YesNoQuestion("Effect " .. n .. " was modified since last saved, save changes?", function()
            self:on_save()
        end)
	end

	--self._graph_view_dialog:destroy()
    self._panel:Destroy()

	return true
end

function CoreParticleEditorPanel:on_lose_focus()
	if self._effect_id and self._effect_id > 0 then
		World:effect_manager():kill(self._effect_id)
	end

	--self:show_stack_overview(false)
end

function CoreParticleEditorPanel:on_select_stack_member(item)
	if item.parent._prev_stack_item then
		item.parent._prev_stack_item:SetBorder({left = false})
	end
	item:SetBorder({left = true})
    self._stack_panels[item.stack_type]:ClearItems()
    self._atom:stack(item.stack_type):stack()[item.stack_index]:fill_property_container_sheet(self._stack_panels[item.stack_type], self)
	item.parent._prev_stack_item = item
	self:update_view()
end

function CoreParticleEditorPanel:on_save_as()
    BLE.FBD:Show({where = self._editor._last_used_dir or string.gsub(Application:base_path(), "\\", "/"), save = true, extensions = {"effect"}, file_click = function(f)
	    if not f then
			return
		end

        self._effect:set_name(f)
    
        self._editor._last_used_dir = f
        local node = Node("effect")
    
        self._effect:save(node)
    
        local new_xml = node:to_xml()
    
        self._undo_stack:push({
            name = self._effect:name(),
            xml = new_xml
        })
	
		BLE.FBD:Hide()
        return self:do_save(true)
    end})
end

function CoreParticleEditorPanel:do_save()
	local n = Node("effect")

    self._effect:save(n)
    FileIO:WriteTo(self._effect:name(), n:to_xml())
   
	self._last_saved_xml = n:to_xml()
	self._editor:set_page_name(self, BLE.Utils:ShortPath(self._effect:name()))
	return true
end

function CoreParticleEditorPanel:on_stack_remove(item) 
	self._atom:stack(item.parent.stack_type):remove(item.parent.stack_index)
	self:update_view(true)
end


function CoreParticleEditorPanel:on_stack_up(stacktype)
	local box = self._stacklist_boxes[stacktype]
	local selected = box._prev_stack_item

	if not selected then
		return
	end

	local stack = self._atom:stack(stacktype)
	local idx = selected.stack_index
	idx = stack:move_up(idx)
	self:update_view(true)
	local items = self._stacklist_boxes[stacktype]:Items()
	local item = items[idx]
	if item then
		item:RunCallback()
	end
end

function CoreParticleEditorPanel:on_stack_down(stacktype)
	local box = self._stacklist_boxes[stacktype]
	local selected = box._prev_stack_item

	if not selected then
		return
	end

	local stack = self._atom:stack(stacktype)
	local idx = selected.stack_index
	idx = stack:move_down(idx)
	self:update_view(true)
	local items = self._stacklist_boxes[stacktype]:Items()
	local item = items[idx]
	if item then
		item:RunCallback()
	end
end


function CoreParticleEditorPanel:on_stack_copy(stacktype)
	local box = self._stacklist_boxes[stacktype]
	local selected = box._prev_stack_item

	if not selected then
		return
	end

	self._editor._clipboard_type = stacktype
	self._editor._clipboard_object = deep_clone(self._atom:stack(stacktype):member(selected.stack_index))
end

function CoreParticleEditorPanel:on_stack_paste(stacktype)
	if self._editor._clipboard_type ~= stacktype or not self._editor._clipboard_object then
		return
	end

	local box = self._stacklist_boxes[stacktype]
	local selected = box._prev_stack_item

	if not selected then
		self._atom:stack(stacktype):add_member(deep_clone(self._editor._clipboard_object))
	else
		self._atom:stack(stacktype):insert_member(deep_clone(self._editor._clipboard_object), selected.stack_index)
	end

	self:update_view(true)
end

function CoreParticleEditorPanel:on_stack_add(stacktype)
	if not self._atom then
		return
	end

	local members = stack_members[stacktype]
	local member_names = stack_member_names[stacktype]
	local to_add_idx = self._stack_member_combos[stacktype]:Value()

	if tonumber(to_add_idx) and to_add_idx < 0 then
		return
	end

	self._atom:stack(stacktype):add_member(members[member_names[to_add_idx].key]())
	self:update_view(true)

	local items = self._stacklist_boxes[stacktype]:Items()
	local item = items[#items]
	if item then
		item:RunCallback()
	end
end

function CoreParticleEditorPanel:safety_backup()
end