AssetsManagerDialog = AssetsManagerDialog or class(MenuDialog)
AssetsManagerDialog.type_name = "AssetsManagerDialog"
AssetsManagerDialog._no_reshaping_menu = true
AssetsManagerDialog.ImportHelp = [[
This will search for dependencies that the unit requires in order to load.
Any missing dependency from your extract directory will fail the load. So be sure your extract is not outdated.
After pressing export please wait until you see another dialog that will confirm that the export was complete.
]]

local ADD = "add"
local UNIT_LOAD = "unit_load"
local UNIT = "unit"

function AssetsManagerDialog:init(params, menu)
    if self.type_name == AssetsManagerDialog.type_name then
        params = params and clone(params) or {}
	end
	params.scrollbar = false
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
    self._unready_assets = {}
    self._export_dialog = ExportDialog:new(BLE._dialogs_opt)
end

function AssetsManagerDialog:_Show()
    if not self.super._Show(self, {yes = false}) then
        return
    end
    self._params = nil
    self._assets = {unit = {}}
    self._missing_assets = {unit = {}}
    local btn = self:Button("Close", ClassClbk(self, "hide", true), {position = "Bottom", count_height = true})
    local group_h = (self._menu:Height() / 2) - 24
    local packages = self:DivGroup("Packages", {h = group_h - (btn:Height() + 8), auto_height = false, scrollbar = true})
    local units = self:DivGroup("Assets", {h = group_h, auto_height = false, auto_align = false, scrollbar = true})
    local utoolbar = units:GetToolbar()
    local ptoolbar = packages:GetToolbar()
    ptoolbar:SButton("Add", ClassClbk(self, "add_package_dialog"), {text = "+"})
    local search_opt = {group = ptoolbar, w = 300, lines = 1, text = "Search", offset = 0, control_slice = 0.8, highlight_color = false}
    self:TextBox("Search", ClassClbk(BLE.Utils, "FilterList", "packages"), "", search_opt)
    search_opt.group = utoolbar
    self:TextBox("Search2", ClassClbk(BLE.Utils, "FilterList", "assets"), "", search_opt)

    self:Divider("AssetsManagerStatus", {
        text = "(!) A unit or more are not loaded, you can decide to search for a package that contains(most) of the unloaded units(for leftover units you can repeat this process)",
        group = self._unit_info,
        visible = false,
        color = false,
    })
    self:Button("FixBySearchingPackages", ClassClbk(self, "find_packages", false), {group = self._unit_info})
    self:Button("FixByLoadingFromExtract", ClassClbk(self, "load_all_from_extract_dialog"), {group = self._unit_info})
    self:Button("RemoveAndUnloadUnusedAssets", ClassClbk(self, "remove_unused_units_from_map", false), {group = self._unit_info})
    self:Button("PackageReport", ClassClbk(self, "package_report"), {group = self._unit_info})
    self:Divider("UnitInfoTitle", {text = "Unit Inspection", group = self._unit_info})
    self:Divider("UnitInfo", {text = "None Selected.", color = false, group = self._unit_info})
    local actions = self:DivGroup("Actions", {group = self._unit_info})
    self:Button("FindPackage", ClassClbk(self, "find_package", false, false, false), {offset = 0, group = actions, enabled = false})
    self:Button("LoadFromExtract", ClassClbk(self, "load_from_extract_dialog", false), {offset = 0, group = actions, enabled = false, visible = FileIO:Exists(BLE.ExtractDirectory)})

    self:Button("RemoveAndUnloadAsset", ClassClbk(self, "remove_unit_from_map", true, false), {offset = 0, group = actions, enabled = false})
    self:Button("Remove", ClassClbk(self, "remove_unit_from_map", false, false), {offset = 0, group = actions, enabled = false})
    self:Button("UnloadAsset", ClassClbk(self, "unload_asset", false, false), {offset = 0, group = actions, enabled = false})

    self:reload()
end

