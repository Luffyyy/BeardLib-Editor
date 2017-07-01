SelectListDialogValue = SelectListDialogValue or class(SelectListDialog)
function SelectListDialogValue:init(params, menu)
	params = deep_clone(params)
    self.super.init(self, table.merge(params, {align_method = "grid"}), menu)
end

function SelectListDialogValue:ItemsCount()
    return #self._list_items_menu._all_items
end

function SelectListDialogValue:MakeListItems(params)
    MenuUtils:new(self, self._list_menu)
    self._list_menu:ClearItems()
    self._tbl.values_name = self._tbl.values_name or params and params.values_name
    self._tbl.combo_items_func = self._tbl.combo_items_func or params and params.combo_items_func
    self._list_items_menu = self:DivGroup("Select or Deselect", {w = self._list_menu:ItemsWidth() - (self._tbl.values_name and 200 or 0), offset = 0, auto_align = false})
    if self._tbl.values_name then
    	self._values_list_menu = self:DivGroup(self._tbl.values_name, {w = 200, offset = 0, auto_align = false})
    end
    self.super.MakeListItems(self, params)
end

function SelectListDialogValue:ValueClbk(value, menu, item)
    local selected = item.SelectedItem and item:SelectedItem()
    value.value = selected and type(selected) == "table" and selected.value or selected or item:Value()
end

function SelectListDialogValue:ToggleItem(name, selected, value)
    self:Toggle(name, callback(self, self, "ToggleClbk", value), selected, {group = self._list_items_menu, offset = 4})
    local opt = {control_slice = 1, group = self._values_list_menu, offset = 4, color = false}
    if self._tbl.values_name then
	    if tonumber(value.value) then
	        self:NumberBox("", callback(self, self, "ValueClbk", value), value.value, opt)
	    elseif value.value then
            if self._tbl.combo_items_func then
                local items = self._tbl.combo_items_func(name, value)
                self:ComboBox("", callback(self, self, "ValueClbk", value), items, table.get_key(items, value.value), opt)
            else
	           self:TextBox("", callback(self, self, "ValueClbk", value), value.value, opt)
            end
	    else
	        self:Divider("None", opt)
	    end
	end
end