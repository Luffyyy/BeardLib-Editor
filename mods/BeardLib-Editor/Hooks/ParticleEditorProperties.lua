function CoreEffectPropertyContainer:fill_property_container_sheet(window, view)
	local property_container = self

	local top_sizer = window:divgroup(property_container:name(), {text = property_container:ui_name(), align_method = "grid"})

	if property_container:description() ~= "" then
		top_sizer.help = property_container:name() .. "\n" .. property_container:description()
	end

	for i, p in ipairs(property_container:properties()) do
		if p._visible then
		--	local name_text = window:divider(p:name(), {help = property_container:name() .. " / " .. p:name() .. "\n"..p:help()})

			local w = p:create_widget(window, view)

--[[
		
			if i ~= #property_container:properties() then
				local la = EWS:StaticLine(window, "", "LI_HORIZONTAL")

				la:set_min_size(Vector3(10, 2, 0))
				grid_sizer:add(la, 0, 0, "EXPAND")

				local lb = EWS:StaticLine(window, "", "LI_HORIZONTAL")

				lb:set_min_size(Vector3(10, 2, 0))
				grid_sizer:add(lb, 1, 0, "EXPAND")
			end
			]]
		end
	end
end

function CoreEffectProperty:create_widget(parent, view)
    local widget = nil
    local name = self:name()

	if self._type == "value_list" then
		widget = parent:combobox(name, ClassClbk(self, "on_commit", view), self._values)
		widget:set_value(self._value)
 	elseif self._type == "timeline" then
		--widget = EWS:TimelineEdit(parent, "")

		--view[self._timeline_init_callback](view, widget)
	elseif self._type == "vector3" or self._type == "vector2" then
		widget = parent:Vector3(name, ClassClbk(self, "on_commit", view), math.string_to_vector(self._value), {vector2 = true})
	elseif self._type == "box" then
	--[[	widget = EWS:AABBSelector(parent, "", math.string_to_vector(self._min), math.string_to_vector(self._max))

		local function on_box_commit(widget_view)
			if math.string_to_vector(self._min) ~= widget_view.widget:get_min() or math.string_to_vector(self._max) ~= widget_view.widget:get_max() then
				local minv = widget_view.widget:get_min()
				local maxv = widget_view.widget:get_max()
				self._min = minv.x .. " " .. minv.y .. " " .. minv.z
				self._max = maxv.x .. " " .. maxv.y .. " " .. maxv.z

				widget_view.view:update_view(false)
			end
		end

		widget:connect("EVT_SELECTOR_UPDATED", on_box_commit, {
			widget = widget,
			view = view
		})]]
	elseif self._type == "variant" then
		widget = parent:pan(name)
		local combo = widget:combobox("Variant", ClassClbk(self, "on_set_variant", {
			update = true,
			container = widget,
			view = view,
			variant_panel = variant_panel,
			container_sizer = sizer
		}))

        combo.help = self._help

		for vn, p in pairs(self._variants) do
			combo:Append(tostring(vn))
		end
		combo:set_value(tostring(self._value))

		local variant_panel = widget:pan("VariantPanel")

		self:on_set_variant({
			update = false,
			container = widget,
			view = view,
			variant_panel = variant_panel,
			container_sizer = sizer
		}, combo)
	elseif self._type == "compound" then
		widget = parent:pan(name)

		self._compound_container:fill_property_container_sheet(widget, view)
    elseif self._type == "list_objects" then
        local vars

		local function on_add_object()
			table.insert(vars.property._list_members, deep_clone(self._list_objects[vars.combo:SelectedItem()]))
			vars:fill_list()
			vars.view:update_view(false)
		end

		local function on_remove_object()
			if not vars.list_box.selected then
				return
			end

			table.delete(vars.property._list_members, vars.list_box.selected)
			vars:fill_list()
			vars:on_select_object()
			vars.view:update_view(false)
		end

        local function on_select_object(item)
            if vars.list_box.selected then
                vars.list_box.selected:SetBorder({left = false})
            end
            vars.list_box.selected = item
			vars.sheet:ClearItems()
            item:SetBorder({left = true})
			vars.property._list_members[vars.list_box:selected_index() + 1]:create_widget(vars.sheet, vars.view)
		end

		local function fill_list()
			vars.list_box:ClearItems()

            for _, p in ipairs(vars.property._list_members) do
                vars.list_box:Button(self, on_select_object)
			end
		end

		widget = parent:pan(name, {align_method = "grid"})
		local list_box = widget:pan("", {h = 250})
		local remove_button = widget:SButton("Remove", on_remove_object)
		local combo = widget:combobox(" ", nil, nil, nil, {control_slice = 1, shrink_width = 0.7})

		for n, p in pairs(self._list_objects) do
			combo:Append(n)
			combo:SetValue(n)
		end

		local add_button = widget:SButton("Add", on_add_object)
		local sheet = widget:pan("Sheet")
		vars = {
			property = self,
			combo = combo,
			container = widget,
			list_box = list_box,
			fill_list = fill_list,
			sheet = sheet,
			view = view,
			on_select_object = on_select_object
		}

		fill_list(vars)
	elseif self._type == "null" then
		widget = parent:pan(name)
	elseif self._type == "color" then
		widget = create_color_selector(parent, view, self)
	elseif self._type == "texture" then
		widget = create_texture_selector(parent, view, self)
	elseif self._type == "effect" then
		widget = create_effect_selector(parent, view, self)
	elseif self._type == "percentage" then
		widget = create_percentage_slider(parent, view, self)
	elseif self._type == "keys" then
		widget = parent:pan(name)
		local keys_pan
		local function sort_keys()
			--doesn't sort in xml?
			table.sort(keys_pan._my_items, function(a,b) return tonumber(a.key.t) < tonumber(b.key.t) end)
		end
		local function load_keys()
			keys_pan:ClearItems()
			local key = self._key_type
			for i, k in ipairs(self._keys) do
				local v = Vector3(0, 0, 0)
				local vs = k.v
				local pan = keys_pan:pan("Key"..i, {key = k, offset = 0, align_method = "grid"})
				local t = pan:numberbox("Time", function(item)
					k.t = item:Value()
					sort_keys()
					keys_pan:AlignItems()
				end, k.t, {shrink_width = 0.3, control_slice = 0.65})
				local function set_value(item)
					local val = item:Value()
					if type_name(val) == "Vector3" then
						if key == "vector2" then
							val = val.x .. " " .. val.y
						else
							val = val.x .. " " .. val.y .. " " .. val.z
						end
					end
					k.v = val
				end

				local vec = math.string_to_vector(vs)
				if key == "vector2" or key == "vector3" then
					control = pan:Vector3("Value", set_value, vec, {shrink_width = 0.6, vector2 = true})
				elseif key == "color" then
					control = pan:colorbox("Value", set_value, vec, {ret_vec = true, shrink_width = 0.6})
				elseif key == "float" or "opacity" or "time" then
					control = key == "opacity" and pan:slider("Value", set_value, vs, {min = 0, max = 255, shrink_width = 0.6}) or pan:numberbox("Value", set_value, vs, {shrink_width = 0.6})
				end
				pan:ImgButton("Remove", function()
					table.remove(self._keys, i)
					pan:Destroy()
					view:update_view(false)
				end, nil, BLE.Utils:GetIcon("cross"), {size = t:TextHeight()})
			end
			--[[
				if self._presets then
					widget:set_presets(self._presets)
				end
			]]
		end
		widget:button("AddKey", function()
			table.insert(self._keys, 1, {t = 0, v = key == "vector3" and "0 0 0" or key == "vector2" and "0 0" or "0"})
			local keys = widget:GetItem("Keys")
			sort_keys()
			load_keys()
		end)
		widget:tickbox("Loop", function(item) self._looping = tostring(item:Value()) end, self._looping == "true")

		keys_pan = widget:pan("Keys")
		load_keys()
	elseif self._type == "boolean" then
		widget = create_check(parent, view, self)
	else
		widget = create_text_field(parent, view, self)
	end

	return widget