function AssetsManagerDialog:load_assets()
    self._assets = {unit = {}}
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    if data then
        local level = project:get_level_by_id(data, Global.game_settings.level_id)
        local add_path = level.add.file or Path:Combine(level.include.directory, "add.xml")
        local add = project:read_xml(add_path)
        if add then
			for _, node in pairs(add) do
				if type(node) == "table" then
					local type = node.type or node._meta
					if node._meta == "unit_load" then
						type = UNIT
					end
					local name = node.path or node.name
					if type and name then
						self._assets[type] = self._assets[type] or {}
						self._assets[type][name] = true
					end
				end
            end
        end
    end
end

function AssetsManagerDialog:asset_ready(type, asset)
	return self._unready_assets[type] == nil or self._unready_assets[type][asset] == nil
end

function AssetsManagerDialog:show_assets()
    local units = self:GetItem("Assets")
    if not units then
        return
    end
    units:ClearItems("assets")
    self._missing_assets = {unit = {}}
    local add
    local project = BLE.MapProject
    local mod = project:current_mod()
    if self._tbl._data then
        add = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).add
    end
    local panic
	local new_asset = function(asset, type, times)
		local ready = self:asset_ready(type, asset)
        local loaded = self:is_asset_loaded(asset, type)
        if not loaded then
            if add then
                loaded = self._assets[type] and self._assets[type][asset] ~= nil
            end
			if not loaded then
				self._missing_assets[type] = self._missing_assets[type] or {}
                self._missing_assets[type][asset] = true
                panic = true
            end
        end
        local unused = type == UNIT and times == 0
        local color = not ready and Color.cyan or not loaded and Color.red or (unused and Color.yellow) or nil
        self:Button(asset, callback(self, self, "set_unit_selected"), {
			asset_type = type,
            group = units,
            text = asset.."."..type.."("..(ready and times or "Copying")..")",
			label = "assets",
			disabled_alpha = 0.8,
			index = (not loaded or unused) and 1 or nil,
			enabled = ready,
            background_color = color and color:with_alpha(0.4),
        })
	end
	
    for unit, times in pairs(managers.worlddefinition._all_names) do
        new_asset(unit, UNIT, times)
	end
	
	for type, assets in pairs(self._assets) do
		for name, _ in pairs(assets) do
			if type ~= UNIT or not managers.worlddefinition._all_names[name] then
				new_asset(name, type, 0)
			end
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

function AssetsManagerDialog:show_packages()
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    self._tbl._data = data
    self._current_level = BLE.MapProject:get_level_by_id(self._tbl._data, Global.game_settings.level_id)

    local packages = self:GetItem("Packages", true)
    if not packages then
        return
    end
    packages:ClearItems("packages")
    if self._tbl._data then
        local level = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id)
        if level.packages then
            for i, package in pairs(level.packages) do
                local custom = CustomPackageManager.custom_packages[package:key()] ~= nil
                local size = not custom and BLE.Utils:GetPackageSize(package)
                if size or custom then
                    local text = custom and string.format("%s(custom)", package, size) or string.format("%s(%.2fmb)", package, size)
                    local pkg = self:Divider(package, {text = text, group = packages, label = "packages"})
                    pkg:ImgButton("RemovePackage", ClassClbk(self, "remove_package", package), nil, {184, 2, 48, 48})
                end
            end
        end
    end
end

function AssetsManagerDialog:load_all_from_extract_dialog()
   self:load_from_extract_dialog(self._missing_assets)
end

function AssetsManagerDialog:load_from_extract_dialog(assets)
	if not assets and not self._tbl._selected then
		return
	end
    self._export_dialog:Show({
        force = true,
        message = self.ImportHelp,
        assets_manager = self,
        assets = assets or {[self._tbl._selected.asset_type] = {[self._tbl._selected.name] = true}}
    })
end

function AssetsManagerDialog:find_package(path, typ, dontask, clbk)
    function find_package()
		local items = {}

        for _, pkg in pairs(BLE.Utils:GetPackages(path or self._tbl._selected.name, typ or self._tbl._selected.asset_type, true)) do
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
        BLE.Utils:YesNoQuestion("This will search for packages that contain this asset, it's recommended to choose the smallest one so your level will load faster", function()
            find_package()
        end)
    else
        find_package()
    end
