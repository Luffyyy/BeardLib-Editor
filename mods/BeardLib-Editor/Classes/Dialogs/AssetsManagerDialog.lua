AssetsManagerDialog = AssetsManagerDialog or class(MenuDialog)
AssetsManagerDialog.type_name = "AssetsManagerDialog"
AssetsManagerDialog._no_reshaping_menu = true
function AssetsManagerDialog:init(params, menu)
    params = params or {}
    params = deep_clone(params)
    menu = menu or BeardLib.managers.dialog:Menu()
    self._unit_info = menu:Menu(table.merge({
        name = "unitinfo",
        visible = false,
        h = 600,
        w = 300,
    }, params))
    self.super.init(self, table.merge({
        w = 800,
        h = 600,
        position = function(item)
            item:SetPositionByString("Center")
            item:Panel():move(-self._unit_info:Width() / 2)
        end,
        auto_height = false,
        items_size = 20,
    }, params), menu)
    self._unit_info:SetPosition(function(item)
        item:Panel():set_lefttop(self._menu:Panel():righttop())
    end)
    self._menus = {self._unit_info}
    MenuUtils:new(self)
end

function AssetsManagerDialog:Show()
    if not self.super.Show(self, {yes = false}) then
        return
    end
    self._missing_units = {}
    local btn = self:Button("Close", callback(self, self, "hide", true), {position = "Bottom", count_height = true})
    local group_h = (self._menu:Height() / 2) - 24
    local packages = self:DivGroup("Packages", {h = group_h - (btn:Height() + 8), auto_height = false, scrollbar = true})
    local units = self:DivGroup("Units", {h = group_h, auto_height = false, auto_align = false, scrollbar = true})
    local function base_pos(item)
        item:SetPositionByString("Top")
        item:Panel():set_world_right(item.override_parent.items_panel:world_right() - 8)
    end
    local add = self:Button("Add", callback(self, self, "add_package_dialog"), {override_parent = packages, text = "+", size_by_text = true, position = base_pos})
    local search_opt = {override_parent = packages, w = 300, lines = 1, text = "Search", control_slice = 1.25, marker_highlight_color = false, position = function(item)
        item:SetPositionByString("Top")
        item:Panel():set_world_right(add:Panel():world_left() - 4)
    end}
    local search = self:TextBox("Search", callback(BeardLibEditor.Utils, BeardLibEditor.Utils, "FilterList"), "", search_opt)
    search_opt.position = base_pos
    search_opt.override_parent = units
    self:TextBox("Search2", callback(BeardLibEditor.Utils, BeardLibEditor.Utils, "FilterList"), "", search_opt)

    self:Divider("AssetsManagerStatus", {
        text = "(!) A unit or more are not loaded, you can decide to search for a package that contains(most) of the unloaded units(for leftover units you can repeat this process)",
        group = self._unit_info,
        color = false,
    })
    self:Button("FixBySearchingPackages", callback(self, self, "find_packages"), {group = self._unit_info})
    self:Divider("UnitInfoTitle", {text = "Unit Inspection", group = self._unit_info})
    self:Divider("UnitInfo", {text = "None Selected.", color = false, group = self._unit_info})
    local actions = self:DivGroup("Actions", {group = self._unit_info})
    self:Button("FindPackage", callback(self, self, "find_pacakge"), {offset = 0, group = actions, enabled = false})
    --self:Button("LoadFromExtract", callback(self, self, "load_from_extract"), {offset = 0, group = actions, enabled = false})
    self:Button("RemoveFromMap", callback(self, self, "remove_units_from_map"), {offset = 0, group = actions, enabled = false})

    self:reload()
    self._menu:AlignItems(true)
end

function AssetsManagerDialog:load_units()
    local units = self:GetItem("Units")
    if not units then
        return
    end
    units:ClearItems("units")
    self._missing_units = {}
    local panic
    for unit, times in pairs(managers.worlddefinition._all_names) do
        local loaded = #self:get_packages_of_asset(unit, "unit", false, true) > 0
        if not loaded then
            self._missing_units[unit] = true
            panic = true
        end
        self:Button(unit, callback(self, self, "set_unit_selected"), {group = units, text = unit.."("..times..")", label = "units", index = not loaded and 1, text_color = not loaded and Color.red, text_highlight_color = units.text_color})
    end
    self._unit_info:GetItem("AssetsManagerStatus"):SetVisible(panic)
    self._unit_info:GetItem("FixBySearchingPackages"):SetVisible(panic)
end

