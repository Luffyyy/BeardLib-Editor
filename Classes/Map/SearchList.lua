SearchList = SearchList or class(EditorPart)

function SearchList:init(parent)
    self._menu = parent._holder:pan("Tab", {visible = false, auto_height = false, stretch_to_bottom = true, scrollbar = false})

    self._options = self._menu:group("Options")
    local search = self._options:textbox("Search", ClassClbk(self, "do_search", false, false), nil, {textbox_offset = 22, control_slice = 0.75})
    local h = self._options:ItemsHeight(1)
    search:tb_imgbtn("ClearSearch", ClassClbk(self, "clear_search"), nil, BLE.Utils.EditorIcons.cross, {w = h, h = h, offset = 0, img_scale = 0.5, position = "RightCentery"})

    self._parent = parent
    self._pages_panel = self._menu:holder("Pages", {align_method = "centered_grid", auto_align = false, h = 32, size = self._menu.size * 0.9, inherit_values = {offset = 2}, visible = not self.HIDE_PAGINATION})

    self._page = 1
    self._pages = 1

    self._list = self._menu:pan("Units", {inherit_values = {size = self._menu.size * 0.8}, auto_align = false, auto_height = false, stretch_to_bottom = true})
    self:do_search()
end

function SearchList:set_visible(vis)
    self._menu:SetVisible(vis)
end

function SearchList:clear_search(item)
    self._options:GetItem("Search"):SetValue("")
    self:do_search(false, false)
end

function SearchList:on_click_item(name)
end

function SearchList:do_search(no_reset_page, no_clear, t)
    local item = self._options:GetItem("Search")
    BeardLib:AddDelayedCall("BLEDoSearchList"..tostring(self), self._filtered == nil and 0 or 0.2, function()
        if not alive(self._list) then -- CAN happen when the code reloads
            return
        end
        local search = item:Value():lower():split(",")
        self._search = {}
        for _, s in pairs(search) do
            s = s:escape_special()
            table.insert(self._search, s)
        end
        self._filtered = {}
        self:do_search_list()
        if not no_reset_page then
            self._page = 1
        end
        self:sort_items()
        self:do_show(no_clear)
    end)
end

function SearchList:sort_items()
    table.sort(self._filtered, function(a,b)
        return a.name < b.name
    end)
end

function SearchList:insert_item_to_filtered_list(item)
    table.insert(self._filtered, item)
end

function SearchList:do_search_list()
end

function SearchList:on_click_item()
end

function SearchList:reload()
    self:do_search()
end

function SearchList:do_show(no_clear)
    self._pages_panel:ClearItems()

    local perapge = self.PER_PAGE
    local pages = math.ceil(table.size(self._filtered) / perapge)
    local page = self._page
    local pagination = BeardLib.Utils:MakePagination(page, pages, self._parent._holder:W() < 350 and 1 or 2)

    local h = self._pages_panel:ItemsHeight(1)
    local icons = BLE.Utils.EditorIcons

    local popt = {w = h, h = h, offset = 2, img_offset = 6}

    local back = self._pages_panel:tb_imgbtn("Backwards", ClassClbk(self, "set_page", self._page-1), nil, icons.arrow_left, popt)
    back:SetEnabled(self._page ~= 1)

    for i, page_num in pairs(pagination) do
        if page_num == 1 or page_num == pages then
            local next_or_prev = pagination[i - 1] or pagination[i + 1]
            if next_or_prev and math.abs(next_or_prev-page_num) > 1 then
                self._pages_panel:lbl("...", {index = page_num == 1 and 3 or nil, w = 28, h = h, text_align = "center"})
            end
        end
        self._pages_panel:button(page_num, ClassClbk(self, "set_page", page_num), {border_bottom = page_num == page, h = h, w = 32, text_align = "center"})
    end

    self._pages_panel:tb_imgbtn("Forward", ClassClbk(self, "set_page", self._page+1), nil, icons.arrow_right, popt):SetEnabled(self._page ~= pages and pages > 1)

    if not no_clear then
        self._list:ClearItems()
    end

    local range_1, range_2 = self:get_page_ranges()
    for i, v in pairs(self._filtered) do
        if i > range_1 and i <= range_2 then -- Is it in the page's range?
            if not alive(v.gui_item) then
                v.gui_item = self:create_list_item(v)
            end
        elseif i > range_2 then
            break
        end
    end

    self._menu:AlignItems(true)
end

function SearchList:get_page_ranges()
    return self.PER_PAGE * (self._page-1), self.PER_PAGE * self._page
end

function SearchList:create_list_item(item)
    return self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {
        border_left = true,
        border_color = self:get_border_color(item),
        offset = {1, 4},
    })
end

function SearchList:get_border_color(item)
    return nil
end

function SearchList:friendly_item_name(item)
    return item.name
end

function SearchList:item_object(item)
    return item.object
end

function SearchList:check_search(check)
    check = check:lower()
    if not self._search or #self._search == 0 then
        return true
    else
        for _, search in pairs(self._search) do
            if check:match(search) then
                return true
            end
        end
    end
    return false
end

function SearchList:set_page(page)
    self._page = page
    self:do_show()
end