end

function AssetsManagerDialog:clean_add_asset_tbl(tbl)
    local new_tbl = {}
    for k, v in pairs(tbl) do
        if not tonumber(k) and type(v) ~= "table" then
            new_tbl[k] = v
        end
    end

    for _, asset in pairs(tbl) do
        if type(asset) == "table" and asset._meta then
            local exists
            for _, v in ipairs(new_tbl) do
                if type(v) == "table" and asset._meta == v._meta and asset.path == v.path then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(new_tbl, asset)
            end
        end
    end
    return new_tbl
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

    for k,v in ipairs(add) do
        if type(v) == "table" and v._meta then
            local exists
            for _, tbl in pairs(new_add) do
                if type(tbl) == "table" and tbl._meta == v._meta and ((tbl.path and tbl.path == v.path) or (tbl.name and tbl.name == v.name)) then
                    exists = true
                    break
                end
            end
            if not exists then
                if not v.path or FileIO:Exists(Path:Combine(mod.ModPath, new_add.directory, v.path) ..".".. (v.type or v._meta)) then
                    table.insert(new_add, self:clean_add_asset_tbl(v))
                end
            end
        end
    end
    project:save_xml(add_path, new_add)
end

function AssetsManagerDialog:load_from_extract(missing_assets, exclude, dontask)
    missing_assets = missing_assets or self._missing_assets
    local config = {}
	local failed_all = false
	for ext, assets in pairs(missing_assets) do
		for asset in pairs(assets) do
			local cfg = BLE.Utils.Export:GetDependencies(ext, asset, true, exclude)
			if cfg then
				table.insert(config, table.merge({_meta = ADD, type = ext, path = asset}, cfg))
			else
				failed_all = true
			end	
		end
	end
    self:_load_from_extract(config, dontask, failed_all)
end

function AssetsManagerDialog:_load_from_extract(config, dontask, failed_all)
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
				if type(tbl) == "table" and tbl._meta == v._meta and (tbl.name and tbl.name == v.path or tbl.path and tbl.path == v.path) then
                    exists = true
                    break
                end
            end
            local clean = self:clean_add_asset_tbl(v)
            if not exists then
                table.insert(add, clean)
                table.insert(to_copy, clean)
            end
        end
        local function save()
            local assets_dir = Path:Combine(mod.ModPath, add.directory or "")
            local copy_data = {}
            for _, unit_load in pairs(to_copy) do
                if type(unit_load) == "table" then
                    for _, asset in pairs(unit_load) do
						if type(asset) == "table" and asset.path then
							local type = asset._meta
							local name = asset.path

                            local path = name.."."..type
                            local to_path = Path:Combine(assets_dir, path)
                            table.insert(copy_data, {asset.extract_real_path, to_path})
                            asset.extract_real_path = nil
                            local dir = Path:GetDirectory(to_path)
                            if not FileIO:Exists(dir) then
                                FileIO:MakeDir(dir)
                            end
							self._unready_assets[type] = self._unready_assets[type] or {}
                            self._unready_assets[type][name] = true
                        end        
                    end
                end
            end
            project:save_xml(add_path, add)
            if #copy_data > 0 then
                FileIO:CopyFilesToAsync(copy_data, function(success)
                    if success then
                        CustomPackageManager:LoadPackageConfig(assets_dir, to_copy, nil, true)
                        if failed_all then
                            BLE.Utils:Notify("Info", "Copied some assets, some have failed because not all dependencies exist in the extract path")
                        else
                            BLE.Utils:Notify("Info", "Copied assets successfully")
						end
						for type, assets in pairs(self._unready_assets) do
							for asset, _ in pairs(assets) do
								if type == UNIT then
									BLE.Utils.allowed_units[asset] = true
								end
								assets[asset] = nil
							end
						end
         
                        self:reload()
                    end
                end)
			elseif failed_all then
                BLE.Utils:Notify("Info", "No assets to copy, failed to export an asset or more.")
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

