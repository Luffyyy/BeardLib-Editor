function CoreEffectPropertyContainer:fill_property_container_sheet(window, view, no_border)
	local property_container = self

	local top_sizer = window:divgroup(property_container:name(), {text = property_container:ui_name(), align_method = "grid"})

	if property_container:description() ~= "" then
		top_sizer:GetToolbar():SButton("?", nil, {position = "TopRight", h = top_sizer:TextHeight(), help = property_container:name() .. "\n" .. property_container:description()})
	end

	local bgcolor = BLE.Options:GetValue("BackgroundColor")

	for i, p in ipairs(property_container:properties()) do
		if p._visible then
			if not no_border then
				p._bgcolor = bgcolor
			end
			p:create_widget(window, view, no_border)
		end
	end
end

function CoreEffectProperty:create_widget(parent, view, no_border)
    local widget = nil
    local name = self:name()
	if self._type == "value_list" then
		widget = parent:combobox(name, ClassClbk(self, "on_commit", view), self._values, nil, {background_color = self._bgcolor, highlight_color = nil})
		widget:set_value(self._value)
 	elseif self._type == "timeline" then
		--widget = EWS:TimelineEdit(parent, "")

		--view[self._timeline_init_callback](view, widget)
	elseif self._type == "vector3" or self._type == "vector2" then
		widget = parent:Vector3(name, ClassClbk(self, "on_commit", view), math.string_to_vector(self._value), {
			vector2 = true, background_visible = self._bgcolor and true, background_color = self._bgcolor, unhighlight_color = Color.transparent
		})
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
		widget = parent:pan(name, {background_color = self._bgcolor})
		local combo = widget:combobox(name, ClassClbk(self, "on_set_variant", {
			update = true,
			container = widget,
			view = view,
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
		widget = parent:pan(name, {background_color = self._bgcolor})

		self._compound_container:fill_property_container_sheet(widget, view, true)
    elseif self._type == "list_objects" then
        local vars
		local prev

		local function on_add_object()
			table.insert(vars.property._list_members, deep_clone(self._list_objects[vars.combo:SelectedItem()]))
			vars:fill_list()
			vars.view:update_view(false)
		end

		local function on_remove_object(item)
			table.delete(vars.property._list_members, item.parent.property)
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
			if prev then
				prev:SetBorder({left = false})
			end
			item:SetBorder({left = true})
			prev = item
			item.property._bgcolor = self._bgcolor
			item.property:create_widget(vars.sheet, vars.view)
		end

		local function fill_list()
			vars.list_box:ClearItems()

            for i, p in ipairs(vars.property._list_members) do
				local btn = vars.list_box:button(p:name(), on_select_object, {property = p})
				btn:ImgButton("Remove", on_remove_object, nil, BLE.Utils:GetIcon("minus"))
			end
		end

		widget = parent:pan(name, {align_method = "grid", background_color = self._bgcolor})
		local list_box = widget:pan("", {h = 250})
		local combo = widget:combobox(" ", nil, nil, nil, {control_slice = 1, shrink_width = 0.93})

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
		widget = parent:pan(name, {background_color = self._bgcolor})
		local keys_pan
		local function sort_keys()
			table.sort(keys_pan._my_items, function(a,b) return tonumber(a.key.t) < tonumber(b.key.t) end)
			table.sort(self._keys, function(a,b) return tonumber(a.t) < tonumber(b.t) end)
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
				end, nil, BLE.Utils:GetIcon("minus"), {index = 1, size = t:TextHeight()})
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
		if self._presets then
			local presets = {}
			for _, preset in pairs(self._presets) do
				table.insert(presets, preset[1])
			end
			widget:combobox("Presets", function(item)
				self._keys = {}
				for _, preset in pairs(self._presets[item:Value()][2]) do
					local val = preset[2]
					log(tostring(val))
					if type_name(val) == "Vector3" then
						if key == "vector2" then
							val = val.x .. " " .. val.y
						else
							val = val.x .. " " .. val.y .. " " .. val.z
						end
					end
					table.insert(self._keys, {t = preset[1], v = val})
				end
				load_keys()
			end, presets, nil)
		end
		widget:tickbox("Loop", function(item) self._looping = tostring(item:Value()) end, self._looping == "true")

		keys_pan = widget:pan("Keys")
		load_keys()
	elseif self._type == "boolean" then
		widget = create_check(parent, view, self)
	else
		widget = create_text_field(parent, view, self)
	end

	if widget and not no_border then
		widget.offset[2] = 12
		widget:SetBorder({bottom = true, size = 1, color = widget.foreground:with_alpha(0.2)})
	end

	return widget
end

function create_text_field(parent, view, prop)
    return parent:textbox(prop:name(), ClassClbk(prop, "on_commit", view), prop._value, {background_color = prop._bgcolor})
end

function create_color_selector(parent, view, prop)
    return parent:colorbox(prop:name(), function(item)
        local c = item:Value() * 255
        prop._value = c.r .. " " .. c.g .. " " .. c.b
        view:update_view(false)
    end, math.string_to_vector(prop._value) * 0.00392156862745098, {background_color = prop._bgcolor})
end

function create_texture_selector(parent, view, prop)
    return parent:pathbox(prop:name(), ClassClbk(prop, "on_commit", view), prop._value, "texture", {background_color = prop._bgcolor})
end

function create_effect_selector(parent, view, prop)
    return parent:pathbox(prop:name(), ClassClbk(prop, "on_commit", view), prop._value, "effect", {background_color = prop._bgcolor})
end

function create_percentage_slider(parent, view, prop)
    return parent:slider(prop:name(), ClassClbk(prop, "on_commit", view), tonumber(prop._value), {min = 0, max = 1, background_color = prop._bgcolor})
end

function create_check(parent, view, prop)
    return parent:tickbox(prop:name(), function(item)
		prop._value = item:Value() and "true" or "false"
		view:update_view(false)
	end, prop._value == "true", {background_color = prop._bgcolor})
end

function CoreEffectProperty:on_set_variant(widget_view_variant, item)
	local view = widget_view_variant.view
	local variant_panel = item.parent:GetItem("VariantPanel")
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
		if self._type == "vector3" then
			value = value.x.." "..value.y
		elseif self._type == "vector2" then
			value = value.x.." "..value.y.." "..value.z
		end
		self._value = value

		view:update_view(false)
	end
end
