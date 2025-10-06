--snake_case
--snek

local C = BeardLib.Items

local Item = C.Item
local Slider = C.Slider

function Slider:set_range(min, max)
	self.min = min
	self.max = max
end

local ComboBox = C.ComboBox

ComboBox.set_value = ComboBox.SetSelectedItem
ComboBox.get_value = ComboBox.SelectedItem

local COLOR = BLE.Options:GetValue("AccentColor")
ItemExt = {}
ItemExt.get_value = Item.Value
ItemExt.set_value = Item.SetValue
ItemExt.set_enabled = Item.SetEnabled
ItemExt.set_visible = Item.SetVisible

ItemExt.DEFAULT_OFFSET = {BLE.Options:GetValue("BoxesXOffset"), BLE.Options:GetValue("BoxesYOffset")}
ItemExt.ITEMS_OFFSET = {BLE.Options:GetValue("ItemsXOffset"), BLE.Options:GetValue("ItemsYOffset")}
local SIZE = BLE.Options:GetValue("MapEditorFontSize")

function ItemExt:get_boxes_offset()
	return clone(self.DEFAULT_OFFSET)
end

function ItemExt:get_items_offset()
	return clone(self.ITEMS_OFFSET)
end

function ItemExt:getmenu()
	return self
end

function ItemExt:tb_imgbtn(name, callback, texture, rect, o)
	local offset = self:ConvertOffset(o and o.offset or 4)
	local s = (o and o.size or self:H()) - offset[1]*2
	return self:ImageButton(table.merge({
		name = name,
		on_callback = callback,
		auto_foreground = false,
		offset = offset,
		w = s,
		h = s,
		img_scale = 0.6,
		texture = texture or BLE.Utils.EditorIcons.texture,
		texture_rect = rect,
	}, o))
end

function ItemExt:tb_visbtn(name, callback, value, o)
	local offset = self:ConvertOffset(o and o.offset or 4)
	local s = (o and o.size or self:H()) - offset[1]*2
	return self:ImageButton(table.merge({
		name = name,
		on_callback = function(p)
			p.value = not p.value

			p:SetEnabledAlpha(p.value and 1 or 0.5)
			p:SetImage(BLE.Utils.EditorIcons.texture, BLE.Utils.EditorIcons[p.value and "eye" or "invisible"])
			callback(p)
		end,
		auto_foreground = false,
		offset = offset,
		w = s,
		h = s,
		img_scale = 0.6,
		value = value,
		texture = BLE.Utils.EditorIcons.texture,
		texture_rect = BLE.Utils.EditorIcons[value and "eye" or "invisible"]
	}, o))
end

function ItemExt:tb_btn(name, callback, o)    
	return self:Button(table.merge({
		name = name,
		text = string.pretty2(name),
		on_callback = callback,
		size_by_text = true,
		offset = 2,
		text_align = "center",
	}, o))
end

function ItemExt:s_btn(name, callback, o)
	return self:Button(table.merge({
		name = name,
		text = string.pretty2(name),
		on_callback = callback,
		size_by_text = true,
		text_align = "center",
	}, o))
end

function ItemExt:sq_btn(name, callback, o)
	local s = self.size * 1.4
	o = o or {}
	o.text_align = "center"
	o.fit_width = false
	o.w = s
	o.h = s
	return self:button(name, callback, o)
end

function ItemExt:Pasta1(name, callback, o)
	return table.merge({name = name, on_callback = callback, text = string.pretty2(name)}, o)
end

function ItemExt:Pasta2(name, callback, value, o)
	return table.merge({name = name, on_callback = callback, text = string.pretty2(name), value = value}, o)
end

function ItemExt:tickbox(...)
	return self:Toggle(ItemExt:Pasta2(...))
end

function ItemExt:button(...)
	return self:Button(ItemExt:Pasta1(...))
end

function ItemExt:ubutton(name, clbk, o)
	o = o or {}
	o.border_bottom = true
	return self:Button(ItemExt:Pasta1(name, clbk, o))
end

function ItemExt:numberbox(...)
	return self:NumberBox(ItemExt:Pasta2(...))
end

function ItemExt:textbox(...)
	return self:TextBox(ItemExt:Pasta2(...))
end

