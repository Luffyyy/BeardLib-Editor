MultiSelectListDialog = MultiSelectListDialog or class(ListDialog)
function MultiSelectListDialog:_Show(params)
    self._select_multi_clbk = params.select_multi_clbk
    self._multi_select = false
    self._selected_list = {}
    MultiSelectListDialog.super._Show(self, params)
end

function MultiSelectListDialog:CreateShortcuts(params)
    local offset, bw = MultiSelectListDialog.super.CreateShortcuts(self, params)

    self._menu:Button({
        name = "SelectPresent",
        text = "[+*]",
        w = bw,
        visible = self._multi_select,
        text_align = "center",
        on_callback = ClassClbk(self, "SelectPresent"),
        help = "Select all present items",
    })
    self._unselect_btn = self._menu:Button({
        name = "UnselectPresent",
        text = "[-*]",
        w = bw,
        visible = self._multi_select,
        text_align = "center",
        on_callback = ClassClbk(self, "UnselectPresent"),
        help = "Unselect all present items",
    })

    self._menu:Toggle({
        name = "SelectSpecific",
        text = "[?]",
        w = bw,
        visible = self._params.select_multi_clbk ~= nil,
        value = self._multi_select,
        offset = offset,
        on_callback = ClassClbk(self, "StartMultiSelect"),
        help = "Toggle multi selection on/off",
    })

    self._confirm_btn = self._menu:ImageButton({
        name = "Confirm",
        w = bw,
        visible = self._multi_select,
        h = self._menu:H(),
        icon_w = 16,
        icon_h = 16,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {82, 50, 36, 36},
        on_callback = ClassClbk(self, "ConfirmSelection"),
        label = "temp"
    })

    return offset, bw
end

function MultiSelectListDialog:ConfirmSelection()
    if self._select_multi_clbk then
        self._select_multi_clbk(self._selected_list)
    end
    self:hide(false)
end

function MultiSelectListDialog:SelectPresent()
    if self._multi_select then
        local select = function(itm)
            local v = self._list[itm.list_i]
            if not table.contains(self._selected_list, v) then
                table.insert(self._selected_list, v)
            end
            itm:SetValue(true)
        end
        for _, item in pairs(self._list_menu:Items()) do
            if item.menu_type then
                for _, child_item in pairs(item:Items()) do
                    select(child_item)
                end
            else
                select(item)
            end
        end
    else
        local selected = {}
        for _, item in pairs(self._list_menu:Items()) do
            if item.menu_type then
                for _, child_item in pairs(item:Items()) do
                    table.insert(selected, self._list[child_item.list_i])
                end
            else
                table.insert(selected, self._list[item.list_i])
            end
        end
        if self._select_multi_clbk then
            self._select_multi_clbk(selected)
        end
    end
end

function MultiSelectListDialog:UnselectPresent()
    if self._multi_select then
        local unselect = function(itm)
            local v = self._list[itm.list_i]
            if table.contains(self._selected_list, v) then
                table.delete(self._selected_list, v)
            end
            itm:SetValue(false)
        end
        for _, item in pairs(self._list_menu:Items()) do
            if item.menu_type then
                for _, child_item in pairs(item:Items()) do
                    unselect(child_item)
                end
            else
                unselect(item)
            end
        end
    end
end

function MultiSelectListDialog:ToggleItem(item)
    local v = self._list[item.list_i]
    if item:Value() then
        if not table.contains(self._selected_list, v) then
            table.insert(self._selected_list, v)
        end
    else
        table.delete(self._selected_list, v)
    end
end

function MultiSelectListDialog:StartMultiSelect(item)
    self._multi_select = not self._multi_select
    self._selected_list = {}
    self._confirm_btn:SetEnabled(self._multi_select)
    self._unselect_btn:SetEnabled(self._multi_select)
    self:CreateTopMenu(self._params)
    self:MakeListItems()
end

function MultiSelectListDialog:MakeListItems(params)
    self._list_menu:ClearItems("list_items")
    params = params or self._params
    local case = self._case_sensitive
    local limit = self._limit
    local groups = {}
    local i = 0
    for indx, v in pairs(self._list) do
        local t = type(v) == "table" and v.name or v
        if limit and i > self._max_items then
            break
        end
        if (params.search_check and params.search_check(t, self._filter, v)) or self:SearchCheck(t) or (v.create_group and self:SearchCheck(v.create_group)) then
            i = i + 1 
            local menu = self._list_menu
            if type(v) == "table" and v.create_group then 
                menu = groups[v.create_group] or self._list_menu:Group({
                    auto_align = false,
                    name = v.create_group,
                    text = v.create_group,
                    label = "list_items"
                }) 
                groups[v.create_group] = menu
            end
            if self._multi_select then
                menu:Toggle(table.merge({
                    name = t,
                    text = t,
                    value = table.contains(self._selected_list, v),
                    on_callback = ClassClbk(self, "ToggleItem"),
                    list_i = indx,
                    label = "list_items"
                }, type(v) == "table" and v or nil))
            else
                menu:Button(table.merge({
                    name = t,
                    text = t,
                    list_i = indx,
                    on_callback = function(item)
                        if self._callback then
                            self._callback(v)
                        end
                    end, 
                    label = "list_items"
                }, type(v) == "table" and v or nil))
            end
        end
    end

    self:show_dialog()
    self._list_menu:AlignItems(true)
end