function AssetsManagerDialog:find_packages(missing_assets, clbk)
    missing_assets = missing_assets or self._missing_assets
    local packages = {}
    for name, package in pairs(BLE.DBPackages) do
        if package.unit then
            for typ, assets in pairs(package) do
                for asset, _ in pairs(assets) do
                    if missing_assets[typ] and missing_assets[typ][asset] == true then
                        packages[name] = packages[name] or {}
                        table.insert(packages[name], asset)
                    end
                end
            end
        end
    end
    local items = {}
    local missing_amount = 0
    for typ, assets in pairs(missing_assets) do
        for asset, _ in pairs(assets) do
            missing_amount = missing_amount + 1
        end
    end
    for name, package in pairs(packages) do
        local size = BLE.Utils:GetPackageSize(name)
        if size then
            table.insert(items, {
                name = string.format("%s has %s/%s of the missing assets(%.2fmb)", name, #package, missing_amount, size),
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
    BLE.Utils:YesNoQuestion("This will remove any unused units from your map and remove them from your map assets completely", function()
        for unit, _ in pairs(self._assets.unit) do
            if not managers.worlddefinition._all_names[unit] then
                self:remove_unit_from_map(true, unit, "unit")
            end
        end
        self:reload()
        self:set_unit_selected()
    end)
end

function AssetsManagerDialog:package_report()
    local packages = {}
    for name, package in pairs(BLE.DBPackages) do
        if not name:begins("all_") and not name:ends("_init") then
            if package.unit and not name:find("instances") and not name:find("only") then
                table.insert(packages, {package = name, name = name})
            end
        end
    end
    BLE.ListDialog:Show({
        list = packages,
        force = true,
        callback = function(item)
            BLE.Utils:YesNoQuestion("This will spawn all selected package units in your level. This may hang the game!", function()
                self:add_package(item.package)
                self:_make_package_report(item.package)
                BLE.ListDialog:hide()
            end)
        end
    })
    self:reload()
end

function AssetsManagerDialog:_make_package_report(package)
    local pos = Vector3()
	local rot = Rotation()
	local i = 0
	local prow = 40
	local y_pos = 0
	local c_rad = 0
	local row_units = {}
	local max_rad = 0
	local removed = {}
    for unit_name in pairs(BLE.DBPackages[package].unit) do
        local unit = managers.editor:SpawnUnit(unit_name)
        if alive(unit) then
            local bsr = unit:bounding_sphere_radius() * 2

            i = i + 1

            managers.editor:set_unit_position(unit, unit:position() + Vector3(bsr / 2, y_pos, 0), Rotation())

            pos = pos + Vector3(bsr, 0, 0)

            
            if math.mod(i, prow) == 0 then
                c_rad = bsr * 2

                max_rad = 0
                y_pos = y_pos + c_rad
                pos = Vector3()
                row_units = {}
            end
        end
    end
end

--TODO: is save forced if asset is removed from add.xml?
function AssetsManagerDialog:remove_unit_from_map(remove_asset, name, type)
    local ask = not name
	name = name or self._tbl._selected.name
	type = type or self._tbl._selected.asset_type

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
        if self._assets[type] and self._assets[type][name] and remove_asset == true then
            self:unload_asset(type, name, true)
        end
        if ask then
            managers.editor:m().opt:save()
            self:reload()
            self:set_unit_selected()
        end
    end
	if ask then
        BLE.Utils:YesNoQuestion(
            "This will remove the asset, if it's a unit it will delete all units that are spawned(except the ones spawned by an instance)",
            remove
        )
    else
        remove()
    end
end

function AssetsManagerDialog:unload_asset(typ, name, no_dialog)
	name = name or self._tbl._selected.name
	typ = typ or self._tbl._selected.asset_type

    local function unload()
        local project = BLE.MapProject
        local mod, data = project:get_mod_and_config()
        if data then
            local level = project:current_level(data)
            level.add = level.add or {}
            local add_path = level.add.file or Path:Combine(level.include.directory, "add.xml")
			local add = project:read_xml(add_path)
			
			if add then

				local function delete_asset(deleting_node, deleting_asset)
					deleting_asset = deleting_asset or deleting_node
					local used
					for _, node in pairs(add) do
						if type(node) == "table" and node ~= deleting_node then
							for _, asset in pairs(node) do
								if type(asset) == "table" and asset._meta == deleting_asset._meta and asset.path == deleting_asset.path then
									used = true
									break
								end
							end
						end
					end
					if not used then
						local file = Path:Combine(mod.ModPath, add.directory, deleting_asset.path.."."..deleting_asset._meta)
						if FileIO:Exists(file) then
							FileIO:Delete(file)
						end
					end
				end

				for k, node in pairs(add) do
					if type(node) == "table" then
						local path = node.path or node.name
						local asset_type = node.type or node._meta						
						prnt("check", path, name, asset_type, typ)
						if path == name and asset_type == typ then
							--TODO: check multiple maps if the asset is actually used.
							if node._meta == UNIT_LOAD or node._meta == ADD then
								for _, asset in pairs(node) do
									if type(asset) == "table" then
										delete_asset(node, asset)
									end
								end
							else
								delete_asset(node)
							end
							table.remove_key(add, k)
							if asset_type == UNIT then
								BLE.Utils.allowed_units[name] = nil
							end
							break
						end
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
	local asset
	local type
    if self._tbl._selected then
		asset = self._tbl._selected.name
		type = self._tbl._selected.asset_type
        local project = BLE.MapProject
        local load_from
        for _, pkg in pairs(self:get_packages_of_asset(asset, type, true)) do
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
        if self._assets[type] and self._assets[type][asset] then
            load_from = (load_from or "") .. "\n".."Map Assets"
            if type == UNIT and not managers.worlddefinition._all_names[asset] then
                load_from = load_from .. "\n" .. "| Warning: Unused!"
                unused = true
            end
        end
        self._unit_info:GetItem("UnitInfo"):SetText("| Asset:\n"..BLE.Utils:ShortPath(asset.."."..type, 2) .. "\n| " .. (load_from and "Loaded From:"..load_from or "Unloaded, please load the asset using one of the methods below"))
    else
        self._unit_info:GetItem("UnitInfo"):SetText("None Selected.")
    end
    self._unit_info:GetItem("FindPackage"):SetEnabled(asset ~= nil)
    self._unit_info:GetItem("LoadFromExtract"):SetEnabled(asset ~= nil)
    self._unit_info:GetItem("RemoveAndUnloadAsset"):SetEnabled(not unused and asset ~= nil)
    self._unit_info:GetItem("Remove"):SetEnabled(not unused and asset ~= nil)
    self._unit_info:GetItem("UnloadAsset"):SetEnabled((unused or loaded_from_package) and asset and type and self._assets[type] and self._assets[type][asset])
    self._unit_info:AlignItems(true)
end

function AssetsManagerDialog:add_package(package)
    self:check_data()
    local project = BLE.MapProject
    local level_packages = project:get_level_by_id(self._tbl._data, Global.game_settings.level_id).packages
    table.insert(level_packages, package)
    PackageManager:set_resource_loaded_clbk(Idstring(UNIT), nil)
    if PackageManager:package_exists(package.."_init") and not PackageManager:loaded(package.."_init") then
        PackageManager:load(package.."_init")
    end
    if PackageManager:package_exists(package) and not PackageManager:loaded(package) then
        PackageManager:load(package)
    else
        BLE:log("[Warning] Something went wrong in AssetsManagerDialog:add_package_dialog")
    end
    PackageManager:set_resource_loaded_clbk(Idstring(UNIT), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
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
            table.insert(packages, {package = name, name = name})
        end
    end
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
    self:load_assets()
    self:show_packages()
    self:show_assets()
    local selected = self._tbl._selected
    self:set_unit_selected()
    self:set_unit_selected(nil, selected)
    self._menu:AlignItems(true)
end

function AssetsManagerDialog:hide(yes)
    self._unit_info:SetVisible(false)
    return AssetsManagerDialog.super.hide(self, yes)
end