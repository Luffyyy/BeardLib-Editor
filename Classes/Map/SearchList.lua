SearchList = SearchList or class(EditorPart)

function SearchList:init(parent)
    self._menu = parent._holder:pan("Tab", {visible = false, auto_height = false, offset = {0, 8}, h = parent._holder:ItemsHeight() - 16, scrollbar = false})
    self._options = self._menu:group("Options", {private = {offset = 0}})
    self._options:textbox("Search", ClassClbk(self, "do_search"), nil, {control_slice = 0.75})

    self._parent = parent
    self._pages = self._menu:pan("Pages", {align_method = "centered_grid", visible = not self.HIDE_PAGINATION})

    self._page = 1

    self._list = self._menu:pan("Units", {inherit_values = {size = 14}, offset = {0, 8}, auto_align = false, auto_height = false, h = self._menu:ItemsHeight() - (self.HIDE_PAGINATION and 75 or 120)})
    self:do_search()
end

function SearchList:set_visible(vis)
    self._menu:SetVisible(vis)
end

function SearchList:on_click_item(name)
end

function SearchList:do_search(item)
    item = self._options:GetItem("Search")
    BeardLib:AddDelayedCall("BLEDoSearchList"..tostring(self), self._filtered == nil and 0 or 0.2, function()
        self._search = item:Value()
        self._filtered = {}
        self:do_search_list()
        self._page = 1
        self:do_show()
    end)
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
            self._list:button(self:friendly_item_name(v), ClassClbk(self, "on_click_item", v), {border_left = true, offset = {1, 4},
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

function SearchList:friendly_item_name(full_name)
    return type(full_name) == "table" and full_name.name or full_name
end

function SearchList:set_page(page)
    self._page = page
    self:do_show()
end

------------------------------------- Units -------------------------------------------

UnitSpawnList = UnitSpawnList or class(SearchList)

function UnitSpawnList:init(parent)
    UnitSpawnList.super.init(self, parent)

    self._options:tickbox("ShowLoadedUnitsOnly", ClassClbk(self, "do_search"), false, {help = "Filters the list to show only units that are loaded."})
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
                    table.insert(self._filtered, {name = unit:gsub("units/", ""), unit = unit})
                end
            end
        end
    end
end

function UnitSpawnList:on_click_item(item)
    if PackageManager:has(Idstring("unit"), item.unit:id()) then
        self._parent:begin_spawning(item.unit)
    else
        self:do_load(item.unit)
    end
end

function UnitSpawnList:do_load(unit)
    local world = self:GetPart("world")
    local pkgs = world._assets_manager and world._assets_manager:get_level_packages()

    if BLE.Utils:IsLoaded(unit, "unit", pkgs) then
        self:begin_spawning(unit)
        return
    end

    local start_spawning = ClassClbk(self._parent, "begin_spawning", unit)
    if self._options:GetItemValue("LoadWithPackages") then
        world._assets_manager:find_package(unit, "unit", true, start_spawning)
    else
        world._assets_manager:load_from_extract({unit = {[unit] = true}}, {
            texture = true,
            model = true,
            cooked_physics = true
        }, false, true, start_spawning)
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
            table.insert(self._filtered, {name = name, element = element})
        end
    end
    table.sort(self._filtered, function(a,b) return b.name > a.name end)
end

function ElementSpawnList:on_click_item(item)
    self._parent:begin_spawning_element(item.element)
end

------------------------------------- Prefabs -------------------------------------------

PrefabSpawnList = PrefabSpawnList or class(SearchList)
function PrefabSpawnList:on_click_item(item)
    self:GetPart("static"):SpawnPrefab(item.prefab)
end

function PrefabSpawnList:do_search_list()
    self._filtered = {}
    for name, prefab in pairs(BLE.Prefabs) do
        if not self._search or self._search:len() == 0 or name:lower():match(self._search:lower()) then
            table.insert(self._filtered, {name = name, prefab = prefab})
        end
    end
end

------------------------------------- Instances -------------------------------------------

InstanceSpawnList = InstanceSpawnList or class(SearchList)

function InstanceSpawnList:on_click_item(item)
    self._parent:SpawnInstance(item.instance, nil, true)
end

function InstanceSpawnList:do_search_list()
    self._filtered = {}
    for _, path in pairs(table.merge(BLE.Utils:GetEntries({type = "world"}), table.map_keys(BeardLib.managers.MapFramework._loaded_instances))) do
        if path:match("levels/instances") and (not self._search or self._search:len() == 0 or path:lower():match(self._search:lower())) then
            table.insert(self._filtered, {name = path:gsub("levels/instances/", ""), instance = path})
        end
    end
end