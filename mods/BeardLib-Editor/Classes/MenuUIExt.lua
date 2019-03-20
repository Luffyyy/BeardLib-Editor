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

local ItemExt = {}

function Item:ImgButton(name, callback, texture, rect, o)
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

function Item:SButton(name, callback, o)    
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

function Item:SqButton(name, callback, o)    
	local s = (o and o.size) or self.items_size
	o.min_width = s
	o.min_height = s
	o.max_height = s
	o.max_width = s
	return self:SButton(name, callback, o)
end

for _, item in pairs(C) do
	for n, func in pairs(ItemExt) do
		item[n] = func
	end
end