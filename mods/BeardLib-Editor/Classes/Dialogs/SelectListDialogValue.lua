SelectListDialogValue = SelectListDialogValue or class(SelectListDialog)
SelectListDialogValue.type_name = "SelectListDialogValue"

function SelectListDialogValue:init(params, menu)
    if self.type_name == SelectListDialogValue.type_name then
        params = params and clone(params) or {}
    end
    self.super.init(self, table.merge(params, {align_method = "grid"}), menu)
end

function SelectListDialogValue:ItemsCount()
    return #self._list_items_menu:Items()
end

function SelectListDialogValue:ShowItem(t, selected)
    if not selected and (self._single_select or not self._allow_multi_insert) and self._list_menu:GetItem(t) then
        return false
    end

    if self:SearchCheck(t) then
        if not self._limit or self:ItemsCount() <= 250 then
            return true
        end
    end
    return false    
end

function SelectListDialogValue:MakeListItems(params)
    MenuUtils:new(self, self._list_menu)
    self._list_menu:ClearItems()
    self._tbl.values_name = self._tbl.values_name or params and params.values_name
    self._tbl.combo_items_func = self._tbl.combo_items_func or params and params.combo_items_func
    self._tbl.values_list_width = self._tbl.values_list_width or params and params.values_list_width or 200
    self._list_items_menu = self:DivGroup("Select or Deselect", {w = self._list_menu:ItemsWidth() - (self._tbl.values_name and self._tbl.values_list_width or 0), offset = 0, auto_align = false})
    if self._tbl.values_name then
    	self._values_list_menu = self:DivGroup(self._tbl.values_name, {w = self._tbl.values_list_width, offset = 0, auto_align = false})
    end
    self.super.MakeListItems(self, params)
end

function SelectListDialogValue:ValueClbk(value, menu, item)
    local selected = item.SelectedItem and item:SelectedItem()
    value.value = selected and type(selected) == "table" and selected.value or selected or item:Value()
end

function SelectListDialogValue:ToggleClbk(...)
    SelectListDialogValue.super.ToggleClbk(self, ...)
    if self._allow_multi_insert and not self._single_select then
        self:MakeListItems()
    end
end

function SelectListDialogValue:ToggleItem(name, selected, value)
    local opt = {group = self._list_items_menu, offset = 4}
    local item
    if self._single_select then
        item = self:Toggle(name, callback(self, self, "ToggleClbk", value), selected, opt)
    else
        if selected then
            opt.value = false
            opt.foreground = Color.green
            opt.foreground_highlight = false            
            opt.auto_foreground = false
            opt.can_be_ticked = false
            item = self:Button("- "..name, callback(self, self, "ToggleClbk", value), opt)
        else
            opt.value = true
            opt.foreground_highlight = false
            opt.auto_foreground = false
            opt.can_be_unticked = false
            item = self:Button("+ "..name, callback(self, self, "ToggleClbk", value), opt)
        end                
    end

    opt = {control_slice = 1, group = self._values_list_menu, offset = 4, color = false}
    local v = selected and value.value or nil
    if self._tbl.values_name then
	    if tonumber(v) then
	        self:NumberBox("", callback(self, self, "ValueClbk", value), v, opt)
        elseif type(v) == "boolean" then
            self:Toggle("", callback(self, self, "ValueClbk", value), v, opt)
	    elseif v then
            if self._tbl.combo_items_func then
                local items = self._tbl.combo_items_func(name, value)
                self:ComboBox("", callback(self, self, "ValueClbk", value), items, table.get_key(items, v), opt)
            else
	           self:TextBox("", callback(self, self, "ValueClbk", value), v, opt)
            end
	    else
	        self:Divider("...", opt)
	    end
    end
    table.insert(self._visible_items, item)
end