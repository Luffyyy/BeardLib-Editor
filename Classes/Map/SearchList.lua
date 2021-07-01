SearchList = SearchList or class(EditorPart)

function SearchList:init(parent)
    self._menu = parent._holder:pan("Tab", {visible = false, auto_height = false, stretch_to_bottom = true, scrollbar = false})

    self._options = self._menu:group("Options")
    self._options:textbox("Search", ClassClbk(self, "do_search"), nil, {control_slice = 0.75})

    self._parent = parent
    self._pages = self._menu:holder("Pages", {align_method = "centered_grid", h = 32, size = self._menu.size * 0.9, inherit_values = {offset = 2}, visible = not self.HIDE_PAGINATION})

    self._page = 1

    self._list = self._menu:pan("Units", {inherit_values = {size = self._menu.size * 0.8}, auto_align = false, auto_height = false, stretch_to_bottom = true})
    self:do_search()
end

function SearchList:set_visible(vis)
    self._menu:SetVisible(vis)
end

function SearchList:on_click_item(name)
end

function SearchList:do_search(no_reset_page)
    local item = self._options:GetItem("Search")
    BeardLib:AddDelayedCall("BLEDoSearchList"..tostring(self), self._filtered == nil and 0 or 0.2, function()
        self._search = item:Value()
        self._filtered = {}
        self:do_search_list()
        if not no_reset_page then
            self._page = 1
        end
        self:do_show()
    end)
end

function SearchList:insert_item_to_filtered_list(item)
    table.insert(self._filtered, item)
end

function SearchList:do_search_list()
end

function SearchList:on_click_item()
end

function SearchList:do_show()
    self._pages:ClearItems()

    local perapge = 200
    local pages = math.ceil(table.size(self._filtered) / perapge)
    local page = self._page
    local pagination = BeardLib.Utils:MakePagination(page, pages, 2)

    local h = self._pages:ItemsHeight(1)
    local icons = BLE.Utils.EditorIcons

    local popt = {w = h, h = h, offset = 2, img_offset = 6}

    local back = self._pages:tb_imgbtn("Backwards", ClassClbk(self, "set_page", self._page-1), nil, icons.arrow_left, popt)
    back:SetEnabled(self._page ~= 1)

    for i, page_num in pairs(pagination) do
        if page_num == 1 or page_num == pages then
            local next_or_prev = pagination[i - 1] or pagination[i + 1]
            if next_or_prev and math.abs(next_or_prev-page_num) > 1 then
                self._pages:lbl("...", {index = page_num == 1 and 3 or nil, w = 28, h = h, text_align = "center"})
            end
        end
        self._pages:button(page_num, ClassClbk(self, "set_page", page_num), {border_bottom = page_num == page, h = h, w = 32, text_align = "center"})
    end

    self._pages:tb_imgbtn("Forward", ClassClbk(self, "set_page", self._page+1), nil, icons.arrow_right, popt):SetEnabled(self._page ~= pages and pages > 1)

    self._list:ClearItems()

    for i, v in pairs(self._filtered) do
        if i > perapge * (page-1) and i < perapge * (page + 1) then -- Is it in the page's range?
            self:create_list_item(v)
        end
    end

    self._list:AlignItems()
end

function SearchList:create_list_item(item)
    self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {border_left = true, offset = {1, 4}})
end

function SearchList:friendly_item_name(item)
    return type(item) == "table" and item.name or item
end

function SearchList:item_id(item)
    return type(item) == "table" and item.id or item
end

function SearchList:check_search(check)
    return not self._search or self._search:len() == 0 or check:lower():match(self._search:lower())
end

function SearchList:set_page(page)
    self._page = page
    self:do_show()
end