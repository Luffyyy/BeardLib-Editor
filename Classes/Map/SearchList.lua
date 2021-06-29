SearchList = SearchList or class(EditorPart)

function SearchList:init(parent)
    self._menu = parent._holder:pan("Tab", {visible = false, auto_height = false, offset = {0, 8}, h = parent._holder:ItemsHeight() - 16, scrollbar = false})
    self._options = self._menu:group("Options", {private = {offset = 0}})
    self._options:textbox("Search", ClassClbk(self, "do_search"), nil, {control_slice = 0.75})

    self._parent = parent
    self._pages = self._menu:pan("Pages", {align_method = "centered_grid", visible = not self.HIDE_PAGINATION})

    self._fav = BLE.Options:GetValue("Map/FavoriteItems")
    self._fav.spawn_menu = self._fav.spawn_menu or {}

    self._page = 1

    self._list = self._menu:pan("Units", {inherit_values = {size = 14}, offset = {0, 8}, auto_align = false, auto_height = false, h = self._menu:ItemsHeight() - (self.HIDE_PAGINATION and 75 or 120)})
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
    if self._fav.spawn_menu[self:item_id(item)] then
        table.insert(self._filtered, 1, item)
    else
        table.insert(self._filtered, item)
    end
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

    for i, v in pairs(self._filtered) do
        if i > perapge * (page-1) and i < perapge * (page + 1) then -- Is it in the page's range?
            local favbtn
            local favorited = false
            local id = self:item_id(v)
            if self._fav.spawn_menu[id] then
                favorited = true
                favbtn = {
                    text = "Remove from Favorites",
                    on_callback = function()
                        self._fav.spawn_menu[id] = nil
                        self:do_search(true)
                        BLE.Options:SetValue("Map/FavoriteItems", self._fav)
                        BLE.Options:Save()
                    end
                }
            else
                favbtn = {
                    text = "Add To Favorites",
                    on_callback = function()
                        self._fav.spawn_menu[id] = true
                        self:do_search(true)
                        BLE.Options:SetValue("Map/FavoriteItems", self._fav)
                        BLE.Options:Save()
                    end
                }
            end
            self._list:button(self:friendly_item_name(v), ClassClbk(self, "on_click_item", v), {border_left = true, border_color = favorited and Color.green or nil, offset = {1, 4}, items = {favbtn}})
        end
    end

    self._list:AlignItems()
end

function SearchList:friendly_item_name(item)
    return type(item) == "table" and item.name or item
end

function SearchList:item_id(item)
    return type(item) == "table" and item.id or item
end

function SearchList:set_page(page)
    self._page = page
    self:do_show()
end

------------------------------------- Units -------------------------------------------

UnitSpawnList = UnitSpawnList or class(SearchList)

function UnitSpawnList:init(parent)
    UnitSpawnList.super.init(self, parent)

    self._options:tickbox("ShowLoadedUnitsOnly", ClassClbk(self, "do_search", false), false, {help = "Filters the list to show only units that are loaded."})
    self._options:tickbox("LoadWithPackages", nil, false, {
        help = "Opens a dialog to pick a package in order to load the unit instead of loading it from the database"
    })
end

local unit_ids = Idstring("unit")
local blacklist = {
    "/wpn_",
    "/msk_",
    "/npc_",
    "/npc_",
    "/ene_",
    "/brushes"
}
function UnitSpawnList:do_search_list()
    local loaded_only = self._options:GetItemValue("ShowLoadedUnitsOnly")
    for unit in pairs(BLE.DBPaths.unit) do
        local blacklisted = false
        for _, bad in pairs(blacklist) do
            if unit:match(bad) then
                blacklisted = true
                break
            end
        end
        if not blacklisted then
            if not loaded_only or PackageManager:has(unit_ids, unit:id()) then
                if not self._search or self._search:len() == 0 or unit:lower():match(self._search:lower()) then
                    self:insert_item_to_filtered_list({name = unit:gsub("units/", ""), id = unit})
                end
            end
        end
    end
end

function UnitSpawnList:on_click_item(item)
    if PackageManager:has(Idstring("unit"), item.unit:id()) then
        self._parent:begin_spawning(item.id)
    else
        self:do_load(item.id)
    end
end

function UnitSpawnList:do_load(unit)
    local assets = self:GetPart("assets")

    if assets:is_asset_loaded("unit", unit) then
        self:begin_spawning(unit)
        return
    end

    local begin_spawning = ClassClbk(self._parent, "begin_spawning", unit)
    if self._options:GetItemValue("LoadWithPackages") then
        assets:find_package(unit, "unit", true, begin_spawning)
    else
        assets:quick_load_from_db("unit", unit, begin_spawning)
    end
end

------------------------------------- Elements -------------------------------------------

ElementSpawnList = ElementSpawnList or class(SearchList)
ElementSpawnList.HIDE_PAGINATION = true
function ElementSpawnList:do_search_list()
    self._filtered = {}
    for _, element in pairs(BLE._config.MissionElements) do
        local name = element:gsub("Element", "")
        if not self._search or self._search:len() == 0 or element:lower():match(self._search:lower()) then
            self:insert_item_to_filtered_list({name = name, id = element})
        end
    end
    local spawn_menu = self._fav.spawn_menu
    table.sort(self._filtered, function(a,b)
        local a_is_fav = spawn_menu[a.id]
        local b_is_fav = spawn_menu[b.id]

        if a_is_fav and b_is_fav or not a_is_fav and not b_is_fav then
            return a.id < b.id
        elseif a_is_fav then
            return true
        elseif b_is_fav then
            return false
        end
    end)
end

function ElementSpawnList:on_click_item(item)
    self._parent:begin_spawning_element(item.id)
end

------------------------------------- Prefabs -------------------------------------------

PrefabSpawnList = PrefabSpawnList or class(SearchList)
function PrefabSpawnList:on_click_item(item)
    self:GetPart("static"):SpawnPrefab(item.id)
end

function PrefabSpawnList:do_search_list()
    self._filtered = {}
    for name, prefab in pairs(BLE.Prefabs) do
        if not self._search or self._search:len() == 0 or name:lower():match(self._search:lower()) then
            self:insert_item_to_filtered_list({name = name, id = prefab})
        end
    end
end

------------------------------------- Instances -------------------------------------------

InstanceSpawnList = InstanceSpawnList or class(SearchList)

function InstanceSpawnList:on_click_item(item)
    self._parent:SpawnInstance(item.id, nil, true)
end

function InstanceSpawnList:do_search_list()
    self._filtered = {}
    for _, path in pairs(table.merge(BLE.Utils:GetEntries({type = "world"}), table.map_keys(BeardLib.managers.MapFramework._loaded_instances))) do
        if path:match("levels/instances") and (not self._search or self._search:len() == 0 or path:lower():match(self._search:lower())) then
            self:insert_item_to_filtered_list({name = path:gsub("levels/instances/", ""), id = path})
        end
    end
end