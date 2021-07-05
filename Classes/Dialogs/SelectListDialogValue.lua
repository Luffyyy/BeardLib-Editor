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
        if not self._limit or self:ItemsCount() <= self._max_items then
            return true
        end
    end
    return false    
end

function SelectListDialogValue:MakeListItems(params)
    ItemExt:add_funcs(self, self._list_menu)
    self._list_menu:ClearItems()
    self._tbl.entry_values = self._tbl.entry_values or params and params.entry_values
    self._tbl.combo_items_func = self._tbl.combo_items_func or params and params.combo_items_func
    self._tbl.values_list_width = self._tbl.values_list_width or params and params.values_list_width or 200
    self._list_items_menu = self:divgroup("Select or Deselect", {offset = 0, auto_align = false, border_left = false, border_bottom = true})
    local tb = self._list_items_menu:GetToolbar()
    if not self._single_select then
        tb:divider("Order", {w = self._tbl.values_list_width / 3, border_left = false, border_bottom = true})
    end
    if self._tbl.entry_values then
        for _, value in pairs(self._tbl.entry_values) do
            tb:divider(value.name, {w = self._tbl.values_list_width, border_left = false, border_bottom = true})
        end
    end
    self.super.MakeListItems(self, params)
end

function SelectListDialogValue:ValueClbk(i, item)
    local selected = item.SelectedItem and item:SelectedItem()
    item.parent.entry.values[i] = selected and type(selected) == "table" and selected.value or selected or item:Value()
end

function SelectListDialogValue:ChangeOrder(item)
    local entry = item.parent.entry
    if entry then
        local i = table.get_key(self._selected_list, entry)
        if i then
            table.remove(self._selected_list, i)
            table.insert(self._selected_list, i + (item.up and -1 or 1), entry)
        end
        local y = self._list_menu:ScrollY()
        self:MakeListItems()
        self._list_menu:SetScrollY(y)
        entry.moved = true
    end
end

function SelectListDialogValue:ToggleClbk(entry, item, no_refresh)
    if self._single_select then
        for _,v in pairs(self._list) do
            local toggle = self._list_menu:GetItem(type(v) == "table" and v.name or v)
            if toggle and toggle ~= item then
                toggle:SetValue(false)
            end
        end
    end
    if item:Value() == true then
        if not table.contains(self._selected_list, entry) or self._allow_multi_insert then
            if self._single_select then
                self._selected_list = {entry}
            else
                local new_entry = type(entry) == "table" and clone(entry) or entry
                if new_entry.values then
                    new_entry.values = clone(entry.values)
                end
                table.insert(self._selected_list, new_entry)
            end
        end
    else
        if self._single_select then
            self._selected_list = {}
        else
            table.delete(self._selected_list, entry)
        end
    end
    if not no_refresh and not self._single_select then
        self:MakeListItems()
    end
end

function SelectListDialogValue:ToggleItem(name, selected, entry)
    local opt = {align_method = "grid_from_right", entry = entry}
    local item
    if self._single_select then
        item = self._list_items_menu:tickbox(name, ClassClbk(self, "ToggleClbk", entry), selected, opt)
    else
        if selected then
            opt.value = false
            opt.foreground = Color.green
            opt.foreground_highlight = false            
            opt.auto_foreground = false
            opt.can_be_ticked = false
            item = self._list_items_menu:button("- "..name, ClassClbk(self, "ToggleClbk", entry), opt)
        else
            opt.value = true
            opt.foreground_highlight = false
            opt.auto_foreground = false
            opt.can_be_unticked = false
            item = self._list_items_menu:button("+ "..name, ClassClbk(self, "ToggleClbk", entry), opt)
        end
    end

    if not self._single_select then
        local updown = item:Divider({offset = 0, w =self._tbl.values_list_width/3, enabled = selected, align_method = "centered_grid", entry = entry})
        local max = #self._selected_list
        local entry_i = table.get_key(self._selected_list, entry)
        updown:tb_imgbtn("Up", ClassClbk(self, "ChangeOrder"), "guis/textures/menu_ui_icons", {32, 0, 32, 32}, {up = true, enabled = entry_i and entry_i > 1, size = item.size*1.2})
        updown:tb_imgbtn("Down", ClassClbk(self, "ChangeOrder"), "guis/textures/menu_ui_icons", {0, 0, 32, 32}, {enabled = entry_i and entry_i < max, size = item.size*1.2})
    end

    opt = {control_slice = 1, color = false, free_typing = self._params.combo_free_typing, w = self._tbl.values_list_width-16}
    local values = entry.values
    if self._tbl.entry_values then
        for i, value in pairs(self._tbl.entry_values) do
            local v = values and values[i]
            if tonumber(v) then
                item:numberbox("", ClassClbk(self, "ValueClbk", i), v, opt)
            elseif type(v) == "boolean" then
                item:tickbox("", ClassClbk(self, "ValueClbk", i), v, opt)
            elseif v then
                local items = self._tbl.combo_items_func and self._tbl.combo_items_func(name, entry, i)
                if items then
                    item:combobox("", ClassClbk(self, "ValueClbk", i), items, table.get_key(items, v) or v, opt)
                else
                    item:textbox("", ClassClbk(self, "ValueClbk", i), v, opt)
                end
            end
        end
    end
    table.insert(self._visible_items, item)
end