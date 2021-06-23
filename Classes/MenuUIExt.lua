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

local color
ItemExt = {}
ItemExt.get_value = Item.Value
ItemExt.set_value = Item.SetValue
ItemExt.set_enabled = Item.SetEnabled
ItemExt.set_visible = Item.SetVisible
ItemExt.clear_items = Item.ClearItems

function ItemExt:getmenu()
	return self
end

function ItemExt:tb_imgbtn(name, callback, texture, rect, o)
	return self:ImageButton(table.merge({
		name = name,
		on_callback = callback,
		highlight_color = self:GetForeground():with_alpha(0.25),
		auto_foreground = false,
		size = self:H(),
		offset = 2,
		img_offset = 4,
		texture = texture or BLE.Utils.EditorIcons.texture,
		texture_rect = rect,
	}, o))
end

function ItemExt:tb_btn(name, callback, o)    
	return self:Button(table.merge({
		name = name,
		text = string.pretty2(name),
		on_callback = callback,
		size_by_text = true,
		offset = 2,
		highlight_color = self:GetForeground():with_alpha(0.25),
	--	auto_foreground = false,
		foreground_highlight = false,
		text_align = "center",
		text_vertical = "center",
	}, o))
end

function ItemExt:s_btn(name, callback, o)
	o = o or {}
	o.offset = self.offset
	return self:tb_btn(name, callback, o)
end

function ItemExt:sq_btn(name, callback, o)    
	local s = (o and o.size) or self.items_size
	o = o or {}
	o.min_width = s
	o.min_height = s
	o.max_height = s
	o.max_width = s
	return self:tb_btn(name, callback, o)
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
	return self:Menu(table.merge({name = name, auto_height = true}, o))
end

function ItemExt:lbl(name, o)
	return self:Divider(table.merge({name = name, text = name}, o))
end

function ItemExt:ulbl(name, o)
	return self:Divider(table.merge({name = name, border_bottom = true, text = name}, o))
end