function AssetsManagerDialog:load_packages()
    local packages = self:GetItem("Packages")
    if not packages then
        return
    end
    packages:ClearItems("packages")
    local project = BeardLibEditor.managers.MapProject
    local mod = project:current_mod()
    self._tbl._data = mod and project:get_clean_data(mod._clean_config)
    self._current_level = BeardLibEditor.managers.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
    if self._tbl._data then
        local level = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
        if level.packages then
            for i, package in ipairs(level.packages) do
                local size = BeardLibEditor.Utils:GetPackageSize(package)
                if size then
                    local pkg = self:Divider(package, {closed = true, text = string.format("%s(%.2fmb)", package, size), group = packages, label = "packages"})
                    self:SmallImageButton("RemovePackage", callback(self, self, "remove_package", package), "textures/editor_icons_df", {184, 2, 48, 48}, pkg)
                end
            end
        end
    end
end

function AssetsManagerDialog:load_from_extract()
    managers.editor.managers.utils:SpawnUnitFromExtract(self._tbl._selected.name, false, true)
end

function AssetsManagerDialog:find_pacakge(unit, dontask)
    function find_pacakge()
        local items = {}
        for _, pkg in pairs(BeardLibEditor.Utils:GetPackagesOfUnit(unit or self._tbl._selected.name, true)) do
            table.insert(items, {name = string.format("%s(%.2fmb)", pkg.name, pkg.size), size = pkg.size, package = pkg.name})
        end
        table.sort(items, function(a,b)
            return a.size < b.size
        end)
        BeardLibEditor.managers.ListDialog:Show({
            list = items,
            callback = function(selection)
                self:add_package(selection.package)
                BeardLibEditor.managers.ListDialog:hide()
            end
        })        
    end
    if not dontask then
        BeardLibEditor.Utils:YesNoQuestion("This will search for packages that contain this unit, it's recommended to choose the smallest one so your level will load faster", function()
            find_pacakge()
        end)
    else
        find_pacakge()
    end
end

