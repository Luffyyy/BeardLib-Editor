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

function ItemExt:ImgButton(name, callback, texture, rect, o)
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

function ItemExt:SButton(name, callback, o)    
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

function ItemExt:SqButton(name, callback, o)    
	local s = (o and o.size) or self.items_size
	o = o or {}
	o.min_width = s
	o.min_height = s
	o.max_height = s
	o.max_width = s
	return self:SButton(name, callback, o)
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

function ItemExt:numberbox(...)
	return self:NumberBox(ItemExt:Pasta2(...))
end

function ItemExt:textbox(...)
	return self:TextBox(ItemExt:Pasta2(...))
end

function ItemExt:slider(...)
	return self:Slider(ItemExt:Pasta2(...))
end

function ItemExt:pan(name, o)
	return self:Menu(table.merge({name = name, auto_height = true}, o))
end

function ItemExt:lbl(name, o)
	return self:Divider(table.merge({name = name, text = string.pretty2(name)}, o))
end

function ItemExt:divider(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:Divider(table.merge({name = name, text = string.pretty2(name), color = color, offset = {8, 4}}, o))
end

function ItemExt:separator(o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:Divider(table.merge({
		name = "div", text = "", h = 2, size_by_text = false, border_bottom = true, border_color = self.foreground:with_alpha(0.5)
	}, o))
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
	return self:PopupMenu(table.merge({size_by_text = true, name = name, text = string.pretty2(name)}, o))
end

function ItemExt:toolbar(name, o)
	name = name or "ToolBar"
	return self:ToolBar(table.merge({name = name, inherit_values = {offset = 0}}, o))
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
		value = value or Color.white
	}, o))
	if o and o.ret_vec then
		function item:Value()
			local v = BeardLib.Items.ColorTextBox.Value(self)
			return Vector3(v.r, v.g, v.b)
		end
	end
	return item
end


local function check_slot(slot, unit)
	return BeardLibEditor.Utils:InSlot(unit, slot) and not unit:match("husk")
end

function ItemExt:pathbox(name, callback, value, typ, o)
	local p = self:pan(name, table.merge({align_method = "grid"}, o))
	o = {}
	o.control_slice = 0.7
	o.on_callback = callback
	o.text = string.pretty2(name)
	local t = p:textbox("path", nil, value, o)
	o.text = "Browse " .. tostring(typ).."s"
	o.offset = {t.offset[1] * 4, t.offset[2]}
	o.on_callback = nil
	o.on_callback = p.btn_callback
	local btn = p:button("select_button", function()
		local list = BeardLibEditor.Utils:GetEntries({
			type = typ, loaded = NotNil(o.loaded, typ ~= "texture"), filenames = false, check = o.check or (o.slot and SimpleClbk(check_slot, o.slot))
		})
		if o.sort_func then
			o.sort_func(list)
		end
		   BeardLibEditor.ListDialog:Show({
			list = list,
			sort = o.sort_func == nil,
			callback = function(path) 
				t:SetValue(path, true)
				if not o.not_close then
					BeardLibEditor.ListDialog:Hide()
				end
			end
		})
	end, o)
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
	if type_name(result) == "Vector3" and menu.value_type == "Position" then
		menu:SetValue(result, true)
	end
	if type_name(result) == "Rotation" and menu.value_type == "Rotation" then
		
	end
end

function ItemExt:Vector3(name, clbk, value, o)
	local p = self:divgroup(name, table.merge({on_callback = clbk, value_type = "Position", align_method = "centered_grid", color = false}, o))
	o = {}
	value = value or Vector3()
	local vector2 = p.vector2
	local TB = p:GetToolbar()
	TB:SqButton("p", ClassClbk(self, "PasteAxis"), {offset = 0})
	TB:SqButton("c", ClassClbk(self, "CopyAxis"), {offset = 0})
	local controls = {"x", "y", "z"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:numberbox(control, function()
			p:RunCallback()
		end, value[control], {w = (p:ItemsWidth() / (vector2 and 2 or 3)) - p:OffsetX(), control_slice = 0.6})
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
	
	return p
end

function ItemExt:GetItem(name)
	return self:GetItem(name)
end

function ItemExt:add_funcs(clss, menu)
	menu = menu or clss._menu
	for n, func in pairs(ItemExt) do
		clss[n] = function(self, ...)
			return menu[n](menu, ...)
		end
	end
end

for n, item in pairs(C) do
	if n ~= "ContextMenu" then
		for n, func in pairs(ItemExt) do
			item[n] = item[n] or func
		end
	end
end