function ItemExt:slider(...)
	return self:Slider(ItemExt:Pasta2(...))
end

function ItemExt:keybind(...)
	local k = self:KeyBind(ItemExt:Pasta2(...))
	k.supports_additional = true
	return k
end

function ItemExt:pan(name, o)
	return self:Menu(table.merge({name = name, auto_height = true, offset = self:get_boxes_offset(), inherit_values = {offset = self:get_items_offset()}}, o))
end

function ItemExt:lbl(name, o)
	return self:Divider(table.merge({name = name, text = name}, o))
end

function ItemExt:ulbl(name, o)
	return self:Divider(table.merge({name = name, border_bottom = true, text = name}, o))
end

function ItemExt:divider(name, o)
	return self:Divider(table.merge({name = name, text = string.pretty2(name), color = COLOR, offset = {8, 4}}, o))
end

function ItemExt:img(name, o)
	return self:Image(table.merge({name = name, text = name}, o))
end

function ItemExt:separator(o)
	return self:Divider(table.merge({
		name = "div", text = o and o.text or "", h = (not o or not o.text) and 2 or nil, size_by_text = false, border_bottom = true, border_color = self.foreground:with_alpha(0.1)
	}, o))
end

function ItemExt:group(name, o)
	return self:Group(table.merge({
		color = COLOR,
		name = name,
		text = string.pretty2(name),
		offset = self:get_boxes_offset(),
		closed = self.saved_group_states and self.saved_group_states[name] or false,
		inherit_values = {
			size = SIZE,
            highlight_color = BLE.Options:GetValue("ItemsHighlight"),
			offset = self:get_items_offset()
		},
		private = {
			size = SIZE,
			background_color = COLOR:with_alpha(0.15), highlight_color = COLOR:with_alpha(0.15)
		},
		on_group_toggled = function(item)
			self.saved_group_states = self.saved_group_states or {}
			self.saved_group_states[name] = item.closed
		end,
	}, o))
end

function ItemExt:notebook(name, o)
	return self:NoteBook(table.merge({color = COLOR, name = name, text = string.pretty2(name)}, o))
end

function ItemExt:popup(name, o)
	return self:PopupMenu(table.merge({name = name, text = string.pretty2(name)}, o))
end

function ItemExt:tholder(name, o, text_o)
	local holder = self:holder(name, o)
	holder:ulbl(name, text_o or o and o.text_o or nil)
	return holder
end

function ItemExt:holder(name, o)
	return self:Holder(table.merge({name = name, text = string.pretty2(name), offset = self:get_boxes_offset(), inherit_values = {offset = self:get_items_offset()}}, o))
end

function ItemExt:divgroup(name, o)
	return self:DivGroup(table.merge({
		name = name,
		color = COLOR,
		offset = self:get_boxes_offset(),
		private = {
			size = SIZE * 1.2,
			background_color = COLOR:with_alpha(0.2),
		},
		inherit_values = {
			offset = self:get_items_offset(),
			size = SIZE,
		},
		text = string.pretty2(name),
		auto_height = true,
		background_visible = false
	}, o))
end

function ItemExt:simple_divgroup(name, o)
	return self:DivGroup(table.merge({
		name = name,
		offset = self:get_boxes_offset(),
		inherit_values = {offset = self:get_items_offset()},
		text = string.pretty2(name),
		auto_height = true,
		background_visible = false
	}, o))
end

function ItemExt:combobox(name, callback, items, value, o)
	return self:ComboBox(table.merge({
		name = name,
		text = string.pretty2(name),
		value = value,
		items = items,
		bigger_context_menu = true,
		on_callback = callback,
	}, o))
end

function ItemExt:colorbox(name, callback, value, o)
	local item = self:ColorTextBox(table.merge({
		name = name,
		text = string.pretty2(name),
		on_callback = callback,
		value = value
	}, o))
	if o and o.ret_vec then
		function item:Value()
			local v = BeardLib.Items.ColorTextBox.Value(self)
			return Vector3(v.r, v.g, v.b)
		end
	end
	return item
end