function AssetsManagerDialog:find_packages()
    local packages = {}
    for name, package in pairs(BeardLibEditor.DBPackages) do
        for _, unit in pairs(package.unit or {}) do
            if self._missing_units[unit] == true then
                packages[name] = packages[name] or {}
                table.insert(packages[name], unit)
            end
        end
    end
    local items = {}
    local missing_amount = table.size(self._missing_units)
    for name, package in pairs(packages) do
        local size = BeardLibEditor.Utils:GetPackageSize(name)
        if size then
            table.insert(items, {name = string.format("%s has %s/%s of the missing units(%.2fmb)", name, #package, missing_amount, size), package = name, size = size, amount = #package})
        end
    end
    table.sort(items, function(a,b)
        return a.amount > b.amount
    end)
    BeardLibEditor.managers.ListDialog:Show({
        list = items,
        callback = function(selection)
            self:add_package(selection.package)
            BeardLibEditor.managers.ListDialog:hide()
        end
    })
end

function AssetsManagerDialog:remove_units_from_map()
    BeardLibEditor.Utils:YesNoQuestion("This will remove all of the spawned units of that unit, this will not remove units that are inside an instance(save is required)", function()
        for k, unit in pairs(managers.worlddefinition._all_units) do
            local ud = alive(unit) and unit:unit_data()
            if ud and not ud.instance and ud.name == self._tbl._selected.name then
                managers.editor:DeleteUnit(unit)
            end
        end
        managers.worlddefinition._all_names[self._tbl._selected.name] = nil
        local continents = managers.worlddefinition._continent_definitions
        local temp = deep_clone(continents)
        for name, continent in pairs(temp) do
            for i, static in pairs(continent.statics) do
                if static.unit_data and static.unit_data.name == self._tbl._selected.name then
                    table.remove(continents[name].statics, i)
                end
            end
        end
        managers.editor:m().opt:save()
        self:all_ok_dialog()
        self:reload()
    end)
end

function AssetsManagerDialog:get_level_packages()
    if not self._current_level or not self._tbl._data then
        local project = BeardLibEditor.managers.MapProject
        local mod = project:current_mod()
        self._tbl._data = mod and project:get_clean_data(mod._clean_config)
        self._current_level = BeardLibEditor.managers.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
    end
    local packages = {}
    for _, package in pairs(self._current_level.packages) do
        packages[package] = BeardLibEditor.DBPackages[package]
    end
    return packages
end

function AssetsManagerDialog:is_asset_loaded(asset, type)
    return BeardLibEditor.Utils:IsLoaded(asset, type, self:get_level_packages())
end

function AssetsManagerDialog:get_packages_of_asset(asset, type, size_needed, first)
    return BeardLibEditor.Utils:GetPackages(asset, type, size_needed, first, self:get_level_packages())
end

function AssetsManagerDialog:set_unit_selected(menu, item)
    if self._tbl._selected then
        self._tbl._selected:SetBorder({left = false})
    end
    if self._tbl._selected == item then
        self._tbl._selected = nil
    else
        self._tbl._selected = item
        item:SetBorder({left = true})
    end
    if self._tbl._selected then
        local unit = self._tbl._selected.name
        local project = BeardLibEditor.managers.MapProject
        local pkgs_s
        local short_path = function(path, times)
            local path_splt = string.split(path, "/")
            for i=1, #path_splt - times do table.remove(path_splt, 1) end
            path = "..."
            for _, s in pairs(path_splt) do
                path = path.."/"..s
            end
            return path
        end
        for _, pkg in pairs(self:get_packages_of_asset(unit, "unit", true)) do
            pkgs_s = pkgs_s or ""
            local name = pkg.name
            if name:sub(1, 6) == "levels" then
                name = short_path(name, 3)
            end
            local pkg_s = string.format("%s(%.2fmb)", name, pkg.size)
            pkgs_s = pkgs_s.."\n"..pkg_s
        end
        self._unit_info:GetItem("UnitInfo"):SetText("| Unit:\n"..short_path(unit, 2) .. "\n| " .. (pkgs_s and "Loaded From:"..pkgs_s or "Unloaded, please load the unit using one of the methods below"))
    else
        self._unit_info:GetItem("UnitInfo"):SetText("None Selected.")
    end
    self._unit_info:GetItem("FindPackage"):SetEnabled(self._tbl._selected ~= nil)
   --self._unit_info:GetItem("LoadFromExtract"):SetEnabled(self._tbl._selected ~= nil)
    self._unit_info:GetItem("RemoveFromMap"):SetEnabled(self._tbl._selected ~= nil)
    self._unit_info:AlignItems(true)
end

function AssetsManagerDialog:add_package(package)
    local project = BeardLibEditor.managers.MapProject
    local level_packages = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
    table.insert(level_packages, package)
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
    if PackageManager:package_exists(package.."_init") and not PackageManager:loaded(package.."_init") then
        PackageManager:load(package.."_init")
    end
    if PackageManager:package_exists(package) and not PackageManager:loaded(package) then
        PackageManager:load(package)
    else
        BeardLibEditor:log("[Warning] Something went wrong in AssetsManagerDialog:add_package_dialog")
    end
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
    project:map_editor_save_main_xml(self._tbl._data)
    project:_reload_mod(self._tbl._data.name)
    self:reload()
    self:all_ok_dialog()
end

function AssetsManagerDialog:all_ok_dialog()
    local status = self._unit_info:GetItem("AssetsManagerStatus")
    if status and not status:Visible() then
        local opt = {title = "Hooray!", message = "All units are now loaded!"}
        if Global.editor_safe_mode then
            opt.message = opt.message .. " Load to normal mode?"
            BeardLibEditor.Utils:QuickDialog(opt, {"Yes", function()
                Global.editor_safe_mode = nil
                managers.game_play_central:restart_the_game()
            end})
        else
            BeardLibEditor.managers.Dialog:Show(opt)
        end        
    end
end

function AssetsManagerDialog:add_package_dialog()
    local packages = {}
    local level_packages = BeardLibEditor.managers.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
    for name in pairs(BeardLibEditor.DBPackages) do
        if not table.contains(level_packages, name) then
            table.insert(packages, name)
        end
    end
    BeardLibEditor.managers.ListDialog:Show({
        list = packages,
        callback = function(item)
            self:add_package(item)
            BeardLibEditor.managers.ListDialog:hide()
        end
    })
    self:reload()
end

function MapProjectManager:_reload_mod(name)
    BeardLib.managers.MapFramework._loaded_mods[name] = nil
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
end


function AssetsManagerDialog:remove_package(package, menu, item)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the package from your level(this will not unload the package if there's a spawned unit that is loaded by the pacakge)", function()
        local project = BeardLibEditor.managers.MapProject
        local packages = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
        for i, pkg in ipairs(packages) do
            if pkg == package then
                table.remove(packages, i)
                break
            end
        end
        local p_units = BeardLibEditor.DBPackages[package].units
        local can_remove = p_units ~= nil
        if can_remove then
            for k, unit in pairs(World:find_units_quick("all")) do
                if not can_remove then
                    break
                end
                local ud = unit:unit_data()
                if ud then
                    for _, u in pairs(p_units) do
                        if u == ud.name then
                            can_remove = false
                            break
                        end
                    end
                end
            end
        end
        if can_remove then
            managers.worlddefinition:_unload_package(package.."_init")
            managers.worlddefinition:_unload_package(package)
        end
        menu:RemoveItem(item.override_parent)
        project:map_editor_save_main_xml(self._tbl._data)
        project:_reload_mod(self._tbl._data.name)
        self:reload()
    end)
end

function AssetsManagerDialog:reload()
    self:load_packages()
    self:load_units()
end

function AssetsManagerDialog:hide(yes)
    self._unit_info:SetVisible(false)
    return AssetsManagerDialog.super.hide(self, yes)
end