function ItemExt:divider(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:Divider(table.merge({name = name, text = string.pretty2(name), color = color, offset = {8, 4}}, o))
end

function ItemExt:img(name, o)
	return self:Image(table.merge({name = name, text = name}, o))
end

function ItemExt:separator(o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:Divider(table.merge({
		name = "div", text = o and o.text or "", h = (not o or not o.text) and 2 or nil, size_by_text = false, border_bottom = true, border_color = self.foreground:with_alpha(0.1)
	}, o))
end

function ItemExt:s_group(name, o)
	o = o or {}
	o.inherit_values = o.inherit_values or {}
	o.inherit_values.offset = o.offset or self.inherit_values and self.inherit_values.offset or self.offset
	o.offset = {1, o.inherit_values.offset[2]}
	return self:group(name, o)
end

function ItemExt:group(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:Group(table.merge({color = color, name = name, text = string.pretty2(name)}, o))
end

function ItemExt:notebook(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:NoteBook(table.merge({color = color, name = name, text = string.pretty2(name)}, o))
end

function ItemExt:popup(name, o)
	return self:PopupMenu(table.merge({name = name, text = string.pretty2(name)}, o))
end

function ItemExt:toolbar(name, o)
	name = name or "ToolBar"
	return self:ToolBar(table.merge({name = name, inherit_values = {offset = 0}}, o))
end

function ItemExt:tholder(name, o, text_o)
	local holder = self:holder(name, o)
	holder:ulbl(name, text_o or o and o.text_o or nil)
	return holder
end

function ItemExt:holder(name, o)
	return self:Holder(table.merge({name = name, text = string.pretty2(name)}, o))
end

function ItemExt:divgroup(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:DivGroup(table.merge({
		name = name,
		color = color,
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
	local div = self:lbl(text, {color = true, private = {background_color = self.full_bg_color}, border_color = color or Color.yellow, border_lock_height = false})
	div:tb_imgbtn("Alert", nil, nil, {343, 132, 72, 72}, {divider_type = true, offset = 0, w = 24, h = 24})
	return div
end

function ItemExt:info(text, color)
	local div = self:lbl(text, {color = true, private = {background_color = self.full_bg_color}, border_lock_height = false})
	div:tb_imgbtn("Info", nil, nil, {252, 132, 72, 72}, {divider_type = true, offset = 0, w = 24, h = 24})
	return div
end

local function check_slot(slot, unit)
	return BeardLibEditor.Utils:InSlot(unit, slot) and not unit:match("husk")
end

function ItemExt:pathbox(name, callback, value, typ, o)
	o = o or {}
	local p = self:pan(name, table.merge({full_bg_color = false, align_method = "grid", text = o.text or string.pretty2(name)}, o))
	local o2 = {}
	o2.control_slice = p.control_slice or 0.7
	p.on_callback = callback
	o2.text = p.text
	local t = p:textbox("path", function()
		p:RunCallback()
	end, value, o)
	if p.disable_input then
		t.divider_type = true
	end
	o2.text = "Browse " .. tostring(typ).."s"
	o2.offset = {p.offset[1] * 4, p.offset[2]}
	o2.on_callback = nil
	o2.on_callback = p.btn_callback
	local btn = p:button("select_button", function()
		local list = p.custom_list or BeardLibEditor.Utils:GetEntries({
			type = typ, loaded = NotNil(o.loaded, typ ~= "texture"), filenames = false, check = o.check or (o.slot and SimpleClbk(check_slot, o.slot))
		})
		if o.sort_func then
			o.sort_func(list)
		end
		BeardLibEditor.ListDialog:Show({
			list = list,
			sort = o.sort_func == nil,
			callback = function(path) 
				p:SetValue(path, true)
				if not o.not_close then
					BeardLibEditor.ListDialog:Hide()
				end
			end
		})
	end, o2)
	function p:SetValue(val, run_callback)
		t:SetValue(val, false)
		if run_callback then
			self:RunCallback()
		end
	end
	function p:Value()
		return t:Value()
	end
	return p
end

function ItemExt:CopyAxis(item)
	local menu = item.parent.parent
	Application:set_clipboard(tostring(menu:Value()))
end

function ItemExt:PasteAxis(item)
	local menu = item.parent.parent
	local paste = Application:get_clipboard()
	local result
	pcall(function()
		result = loadstring("return " .. paste)()
	end)
	if result and type(result) == "table" and result._is_a_shape or type_name(result) == menu.value_type then
		menu:SetValue(result, true)
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
	local p = self:divgroup(name, table.merge({full_bg_color = false, on_callback = clbk, value_type = "Vector3", align_method = "centered_grid", color = false}, o))
	o = {}
	value = value or Vector3()
	local vector2 = p.vector2
	local TB = p:GetToolbar()
	TB:sq_btn("p", ClassClbk(self, "PasteAxis"), {offset = 0})
	TB:sq_btn("c", ClassClbk(self, "CopyAxis"), {offset = 0})
	local controls = {"x", "y", "z"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control, function()
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
	local p = self:divgroup(name, table.merge({full_bg_color = false, on_callback = clbk, value_type = "Rotation", align_method = "centered_grid", color = false}, o))
	o = {}
	value = value or Rotation()
	local TB = p:GetToolbar()
	TB:sq_btn("p", ClassClbk(self, "PasteAxis"), {offset = 0})
	TB:sq_btn("c", ClassClbk(self, "CopyAxis"), {offset = 0})
	local controls = {"yaw", "pitch", "roll"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control:sub(1, 1), function()
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
	local p = self:divgroup(name, table.merge({full_bg_color = false, on_callback = clbk, value_type = "Shape", align_method = "centered_grid", color = false}, o))
	o = {}
	value = value or Rotation()
	local TB = p:GetToolbar()
	TB:sq_btn("p", ClassClbk(self, "PasteAxis"), {offset = 0})
	TB:sq_btn("c", ClassClbk(self, "CopyAxis"), {offset = 0})
	local controls = {"width", "height", "depth", "radius"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control:sub(1,1), function()
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
ItemExt.ClearItems = Item.ClearItems
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