function ItemExt:alert(text, color)
	local div = self:lbl(text, {color = true, private = {background_color = self.full_bg_color}, highlight_color = self.full_bg_color, min_height = 24, text_offset = {4, 4, 32, 4}, border_color = color or Color.yellow, border_lock_height = false})
	div:tb_imgbtn("Alert", nil, nil, BLE.Utils.EditorIcons.alert, {divider_type = true, img_scale = 0.8, w = 24, h = 24})
	return div
end

function ItemExt:info(text, color)
	local div = self:lbl(text, {color = true, private = {background_color = self.full_bg_color}, highlight_color = self.full_bg_color, min_height = 24, text_offset = {4, 4, 32, 4}, border_lock_height = false})
	div:tb_imgbtn("Info", nil, nil, BLE.Utils.EditorIcons.help, {divider_type = true, img_scale = 0.8, w = 24, h = 24})
	return div
end

local function check_slot(slot, unit)
	return BLE.Utils:InSlot(unit, slot) and not unit:match("husk")
end

function ItemExt:fs_pathbox(name, callback, value, typ, o)
	o = o or {}
	o.browse_func = function(tb)
		BLE.FBD:Show({
			where = BLE.MapProject:current_path() or string.gsub(Application:base_path(), "\\", "/"),
			extensions = type(typ) == "table" and typ or {typ},
			file_click = function(path)
				if o.process_path then
					tb:SetValue(o.process_path(path), true)
				else
					tb:SetValue(path, true)
				end
				if not o.not_close then
					BLE.FBD:Hide()
				end
			end
		})
	end
	return self:pathbox(name, callback, value, nil, o)
end

function ItemExt:pathbox(name, callback, value, typ, o)
	o = o or {}
	local tb = self:textbox(name, callback, value, table.merge({
		text = string.pretty2(name),
		textbox_font_size = self.size * 0.75,
		control_slice = 0.65,
		textbox_offset = 36
	}, o))
	tb:tb_imgbtn("Browse", function()
		if o.browse_func then
			o.browse_func(tb)
			return
		end

		local list = tb.custom_list or BLE.Utils:GetEntries({
			type = typ, loaded = o.loaded or false, filenames = false, check = o.check or (o.slot and SimpleClbk(check_slot, o.slot))
		})
		if o.sort_func then
			o.sort_func(list)
		end
		BLE.ListDialog:Show({
			list = list,
			sort = o.sort_func == nil,
			callback = function(path)
				local assets = managers.editor.parts.assets
				if not assets:is_asset_loaded(typ, path) then
					assets:quick_load_from_db(typ, path, nil, o.exclude, o.extra_info and clone(o.extra_info))
				end
				tb:SetValue(path, true)
				if not o.not_close then
					BLE.ListDialog:Hide()
				end
			end
		})
	end, nil, BLE.Utils.EditorIcons.dots, {
		help = "Browse " .. tostring(typ).."s",
		size = self.size * 1.75,
		position = function(item)
			item:SetPositionByString("RightCentery")
			item:Move(-6)
		end
	})
	return tb
end

function ItemExt:CopyAxis(item)
	local menu = item.parent.parent
	local value = menu:Value()
	if type_name(value) == "table" and value._shape then
		value = string.format("{_shape = true, width = %d, height = %d, depth = %d, radius = %d}", value.width, value.height, value.depth, value.radius)
	end
	Application:set_clipboard(tostring(value))
	managers.editor:status_message(menu:Name() .. " copied to clipboard")
end

function ItemExt:PasteAxis(item)
	local menu = item.parent.parent
	local paste = Application:get_clipboard()
	local result
	pcall(function()
		result = loadstring("return " .. paste)()
	end)
	if result and type_name(result) == menu.value_type or (menu.value_type == "Shape" and result._shape) then
		menu:SetValue(result, true)
		managers.editor:status_message(menu:Name() .. " pasted from clipboard")
	else
		managers.editor:status_message("Incorrect paste data")
	end
end

function ItemExt:RandomizeYaw(item)
	local menu = item.parent.parent
	local value = menu:Value()
	local random_rot = math.round(math.random(0, 360))
	local rot = Rotation(random_rot, value:pitch(), value:roll())
	menu:SetValue(rot, true)
end

