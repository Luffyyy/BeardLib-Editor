--snake_case
--snek

local C = BeardLib.Items
local Item = C.Item
Item.get_value = Item.Value
Item.set_value = Item.SetValue
Item.set_enabled = Item.SetEnabled
Item.set_visible = Item.SetVisible

local Slider = C.Slider

function Slider:set_range(min, max)
	self.min = min
	self.max = max
end

local color
ItemExt = {}

function ItemExt:ImgButton(name, callback, texture, rect, o)
	local s = self:H()
	return self:ImageButton(table.merge({
		name = name,
		on_callback = callback,
		highlight_color = self.foreground:with_alpha(0.25),
		auto_foreground = false,
		w = s,
		h = s,
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
		highlight_color = self.foreground:with_alpha(0.25),
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

function ItemExt:divider(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:Divider(table.merge({name = name, text = string.pretty2(name), color = color, offset = {8, 4}}, o))
end

function ItemExt:group(name, o)
	return self:Group(table.merge({name = name, text = string.pretty2(name)}, o))
end


function ItemExt:divgroup(name, o)
	color = color or BLE.Options:GetValue("AccentColor")
	return self:DivGroup(table.merge({
		name = name,
		color = color,
		text = string.pretty2(name),
		auto_height = true,
		background_visible = false
	}))
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