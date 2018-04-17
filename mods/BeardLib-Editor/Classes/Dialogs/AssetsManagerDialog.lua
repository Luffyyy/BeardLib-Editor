AssetsManagerDialog = AssetsManagerDialog or class(MenuDialog)
AssetsManagerDialog.type_name = "AssetsManagerDialog"
AssetsManagerDialog._no_reshaping_menu = true
AssetsManagerDialog.ImportHelp = [[
This will search for dependencies that the unit requires in order to load.
Units that have a network counterpart will have to be loaded manually(this will hopefully change in the future).
Any missing dependency from your extract directory will fail the load. So be sure your extract is not outdated.
]]

function AssetsManagerDialog:init(params, menu)
    if self.type_name == AssetsManagerDialog.type_name then
        params = params and clone(params) or {}
    end
    menu = menu or BeardLib.managers.dialog:Menu()
    self._unit_info = menu:Menu(table.merge({
        name = "unitinfo",
        visible = false,
        auto_foreground = true,
        h = 600,
        w = 300,
    }, params))
    AssetsManagerDialog.super.init(self, table.merge({
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

function AssetsManagerDialog:_Show()
    if not self.super._Show(self, {yes = false}) then
        return
    end
    self._params = nil
    self._assets_units = {}
    self._missing_units = {}
    local btn = self:Button("Close", callback(self, self, "hide", true), {position = "Bottom", count_height = true})
    local group_h = (self._menu:Height() / 2) - 24
    local packages = self:DivGroup("Packages", {h = group_h - (btn:Height() + 8), auto_height = false, scrollbar = true})
    local units = self:DivGroup("Units", {h = group_h, auto_height = false, auto_align = false, scrollbar = true})
    local function base_pos(item)
        item:SetPositionByString("Top")
        item:Panel():set_world_right(item.override_panel.items_panel:world_right() - 8)
    end
    local add = self:Button("Add", callback(self, self, "add_package_dialog"), {override_panel = packages, text = "+", size_by_text = true, position = base_pos})
    local search_opt = {override_panel = packages, w = 300, lines = 1, text = "Search", control_slice = 0.8, highlight_color = false, position = function(item)
        item:SetPositionByString("Top")
        item:Panel():set_world_right(add:Panel():world_left() - 4)
    end}
    local search = self:TextBox("Search", ClassClbk(BLE.Utils, "FilterList"), "", search_opt)
    search_opt.position = base_pos
    search_opt.override_panel = units
    self:TextBox("Search2", ClassClbk(BLE.Utils, "FilterList"), "", search_opt)

    self:Divider("AssetsManagerStatus", {
        text = "(!) A unit or more are not loaded, you can decide to search for a package that contains(most) of the unloaded units(for leftover units you can repeat this process)",
        group = self._unit_info,
        visible = false,
        color = false,
    })
    self:Button("FixBySearchingPackages", ClassClbk(self, "find_packages", false), {group = self._unit_info})
    self:Button("FixByLoadingFromExtract", ClassClbk(self, "load_from_extract", false), {group = self._unit_info})
    self:Button("RemoveAndUnloadUnusedAssets", ClassClbk(self, "remove_unused_units_from_map", false), {group = self._unit_info})
    self:Divider("UnitInfoTitle", {text = "Unit Inspection", group = self._unit_info})
    self:Divider("UnitInfo", {text = "None Selected.", color = false, group = self._unit_info})
    local actions = self:DivGroup("Actions", {group = self._unit_info})
    self:Button("FindPackage", ClassClbk(self, "find_package", false, false), {offset = 0, group = actions, enabled = false})
    self:Button("LoadFromExtract", ClassClbk(self, "load_from_extract_dialog"), {offset = 0, group = actions, enabled = false, visible = FileIO:Exists(BLE.ExtractDirectory)})

    self:Button("RemoveAndUnloadAsset", ClassClbk(self, "remove_unit_from_map", true, false), {offset = 0, group = actions, enabled = false})
    self:Button("Remove", ClassClbk(self, "remove_unit_from_map", false, false), {offset = 0, group = actions, enabled = false})
    self:Button("UnloadAsset", ClassClbk(self, "unload_asset", false), {offset = 0, group = actions, enabled = false})

    self:reload()
end

function AssetsManagerDialog:load_units_from_assets()
    self._assets_units = {}
    local project = BLE.MapProject
    local mod, data = mod and project:get_mod_and_config()
    if data then
        local level = project:get_level_by_id(data, Global.game_settings.level_id)
        local add_path = level.add.file or Path:Combine(level.include.directory, "add.xml")
        local add = project:read_xml(add_path)
        if add then
            for _, node in pairs(add) do
                if type(node) == "table" and node._meta == "unit_load" then
                    self._assets_units[node.name] = true
                end
            end
        end
    end
end

function AssetsManagerDialog:load_units()
    local units = self:GetItem("Units")
    if not units then
        return
    end
    units:ClearItems("units")
    self._missing_units = {}
    local add
    local project = BLE.MapProject
    local mod = project:current_mod()
    if self._tbl._data then
        add = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).add
    end
    local panic
    local new_unit = function(unit, times)
        local loaded = self:is_asset_loaded(unit, "unit")
        if not loaded then
            if add then
                loaded = self._assets_units[unit] ~= nil
            end
            if not loaded then
                self._missing_units[unit] = true
                panic = true
            end
        end
        local unused = times == 0
        local bgcolor = not loaded and Color.red:with_alpha(0.4) or (unused and Color.yellow:with_alpha(0.4)) or nil
        self:Button(unit, callback(self, self, "set_unit_selected"), {
            group = units,
            text = unit.."("..times..")",
            label = "units",
            index = (not loaded or unused) and 1 or nil,
            background_color = bgcolor,
        })
    end
    for unit, times in pairs(managers.worlddefinition._all_names) do
        new_unit(unit, times)
    end
    for unit, _ in pairs(self._assets_units) do
        if not managers.worlddefinition._all_names[unit] then
            new_unit(unit, 0)
        end
    end
    local panicked = self._unit_info:GetItem("AssetsManagerStatus"):Visible()
    self._unit_info:GetItem("AssetsManagerStatus"):SetVisible(panic)
    self._unit_info:GetItem("FixBySearchingPackages"):SetVisible(panic)
    self._unit_info:GetItem("FixByLoadingFromExtract"):SetVisible(panic)
    if panicked and not panic then
        self:all_ok_dialog()
    end
end

function AssetsManagerDialog:load_packages()
    local packages = self:GetItem("Packages")
    if not packages then
        return
    end
    packages:ClearItems("packages")
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    self._tbl._data = data
    self._current_level = BLE.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
    if self._tbl._data then
        local level = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
        if level.packages then
            for i, package in pairs(level.packages) do
                local custom = CustomPackageManager.custom_packages[package:key()] ~= nil
                local size = not custom and BLE.Utils:GetPackageSize(package)
                if size or custom then
                    local text = custom and string.format("%s(custom)", package, size) or string.format("%s(%.2fmb)", package, size)
                    local pkg = self:Divider(package, {closed = true, text = text, group = packages, label = "packages"})
                    self:SmallImageButton("RemovePackage", callback(self, self, "remove_package", package), "textures/editor_icons_df", {184, 2, 48, 48}, pkg)
                end
            end
        end
    end
end

function AssetsManagerDialog:load_from_extract_dialog()
    BLE.Utils:YesNoQuestion(
        self.ImportHelp,
        function()
            self:load_from_extract({[self._tbl._selected.name] = true})
        end
    )
end

function AssetsManagerDialog:find_package(unit, dontask, clbk)
    function find_package()
        local items = {}
        for _, pkg in pairs(BLE.Utils:GetPackagesOfUnit(unit or self._tbl._selected.name, true)) do
            local text = pkg.custom and string.format("%s(custom)", pkg.name) or string.format("%s(%.2fmb)", pkg.name, pkg.package_size)
            table.insert(items, {name = text, package_size = pkg.package_size, package = pkg.name})
        end
        table.sort(items, function(a,b)
            if a.custom then
                return true
            end
            if not a.package_size then
                return false
            end
            if not b.package_size then
                return true
            end
            return a.package_size < b.package_size
        end)
        BLE.ListDialog:Show({
            list = items,
            force = true,
            sort = false,
            callback = function(selection)
                self:add_package(selection.package)
                if type(clbk) == "function" then
                    clbk()
                end
                BLE.ListDialog:hide()
            end
        })        
    end
    if not dontask then
        BLE.Utils:YesNoQuestion("This will search for packages that contain this unit, it's recommended to choose the smallest one so your level will load faster", function()
            find_package()
        end)
    else
        find_package()
    end
end

function AssetsManagerDialog:clean_add_xml()
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    local level = project:current_level(data)
    level.add = level.add or {}
    local add_path = level.add.file or Path:Combine(level.include.directory, "add.xml")
    local add = project:read_xml(add_path) or {_meta = "add", directory = "assets"}
    local new_add = {}

    for k, v in pairs(add) do
        if not tonumber(k) and type(v) ~= "table" then
            new_add[k] = v
        end
    end

    for k,v in pairs(add) do
        if tonumber(k) and type(v) == "table" and v._meta then
            local exists
            for _, tbl in pairs(new_add) do
                if type(tbl) == "table" and tbl._meta == v._meta and ((tbl.path and tbl.path == v.path) or (tbl.name and tbl.name == v.name)) then
                    exists = true
                    break
                end
            end
            if not exists then
                if not v.path or FileIO:Exists(Path:Combine(mod.ModPath, new_add.directory, v.path) ..".".. v._meta) then
                    table.insert(new_add, v)
                end
            end
        end
    end
    project:save_xml(add_path, new_add)
end

function AssetsManagerDialog:load_from_extract(missing_units)
    missing_units = missing_units or self._missing_units
    local config = {}
    local failed_all = false
    for unit, _ in pairs(missing_units) do
        local cfg = BLE.Utils.Export:GetUnitDependencies(unit)
        if cfg then
            table.insert(config, table.merge({_meta = "unit_load", name = unit}, cfg))
        else
            failed_all = true
        end
    end
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    local to_copy = {}
    if data then
        local level = project:current_level(data)
        level.add = level.add or {}
        local add_path = level.add.file or Path:Combine(level.include.directory, "add.xml")
        local add = project:read_xml(add_path)
        add = add or {_meta = "add", directory = "assets"}
        for k,v in pairs(config) do
            local exists 
            for _, tbl in pairs(add) do
                if type(tbl) == "table" and tbl._meta == v._meta and tbl.name == v.name then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(add, v)
                table.insert(to_copy, v)
            end
        end
        local function save()
            local assets_dir = Path:Combine(mod.ModPath, add.directory or "")
            local copy_data = {}
            for _, unit_load in pairs(to_copy) do
                if type(unit_load) == "table" then
                    for _, asset in pairs(unit_load) do
                        if type(asset) == "table" and asset.path then
                            local path = asset.path .. "." .. asset._meta
                            local to_path = Path:Combine(assets_dir, path)
                            table.insert(copy_data, {asset.extract_real_path, to_path})
                            asset.extract_real_path = nil
                            local dir = BeardLib.Utils.Path:GetDirectory(to_path)
                            if not FileIO:Exists(dir) then
                                FileIO:MakeDir(dir)
                            end
                            BLE.Utils.allowed_units[asset.path] = true
                        end        
                    end
                end
            end
            project:save_xml(add_path, add)
            if #copy_data > 0 then
                FileIO:CopyFilesToAsync(copy_data, function(success)
                    if success then
                        CustomPackageManager:LoadPackageConfig(assets_dir, to_copy)
                        if failed_all then
                            BLE.Utils:Notify("Info", "Copied some assets, some have failed because not all dependencies exist in the extract path")
                        else
                            BLE.Utils:Notify("Info", "Copied assets successfully")
                        end
                        self:reload()
                    end
                end)
            else
                BLE.Utils:Notify("Info", "No assets to copy")
            end
        end
        if not dontask then
            BLE.Utils:YesNoQuestion("This will copy the required files from your extract directory and add the files to your map assets proceed?", save, function()
                CustomPackageManager:UnloadPackageConfig(config)
            end)
        else
            save()
        end
    end    
end

function AssetsManagerDialog:find_packages(missing_units, clbk)
    missing_units = missing_units or self._missing_units
    local packages = {}
    for name, package in pairs(BLE.DBPackages) do
        if package.unit then            
            for unit in pairs(package.unit) do
                if missing_units[unit] == true then
                    packages[name] = packages[name] or {}
                    table.insert(packages[name], unit)
                end
            end
        end
    end
    local items = {}
    local missing_amount = table.size(missing_units)
    for name, package in pairs(packages) do
        local size = BLE.Utils:GetPackageSize(name)
        if size then
            table.insert(items, {
                name = string.format("%s has %s/%s of the missing units(%.2fmb)", name, #package, missing_amount, size),
                package = name,
                package_size = size,
                amount = #package,
            })
        end
    end
    table.sort(items, function(a,b)
        if a.amount == b.amount then
            return a.package_size < b.package_size
        else
            return a.amount > b.amount
        end
    end)
    --last, just to color relevant items
    local curr_amount
    for _, item in pairs(items) do
        if item.amount ~= curr_amount then
            item.background_color = BLE._dialogs_opt.accent_color
            item.highlight_color = item.background_color
        end
        curr_amount = item.amount
    end
    BLE.ListDialog:Show({
        list = items,
        force = true,
        sort = false,
        callback = function(selection)
            self:add_package(selection.package)
            if type(clbk) == "function" then
                clbk()
            end
            BLE.ListDialog:hide()
        end
    })
end

function AssetsManagerDialog:remove_unused_units_from_map()
    BLE.Utils:YesNoQuestion("This will remove any unused units from your map and remove them from your map completely", function()
        for unit in pairs(self._assets_units) do
            if not managers.worlddefinition._all_names[unit] then
                self:remove_unit_from_map(true, unit)
            end
        end
        self:reload()
        self:set_unit_selected()
    end)
end

function AssetsManagerDialog:remove_unit_from_map(remove_asset, name)
    local ask = not name
    name = name or self._tbl._selected.name
    local remove = function()
        for k, unit in pairs(managers.worlddefinition._all_units) do
            local ud = alive(unit) and unit:unit_data()
            if ud and not ud.instance and ud.name == name then
                managers.editor:DeleteUnit(unit)
            end
        end
        managers.worlddefinition._all_names[name] = nil
        local continents = managers.worlddefinition._continent_definitions
        for cname, continent in pairs(continents) do
            if continent.statics then
                for i, static in pairs(continent.statics) do
                    if static.unit_data and static.unit_data.name == name then
                        table.remove(continent.statics, i)
                    end
                end
            end
        end
        if self._assets_units[name] and remove_asset == true then
            self:unload_asset(name, true)
        end
        if ask then
            managers.editor:m().opt:save()
            self:reload()
            self:set_unit_selected()
        end
    end
    if ask then
        BLE.Utils:YesNoQuestion(
            "This will remove all of the spawned units of that unit, this will not remove units that are inside an instance(save is required)",
            remove
        )
    else
        remove()
    end
end

function AssetsManagerDialog:unload_asset(name, no_dialog)
    name = name or self._tbl._selected.name
    local function unload()
        local project = BLE.MapProject
        local mod, data = project:get_mod_and_config()
        if data then
            local level = project:current_level(data)
            level.add = level.add or {}
            local add_path = level.add.file or Path:Combine(level.include.directory, "add.xml")
            local add = project:read_xml(add_path)
            if add then
                for k, node in pairs(add) do
                    if type(node) == "table" and node._meta == "unit_load" and node.name == name then
                        for _, asset in pairs(node) do
                            if type(asset) == "table" then
                                local used
                                for _, node in pairs(add) do
                                    if type(node) == "table" and node.name ~= name then
                                        for _, ass in pairs(node) do
                                            if type(ass) == "table" and ass._meta == asset._meta and ass.path == asset.path then
                                                used = true
                                                break
                                            end
                                        end
                                    end
                                end
                                if not used then
                                    FileIO:Delete(Path:Combine(mod.ModPath, add.directory, asset.path.."."..asset._meta))
                                end
                            end
                        end
                        table.remove(add, k)
                        BLE.Utils.allowed_units[name] = nil
                        break
                    end
                end
            end
            project:save_xml(add_path, add)
            FileIO:DeleteEmptyFolders(Path:Combine(mod.ModPath, add.directory))
            if no_dialog ~= false then
                self:reload()
            end
        end
    end
    if no_dialog == true then
        unload()
    else
        BLE.Utils:YesNoQuestion("This will unload the unit from your map", unload)
    end
end

function AssetsManagerDialog:check_data()
    if not self._current_level or not self._tbl._data then
        local project = BLE.MapProject
        local mod, data = project:get_mod_and_config()
        self._tbl._data = data
        self._current_level = BLE.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
    end
end

function AssetsManagerDialog:get_level_packages()
    self:check_data()
    local packages = {}
    for _, package in ipairs(table.merge(clone(BLE.ConstPackages), clone(self._current_level.packages))) do
        packages[package] = BLE.DBPackages[package]
    end
    return packages
end

function AssetsManagerDialog:is_asset_loaded(asset, type)
    return BLE.Utils:IsLoaded(asset, type, self:get_level_packages())
end

function AssetsManagerDialog:get_packages_of_asset(asset, type, size_needed, first)
    return BLE.Utils:GetPackages(asset, type, size_needed, first, self:get_level_packages())
end

function AssetsManagerDialog:set_unit_selected(item)
    local packages = self:GetItem("Packages")
    if not packages then
        return
    end
    if self._tbl._selected then
        self._tbl._selected:SetBorder({left = false})
    end
    if self._tbl._selected == item then
        self._tbl._selected = nil
    else
        self._tbl._selected = item
        if item then
            item:SetBorder({left = true})
        end
    end
    local loaded_from_package
    local unused
    local unit
    if self._tbl._selected then
        unit = self._tbl._selected.name
        local project = BLE.MapProject
        local load_from
        for _, pkg in pairs(self:get_packages_of_asset(unit, "unit", true)) do
            loaded_from_package = true
            load_from = load_from or ""
            local name = pkg.name
            if name:sub(1, 6) == "levels" then
                name = BLE.Utils:ShortPath(name, 3)
            end
            local pkg_s = pkg.custom and string.format("%s(custom)", name) or string.format("%s(%.2fmb)", name, pkg.package_size)
            load_from = load_from.."\n"..pkg_s
        end
        local add
        local project = BLE.MapProject
        local mod = project:current_mod()
        if self._tbl._data then
            add = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).add
        end
        if self._assets_units[unit] then
            load_from = (load_from or "") .. "\n".."Map Assets"
            if not managers.worlddefinition._all_names[unit] then
                load_from = load_from .. "\n" .. "| Warning: Unused!"
                unused = true
            end
        end
        self._unit_info:GetItem("UnitInfo"):SetText("| Unit:\n"..BLE.Utils:ShortPath(unit, 2) .. "\n| " .. (load_from and "Loaded From:"..load_from or "Unloaded, please load the unit using one of the methods below"))
    else
        self._unit_info:GetItem("UnitInfo"):SetText("None Selected.")
    end
    self._unit_info:GetItem("FindPackage"):SetEnabled(unit ~= nil)
    self._unit_info:GetItem("LoadFromExtract"):SetEnabled(unit ~= nil)
    self._unit_info:GetItem("RemoveAndUnloadAsset"):SetEnabled(not unused and unit ~= nil)
    self._unit_info:GetItem("Remove"):SetEnabled(not unused and unit ~= nil)
    self._unit_info:GetItem("UnloadAsset"):SetEnabled((unused or loaded_from_package) and unit and self._assets_units[unit])
    self._unit_info:AlignItems(true)
end

function AssetsManagerDialog:add_package(package)
    self:check_data()
    local project = BLE.MapProject
    local level_packages = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
    table.insert(level_packages, package)
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
    if PackageManager:package_exists(package.."_init") and not PackageManager:loaded(package.."_init") then
        PackageManager:load(package.."_init")
    end
    if PackageManager:package_exists(package) and not PackageManager:loaded(package) then
        PackageManager:load(package)
    else
        BLE:log("[Warning] Something went wrong in AssetsManagerDialog:add_package_dialog")
    end
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
    project:save_main_xml(self._tbl._data)
    project:reload_mod(self._tbl._data.name)
    self:reload()
end

function AssetsManagerDialog:all_ok_dialog()
    local status = self._unit_info:GetItem("AssetsManagerStatus")
    if status and not status:Visible() then
        local opt = {title = "Hooray!", message = "All units are now loaded!", force = true}
        if Global.editor_safe_mode then
            opt.message = opt.message .. " Load to normal mode?"
            BLE.Utils:QuickDialog(opt, {{"Yes", function()
                Global.editor_safe_mode = nil
                managers.game_play_central:restart_the_game()
            end}})
        else
            BLE.Dialog:Show(opt)
        end        
    end
end

function AssetsManagerDialog:add_package_dialog()
    local packages = {}
    local level_packages = BLE.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
    for name in pairs(BLE.DBPackages) do
        if not table.contains(level_packages, name) and not name:begins("all_") and not name:ends("_init") then
            local size = BLE.Utils:GetPackageSize(name)
            table.insert(packages, {package = name, name = size and string.format("%s(%.2fmb)", name, size) or name, package_size = size})
        end
    end
    table.sort(packages, function(a,b)
        if not a.package_size then
            return false
        end
        if not b.package_size then
            return true
        end
        return a.package_size < b.package_size
    end)
    BLE.ListDialog:Show({
        list = packages,
        force = true,
        callback = function(item)
            self:add_package(item.package)
            if not ctrl() then
                BLE.ListDialog:hide()
            end
        end
    })
    self:reload()
end

function AssetsManagerDialog:remove_package(package, item)
    BLE.Utils:YesNoQuestion("This will remove the package from your level(this will not unload the package if there's a spawned unit that is loaded by the package)", function()
        local project = BLE.MapProject
        local packages = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
        for i, pkg in ipairs(packages) do
            if pkg == package then
                table.remove(packages, i)
                break
            end
        end
        local p_units = BLE.DBPackages[package].units
        local can_remove = p_units ~= nil
        if can_remove then
            for k, unit in pairs(World:find_units_quick("all")) do
                local ud = unit:unit_data()
                if ud and p_units[ud.name] then
                    can_remove = false
                    break
                end
            end
        end
        if can_remove then
            managers.worlddefinition:_unload_package(package.."_init")
            managers.worlddefinition:_unload_package(package)
        end
        item:Destroy()
        project:save_main_xml(self._tbl._data)
        self:reload()
    end)
end

function AssetsManagerDialog:reload()
    self:load_units_from_assets()
    self:load_packages()
    self:load_units()
    local selected = self._tbl._selected
    self:set_unit_selected()
    self:set_unit_selected(nil, selected)
    self._menu:AlignItems(true)
end

function AssetsManagerDialog:hide(yes)
    self._unit_info:SetVisible(false)
    return AssetsManagerDialog.super.hide(self, yes)
end