function ItemExt:OffsetGrid(item)
	local menu = item.parent.parent
	local value = menu:Value()
	local offset = managers.editor._grid_size / 2
	local new_x = value.x + offset
	local new_y = value.y + offset
	
	local vect = mvector3.copy(value)
	mvector3.set_static(vect, new_x, new_y, value.z)
	menu:SetValue(vect, true)
end

function ItemExt:Reset(item)
	local menu = item.parent.parent
	local value = menu:Value()
	if type_name(value) == "Vector3" then
		local vect = mvector3.copy(value)
		mvector3.set_static(vect, 0, 0, 0)
		menu:SetValue(vect, true)
	elseif type_name(value) == "Rotation" then
		local rot = Rotation(0, 0, 0)
		menu:SetValue(rot, true)
	elseif type_name(value) == "table" and menu.value_type == "Shape" and value._shape then
		managers.editor:status_message("Not available for shapes")
	end	
end

function ItemExt:RoundAxis(item)
	local menu = item.parent.parent
	local value = menu:Value()
	if type_name(value) == "Vector3" then
		local vect = mvector3.copy(value)
		mvector3.set_static(vect, math.round(vect.x), math.round(vect.y), math.round(vect.z))
		menu:SetValue(vect, true)
	elseif type_name(value) == "Rotation" then
		local rot = Rotation(math.round(value:yaw()), math.round(value:pitch()), math.round(value:roll()))
		menu:SetValue(rot, true)
	elseif type_name(value) == "table" and menu.value_type == "Shape" and value._shape then
		local shape = {width = math.round(value.width), height = math.round(value.height), depth = math.round(value.depth), radius = math.round(value.radius)}
		menu:SetValue(shape, true)
	end
end

function ItemExt:Vec3Rot(name, clbk, pos, rot, o)
	o = o or {}
	if o.use_gridsnap_step then
		o.step = managers.editor._grid_size
	end
	local a = self:Vector3(name.."Position", clbk, pos, o)
	if o.use_gridsnap_step then
		o.step = nil -- managers.editor._snap_rotation
	end
	local b = self:Rotation(name.."Rotation", clbk, rot, o)
	return a,b
end

function ItemExt:Vector3(name, clbk, value, o)
	local p = self:simple_divgroup(name, table.merge({full_bg_color = false, on_callback = clbk, value_type = "Vector3", align_method = "centered_grid"}, o))
	o = {}
	value = value or Vector3()
	local vector2 = p.vector2
	local TB = p:GetToolbar()
	local icons = BLE.Utils.EditorIcons
	TB:tb_imgbtn("p", ClassClbk(self, "PasteAxis"), nil, icons.paste, {help = "Paste"})
	TB:tb_imgbtn("c", ClassClbk(self, "CopyAxis"), nil, icons.copy, {help = "Copy"})
	TB:tb_imgbtn("r", ClassClbk(self, "RoundAxis"), nil, icons.round_number, {help = "Round X,Y,Z Values"})
	TB:tb_imgbtn("r", ClassClbk(self, "OffsetGrid"), nil, icons.repos_brush, {help = "half off-grid"})
	-- TB:tb_imgbtn("r", ClassClbk(self, "Reset"), nil, icons.cross, {help = "Reset To 0"})
	local controls = {"x", "y", "z"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control:upper(), function()
			p:RunCallback()
		end, value and value[control] or 0, {w = (p:ItemsWidth() / (vector2 and 2 or 3)) - p:OffsetX(), control_slice = 0.8, step = p.step})
	end

	if vector2 then
		items[3]:SetVisible(false)
	end

	function p:Value()
		return Vector3(items[1]:Value(), items[2]:Value(), items[3]:Value())
	end
	p.get_value = p.Value

	function p:SetValue(val, run_callback)
		items[1]:SetValue(val.x)
		items[2]:SetValue(val.y)
		items[3]:SetValue(val.z)
		if run_callback then
			self:RunCallback()
		end
	end

	function p:SetVector2()
		items[3]:SetVisible(false)
	end

	function p:SetStep(step)
		items[1].step = step
		items[2].step = step
		items[3].step = step
	end

	return p
end

