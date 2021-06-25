SearchList = SearchList or class(EditorPart)

function SearchList:init(parent)
    self._menu = parent._holder:pan("Tab", {visible = false, auto_height = false, offset = {0, 8}, h = parent._holder:ItemsHeight() - 16, scrollbar = false})
    self._options = self._menu:group("Options", {offset = {0, 8}})
    self._options:textbox("Search", ClassClbk(self, "do_search"), nil, {control_slice = 0.75})

    self._parent = parent
    self._pages = self._menu:pan("Pages", {align_method = "centered_grid"})

    self._page = 1

    self._list = self._menu:pan("Units", {inherit_values = {size = 14}, offset = {0, 8}, auto_align = false, auto_height = false, h = self._menu:ItemsHeight() - 120})
    self:do_search()
end

function SearchList:set_visible(vis)
    self._menu:SetVisible(vis)
end

function SearchList:on_click_item(name)
end

function SearchList:do_search(item)
    item = item or self._options:GetItem("Search")
    BeardLib:AddDelayedCall("BLEDoSearchList"..tostring(self), self._filtered == nil and 0 or 0.2, function()
        self._search = item:Value()
        self._filtered = {}
        self:do_search_list()
        self._page = 1
        self:do_show()
    end)
end

function SearchList:do_search_list()
    log('..')
end

function SearchList:on_click_item()
end

function SearchList:do_show()
    self._pages:ClearItems()

    local perapge = 200
    local pages = math.ceil(table.size(self._filtered) / perapge)
    local page = self._page
    local pagination = BeardLib.Utils:MakePagination(page, pages, 2)

    for i, page_num in pairs(pagination) do
        if page_num == 1 or page_num == pages then
            local next_or_prev = pagination[i - 1] or pagination[i + 1]
            if next_or_prev and math.abs(next_or_prev-page_num) > 1 then
                self._pages:lbl("...", {size_by_text = true, index = page_num == 1 and 2 or nil})
            end
        end
        self._pages:s_btn(page_num, ClassClbk(self, "set_page", page_num), {border_bottom = page_num == page})
    end

    self._list:ClearItems()

    local i = 0

    for name in pairs(self._filtered) do
        i = i + 1
        if i > perapge * (page-1) and i < perapge * (page + 1) then -- Is it in the page's range?
            self._list:button(name:gsub("units/", ""), ClassClbk(self, "on_click_item", name), {border_left = true, offset = {1, 4},
                items = {
                    {
                        text = "Add To Favorites",
                        on_callback = function()
                            log("TODO")
                        end
                    }
                }
            })
        end
    end

    self._list:AlignItems()
end

function SearchList:set_page(page)
    self._page = page
    self:do_show()
end

UnitSpawnList = UnitSpawnList or class(SearchList)

function UnitSpawnList:do_search_list()
    for unit in pairs(BLE.DBPaths.unit) do
        if not unit:match("wpn_") and not unit:match("msk_") then
            if not self._search or self._search:len() == 0 or unit:match(self._search) then
                self._filtered[unit] = true
            end
        end
    end
    log(table.size(self._filtered))
end

function UnitSpawnList:on_click_item(name)
    if PackageManager:has(Idstring("unit"), name:id()) then
        self._parent:begin_spawning(name)
    else
        self:load_from_db(name)
    end
end

function UnitSpawnList:load_from_db(unit)
    local world = self:GetPart("world")
    local pkgs = world._assets_manager and world._assets_manager:get_level_packages()

    if BLE.Utils:IsLoaded(unit, "unit", pkgs) then
        self:begin_spawning(unit)
        return
    end

    world._assets_manager:load_from_extract({unit = {[unit] = true}}, {
        texture = true,
        model = true,
        cooked_physics = true
    }, false, true, ClassClbk(self._parent, "begin_spawning", unit))
end


ElementSpawnList = ElementSpawnList or class(SearchList)
PrefabSpawnList = PrefabSpawnList or class(SearchList)
InstanceSpawnList = InstanceSpawnList or class(SearchList)