end

function create_text_field(parent, view, prop)
    return parent:textbox(prop:name(), ClassClbk(prop, "on_commit", view), prop._value)
end

function create_color_selector(parent, view, prop)
    return parent:colorbox(prop:name(), function(item)
        local c = item:Value() * 255
        prop._value = c.r .. " " .. c.g .. " " .. c.b
        view:update_view(false)
    end, math.string_to_vector(prop._value) * 0.00392156862745098)
end

function create_texture_selector(parent, view, prop)
    return parent:pathbox(prop:name(), ClassClbk(prop, "on_commit", view), prop._value, "texture")
end

function create_effect_selector(parent, view, prop)
    return parent:pathbox(prop:name(), ClassClbk(prop, "on_commit", view), prop._value, "effect")
end

function create_percentage_slider(parent, view, prop)
    return parent:slider(prop:name(), ClassClbk(prop, "on_commit", view), tonumber(prop._value), {min = 0, max = 1})
end

function create_check(parent, view, prop)
    return parent:tickbox(prop:name(), function(item)
		prop._value = item:Value() and "true" or "false"
		view:update_view(false)
	end, prop._value == "true")
end

function create_key_curve_widget(parent, view, prop)
	local function refresh_list(vars)
		local listbox = vars.listbox
		local prop = vars.prop

		listbox:clear()

		for _, k in ipairs(prop._keys) do
			listbox:append("t = " .. k.t .. ", v = " .. k.v)
		end

		vars.view:update_view(false)
	end

	local function on_add(vars)
		local listbox = vars.listbox
		local t = vars.t
		local v = vars.v
		local prop = vars.prop

		if #prop._keys < prop._max_keys then
			prop:add_key({
				t = t:get_value(),
				v = v:get_value()
			})
			vars:refresh_list()
		end
	end

	local function on_remove(vars)
		local listbox = vars.listbox
		local t = vars.t
		local v = vars.v
		local prop = vars.prop

		if listbox:selected_index() < 0 then
			return
		end

		if prop._min_keys < #prop._keys then
			table.remove(prop._keys, listbox:selected_index() + 1)
			vars:refresh_list()
		end
	end

	local function on_select(vars)
		local listbox = vars.listbox
		local t = vars.t
		local v = vars.v
		local prop = vars.prop

		if listbox:selected_index() < 0 then
			return
		end

		t:set_value(prop._keys[listbox:selected_index() + 1].t)
		v:set_value(prop._keys[listbox:selected_index() + 1].v)
	end

	local function on_set(vars)
		local listbox = vars.listbox
		local t = vars.t
		local v = vars.v
		local prop = vars.prop

		if listbox:selected_index() < 0 then
			return
		end

		prop._keys[listbox:selected_index() + 1].t = t:get_value()
		prop._keys[listbox:selected_index() + 1].v = v:get_value()

		vars:refresh_list()
	end

	local panel = EWS:Panel(parent, "", "")
	local listbox = EWS:ListBox(panel, "", "LB_SINGLE,LB_HSCROLL")
	local add_button = EWS:Button(panel, "Add", "", "BU_EXACTFIT")
	local remove_button = EWS:Button(panel, "Remove", "", "BU_EXACTFIT")
	local t = EWS:TextCtrl(panel, "0", "", "TE_PROCESS_ENTER")

	t:set_min_size(Vector3(40, -1, 0))

	local v = EWS:TextCtrl(panel, "0 0 0", "", "TE_PROCESS_ENTER")
	local top_sizer = EWS:BoxSizer("VERTICAL")

	top_sizer:add(listbox, 1, 0, "EXPAND")

	local row_sizer = EWS:BoxSizer("HORIZONTAL")

	row_sizer:add(add_button, 0, 4, "ALL")
	row_sizer:add(remove_button, 0, 4, "ALL")
	top_sizer:add(row_sizer, 0, 0, "EXPAND")

	row_sizer = EWS:BoxSizer("HORIZONTAL")

	row_sizer:add(EWS:StaticText(panel, "t = ", "", ""), 0, 4, "ALIGN_CENTER_VERTICAL,LEFT,RIGHT")
	row_sizer:add(t, 0, 0, "")
	row_sizer:add(EWS:StaticText(panel, "v = ", "", ""), 0, 4, "ALIGN_CENTER_VERTICAL,LEFT,RIGHT")
	row_sizer:add(v, 1, 0, "EXPAND")
	top_sizer:add(row_sizer, 0, 0, "EXPAND")
	panel:set_sizer(top_sizer)

	local vars = {
		listbox = listbox,
		t = t,
		v = v,
		prop = prop,
		refresh_list = refresh_list,
		view = view
	}

	refresh_list(vars)
	add_button:connect("EVT_COMMAND_BUTTON_CLICKED", on_add, vars)
	remove_button:connect("EVT_COMMAND_BUTTON_CLICKED", on_remove, vars)
	v:connect("EVT_COMMAND_TEXT_ENTER", on_set, vars)
	listbox:connect("EVT_COMMAND_LISTBOX_SELECTED", on_select, vars)
	listbox:select_index(0)
	on_select(vars)

	return panel
end

function CoreEffectProperty:on_set_variant(widget_view_variant, item)
	local view = widget_view_variant.view
	local variant_panel = widget_view_variant.variant_panel
	local container = widget_view_variant.container
	local container_sizer = widget_view_variant.container_sizer
	self._value = item:SelectedItem()
	local variant = self._variants[self._value]

	variant_panel:ClearItems()
	variant:create_widget(variant_panel, view)

	if widget_view_variant.update then
		view:update_view(false)
	end
end

function CoreEffectProperty:on_commit(view, item)
	if self._type == "null" then
		return
	end

	local value = item:get_value()
	if self._value ~= value then
		self._value = value

		view:update_view(false)
	end
end
