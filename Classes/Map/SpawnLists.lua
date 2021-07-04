SpawnSearchList = SpawnSearchList or class(SearchList)
SpawnSearchList.PER_PAGE = 200
function SpawnSearchList:init(parent)
    SpawnSearchList.super.init(self, parent)
    self._fav = BLE.Options:GetValue("Map/FavoriteItems")
    self._fav.spawn_menu = self._fav.spawn_menu or {}
end

function SpawnSearchList:create_list_item(item)
    local favbtn
    local favorited = false
    local object = item.fav_id
    if self._fav.spawn_menu[object] then
        favorited = true
        favbtn = {
            text = "Remove from Favorites",
            on_callback = function()
                self._fav.spawn_menu[object] = nil
                self:do_search(true)
                BLE.Options:SetValue("Map/FavoriteItems", self._fav)
                BLE.Options:Save()
            end
        }
    else
        favbtn = {
            text = "Add To Favorites",
            on_callback = function()
                self._fav.spawn_menu[object] = true
                self:do_search(true)
                BLE.Options:SetValue("Map/FavoriteItems", self._fav)
                BLE.Options:Save()
            end
        }
    end

    return self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {border_left = true, border_color = favorited and Color.green or nil, offset = {1, 4}, items = {favbtn}})
end

function SpawnSearchList:insert_item_to_filtered_list(item)
    if self._fav.spawn_menu[item.fav_id] then
        table.insert(self._filtered, 1, item)
    else
        table.insert(self._filtered, item)
    end
end

function SpawnSearchList:sort_items()
    local spawn_menu = self._fav.spawn_menu
    table.sort(self._filtered, function(a,b)
        local a_is_fav = spawn_menu[a.fav_id]
        local b_is_fav = spawn_menu[b.fav_id]

        if a_is_fav and b_is_fav or not a_is_fav and not b_is_fav then
            return a.name < b.name
        elseif a_is_fav then
            return true
        elseif b_is_fav then
            return false
        end
    end)
end
------------------------------------- Units -------------------------------------------

UnitSpawnList = UnitSpawnList or class(SpawnSearchList)

function UnitSpawnList:init(parent)
    UnitSpawnList.super.init(self, parent)

    self._options:tickbox("ShortUnitPaths", ClassClbk(self, "set_short_unit_paths"), BLE.Options:GetValue("Map/ShortUnitPaths"), {help = "Shortens the paths in this list"})
    self._options:tickbox("ShowLoadedUnitsOnly", ClassClbk(self, "do_search", false), false, {help = "Filters the list to show only units that are loaded."})
    self._options:tickbox("LoadWithPackages", nil, false, {
        help = "Opens a dialog to pick a package in order to load the unit instead of loading it from the database"
    })
end

function UnitSpawnList:set_short_unit_paths(item)
    self:GetPart("opt"):update_option_value(item)
    self:do_search()
end

local unit_ids = Idstring("unit")
UnitSpawnList.BLACKLIST = {
    "/wpn_",
    "/msk_",
    "/npc_",
    "/npc_",
    "/ene_",
    "/brushes"
}
function UnitSpawnList:do_search_list()
    local loaded_only = self._options:GetItemValue("ShowLoadedUnitsOnly")
    local short_path = BLE.Options:GetValue("Map/ShortUnitPaths")
    for unit in pairs(BLE.DBPaths.unit) do
        local blacklisted = false
        for _, bad in pairs(self.BLACKLIST) do
            if unit:match(bad) then
                blacklisted = true
                break
            end
        end
        if not blacklisted then
            if self:check_search(unit) then
                if not loaded_only or PackageManager:has(unit_ids, unit:id()) then
                    local name = unit:gsub("units/", "")
                    if short_path then
                        name = BLE.Utils:ShortPath(name, 3)
                    end
                    self:insert_item_to_filtered_list({name = name, object = unit, fav_id = unit})
                end
            end
        end
    end
end

function UnitSpawnList:on_click_item(item)
    if PackageManager:has(Idstring("unit"), item.object:id()) then
        self._parent:begin_spawning(item.object)
    else
        self:do_load(item.object)
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

ElementSpawnList = ElementSpawnList or class(SpawnSearchList)
ElementSpawnList.HIDE_PAGINATION = true
function ElementSpawnList:do_search_list()
    self._filtered = {}
    for _, element in pairs(BLE._config.MissionElements) do
        local name = element:gsub("Element", "")
        if self:check_search(element) then
            self:insert_item_to_filtered_list({name = name, object = element, fav_id = element})
        end
    end
end

function ElementSpawnList:on_click_item(item)
    self._parent:begin_spawning_element(item.object)
end

------------------------------------- Prefabs -------------------------------------------

PrefabSpawnList = PrefabSpawnList or class(SpawnSearchList)
function PrefabSpawnList:on_click_item(item)
    self:GetPart("static"):SpawnPrefab(item.object)
end

function PrefabSpawnList:do_search_list()
    self._filtered = {}
    for name, prefab in pairs(BLE.Prefabs) do
        if self:check_search(name) then
            self:insert_item_to_filtered_list({name = name, object = prefab, fav_id = name})
        end
    end
end

------------------------------------- Instances -------------------------------------------

InstanceSpawnList = InstanceSpawnList or class(SpawnSearchList)

function InstanceSpawnList:on_click_item(item)
    self._parent:SpawnInstance(item.object, nil, true)
end

function InstanceSpawnList:do_search_list()
    self._filtered = {}
    for _, path in pairs(table.merge(BLE.Utils:GetEntries({type = "world"}), table.map_keys(BeardLib.managers.MapFramework._loaded_instances))) do
        if path:match("levels/instances") and self:check_search(path) then
            self:insert_item_to_filtered_list({name = path:gsub("levels/instances/", ""), object = path, fav_id = path})
        end
    end
end