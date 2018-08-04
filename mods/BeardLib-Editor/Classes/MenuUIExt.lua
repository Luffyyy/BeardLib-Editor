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