function ItemExt:Rotation(name, clbk, value, o)
	local p = self:simple_divgroup(name, table.merge({full_bg_color = false, on_callback = clbk, value_type = "Rotation", align_method = "centered_grid"}, o))
	o = {}
	value = value or Rotation()
	local TB = p:GetToolbar()
	local icons = BLE.Utils.EditorIcons
	TB:tb_imgbtn("p", ClassClbk(self, "PasteAxis"), nil, icons.paste, {help = "Paste"})
	TB:tb_imgbtn("c", ClassClbk(self, "CopyAxis"), nil, icons.copy, {help = "Copy"})
	TB:tb_imgbtn("r", ClassClbk(self, "RoundAxis"), nil, icons.round_number, {help = "Round Y,P,R Values"})
	TB:tb_imgbtn("r", ClassClbk(self, "Reset"), nil, icons.cross, {help = "Reset To 0"})
	TB:tb_imgbtn("r", ClassClbk(self, "RandomizeYaw"), nil, icons.reload, {help = "Randomize Yaw"})

	local controls = {"yaw", "pitch", "roll"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control:sub(1, 1):upper(), function()
			p:RunCallback()
		end, value and value[control](value) or 0, {w = p:ItemsWidth() / 3 - p:OffsetX(), control_slice = 0.8})
	end

	function p:Value()
		return Rotation(items[1]:Value(), items[2]:Value(), items[3]:Value())
	end
	p.get_value = p.Value

	function p:SetValue(val, run_callback)
		items[1]:SetValue(val:yaw())
		items[2]:SetValue(val:pitch())
		items[3]:SetValue(val:roll())
		if run_callback then
			self:RunCallback()
		end
	end

	function p:SetStep(step)
		items[1].step = step
		items[2].step = step
		items[3].step = step
	end

	return p
end

function ItemExt:Shape(name, clbk, value, o)
	local p = self:simple_divgroup(name, table.merge({full_bg_color = false, on_callback = clbk, value_type = "Shape", align_method = "centered_grid", color = false}, o))
	o = {}
	value = value or Rotation()
	local TB = p:GetToolbar()
	local icons = BLE.Utils.EditorIcons
	TB:tb_imgbtn("p", ClassClbk(self, "PasteAxis"), nil, icons.paste, {help = "Paste"})
	TB:tb_imgbtn("c", ClassClbk(self, "CopyAxis"), nil, icons.copy, {help = "Copy"})
	TB:tb_imgbtn("r", ClassClbk(self, "RoundAxis"), nil, icons.round_number, {help = "Round W,H,D Values"})
	local controls = {"width", "height", "depth", "radius"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control:sub(1,1):upper(), function()
			p:RunCallback()
		end, value and value[control] or 0, {w = p:ItemsWidth() / 3 - p:OffsetX(), control_slice = 0.8, visible = not p.no_radius or control ~= "radius"})
	end

	function p:Value()
		return {_shape = true, width = items[1]:Value(), height = items[2]:Value(), depth = items[3]:Value(), radius = items[4]:Value()}
	end
	p.get_value = p.Value

	function p:SetStep(step)
		items[1].step = step
		items[2].step = step
		items[3].step = step
		items[4].step = step
	end

	function p:SetValue(val, run_callback)
		items[1]:SetValue(val.width)
		items[2]:SetValue(val.height)
		items[3]:SetValue(val.depth)
		items[4]:SetValue(val.radius)
		if run_callback then
			self:RunCallback()
		end
	end

	return p
end


ItemExt.GetItem = Item.GetItem
ItemExt.AlignItems = Item.AlignItems
ItemExt.GetItemValue = Item.GetItemValue
ItemExt.SetItemValue = Item.SetItemValue
ItemExt.RemoveItem = Item.RemoveItem

--- @deprecated
--- This shouldn't be really used anymore, this is extremely bad practice and causes a lot of issues for the lua server.
function ItemExt:add_funcs(clss, menu)
	menu = menu or clss._menu
	for n, func in pairs(ItemExt) do
		if not n:find("set_") and not n:find("get_") then
			clss[n] = function(self, ...)
				return menu[n](menu, ...)
			end
		end
	end
end

for n, item in pairs(C) do
	if n ~= "ContextMenu" then
		for n, func in pairs(ItemExt) do
			item[n] = func
		end
	end
end

local Toggle = C.Toggle
Toggle.set_value = Toggle.SetValue