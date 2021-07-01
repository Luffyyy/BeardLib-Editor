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
    self._exporter = BLE.Utils.Export:new()
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
            if alive(self._unit_info) then
                item:SetPositionByString("Center")
                item:Panel():move(-self._unit_info:Width() / 2)
            end
        end,
        auto_height = false,
        items_size = 20,
    }, params), menu)
    self._unit_info:SetPosition(function(item)
        if alive(self._menu) then
            item:Panel():set_lefttop(self._menu:Panel():righttop())
        end
    end)
    self._menus = {self._unit_info}
    ItemExt:add_funcs(self)
    self._unready_assets = {}
    self._export_dialog = ExportDialog:new(BLE._dialogs_opt)
end

function AssetsManagerDialog:Destroy()
    AssetsManagerDialog.super.Destroy(self)
    self._export_dialog:Destroy()
end

function AssetsManagerDialog:_Show()
    if not self.super._Show(self, {yes = false}) then
        return
    end
    self._params = nil
    self._assets = {unit = {}}
    self._missing_assets = {unit = {}}
    local group_h = (self._menu:Height() / 2) - 12
    local btn = self:button("Close", ClassClbk(self, "hide", true))
    local packages = self:divgroup("Packages", {h = group_h - (btn:Height() + 8), auto_height = false, scrollbar = true})
    local units = self:divgroup("Assets", {h = group_h, auto_height = false, auto_align = false, scrollbar = true})
    btn:SetIndex(4)
    local utoolbar = units:GetToolbar()
    local ptoolbar = packages:GetToolbar()
    ptoolbar:tb_btn("Add", ClassClbk(self, "add_package_dialog"), {text = "+"})
    local search_opt = {w = 300, lines = 1, text = "Search", offset = 0, control_slice = 0.8, highlight_color = false}
    ptoolbar:textbox("Search", ClassClbk(BLE.Utils, "FilterList", "packages"), "", search_opt)
    utoolbar:textbox("Search2", ClassClbk(BLE.Utils, "FilterList", "assets"), "", search_opt)

    self._unit_info:divider("AssetsManagerStatus", {
        text = "(!) One or more units are missing, you can decide to search for a package that contains(most) of the unloaded units (for leftover units you can repeat this process)",
        visible = false,
        color = false,
    })
    self._unit_info:button("FixBySearchingPackages", ClassClbk(self, "find_packages", false))
    self._unit_info:button("FixByLoadingFromDatabase", ClassClbk(self, "load_all_from_extract_dialog"))
    self._unit_info:button("RemoveAndUnloadUnusedAssets", ClassClbk(self, "remove_unused_units_from_map", false))
    self._unit_info:button("PackageReport", ClassClbk(self, "package_report"))
    self._unit_info:button("ScanAssetsDirectory", ClassClbk(self, "scan_assets"))
    self._unit_info:button("CleanAddXml", ClassClbk(self, "clean_add_xml"))
    self._inspect = self._unit_info:divgroup("UnitInfoTitle", {text = "Unit Inspection"})
    local actions = self._unit_info:divgroup("Actions")
    actions:button("FindPackage", ClassClbk(self, "find_package", false, false, false), {offset = 0, visible = false})
    actions:button("LoadFromDatabase", ClassClbk(self, "load_from_db_dialog", false, false), {offset = 0, visible = false})

    actions:button("RemoveAndUnloadAsset", ClassClbk(self, "remove_unit_from_map", true, false, false), {offset = 0, visible = false})
    actions:button("Remove", ClassClbk(self, "remove_unit_from_map", false, false, false), {offset = 0, visible = false})

    self:reload()
end

function AssetsManagerDialog:load_assets()
    self._assets = {unit = {}}
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    if data then
        local level = project:current_level()
        local add = project:read_xml(level._add_path)
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
						self._assets[type][name] = node
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
        add = self._current_level.add
    end
    local panic
	local new_asset = function(asset, type, times)
		local ready = self:asset_ready(type, asset)
        local loaded = self:is_asset_loaded(type, asset)
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
        units:button(asset, ClassClbk(self, "set_unit_selected"), {
			asset_type = type,
            text = asset.."."..type..(type == "unit" and "("..(ready and times or "Copying")..")" or ""),
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
    self._unit_info:GetItem("FixByLoadingFromDatabase"):SetVisible(panic)
    if panicked and not panic then
        self:all_ok_dialog()
    end
end

function AssetsManagerDialog:show_packages()
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    self._tbl._data = data

    local level = project:get_current_level_node(self._tbl._data)
    self._current_level = level

    local packages = self:GetItem("Packages", true)
    if not packages then
        return
    end
    packages:ClearItems("packages")
    if self._tbl._data then
        if level.packages then
            for i, package in pairs(level.packages) do
                local custom = CustomPackageManager.custom_packages[package:key()] ~= nil
                local size = not custom and BLE.Utils:GetPackageSize(package)
                if size or custom then
                    local text = custom and string.format("%s(custom)", package, size) or string.format("%s(%.3fmb)", package, size)
                    local pkg = packages:divider(package, {text = text, label = "packages"})
                    pkg:tb_imgbtn("RemovePackage", ClassClbk(self, "remove_package", package), nil, BLE.Utils.EditorIcons.cross)
                end
            end
        end
    end
end

function AssetsManagerDialog:load_all_from_extract_dialog()
   self:load_from_db_dialog(self._missing_assets)
end

function AssetsManagerDialog:load_from_db_dialog(assets, clbk)
	if not assets and not self._tbl._selected then
		return
	end
    self._export_dialog:Show({
        force = true,
        message = self.ImportHelp,
        assets_manager = self,
        done_clbk = clbk,
        assets = assets or {[self._tbl._selected.asset_type] = {[self._tbl._selected.name] = true}}
    })
end

function AssetsManagerDialog:find_package(path, typ, dontask, clbk)
    local function find_package()
		local items = {}

        for _, pkg in pairs(BLE.Utils:GetPackages(path or self._tbl._selected.name, typ or self._tbl._selected.asset_type, true)) do
            local text = pkg.custom and string.format("%s(custom)", pkg.name) or string.format("%s(%.3fmb)", pkg.name, pkg.package_size)
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
    local level = project:current_level()
    local add = project:read_xml(level._add_path) or {_meta = "add", directory = "assets"}
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
                if v.from_db or v.path or FileIO:Exists(Path:Combine(mod.ModPath, new_add.directory, v.path) ..".".. (v.type or v._meta)) then
                    table.insert(new_add, self:clean_add_asset_tbl(v))
                end
            end
        end
    end
    project:save_xml(level._add_path, new_add)
end

function AssetsManagerDialog:db_has_asset(ext, asset)
    return blt.asset_db.has_file(asset, ext)
end

function AssetsManagerDialog:quick_load_from_db(ext, asset, clbk)
    self:load_from_db({[ext] = {[asset] = true}}, nil, false, true, clbk)
end

function AssetsManagerDialog:load_from_db(missing_assets, exclude, inc_in_proj, dontask, clbk)
    missing_assets = missing_assets or self._missing_assets
    local config = {}
	local failed_all = false
	for ext, assets in pairs(missing_assets) do
		for asset in pairs(assets) do
			local cfg = self._exporter:GetDependencies(ext, asset, true, exclude)
			if cfg then
				table.insert(config, table.merge({_meta = ADD, type = ext, path = asset, from_db = not inc_in_proj}, cfg))
			else
				failed_all = true
			end
		end
    end
    self:_load_from_db(config, inc_in_proj, dontask, failed_all, clbk)
end

function AssetsManagerDialog:merge_add_configs(config, config_to_merge, clbk)
    for _, v in pairs(config_to_merge) do
        local exists = false
        for _, tbl in pairs(config) do
            if type(tbl) == "table" and tbl._meta == v._meta and (tbl.name and tbl.name == v.path or tbl.path and tbl.path == v.path) then
                exists = true
                break
            end
        end
        local clean = self:clean_add_asset_tbl(v)
        if not exists then
            table.insert(config, clean)
        end
        if clbk then clbk(clean) end
    end
end

function AssetsManagerDialog:_load_from_db(config, inc_in_proj, dontask, failed_all, clbk)
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    local to_copy = {}
    if data then
        local level = project:current_level()
        local add = project:read_xml(level._add_path) or {_meta = "add", directory = "assets"}
        self:merge_add_configs(add, config, function(clean)
            if inc_in_proj then
                table.insert(to_copy, clean)
            else
                BLE.DBPackages.map_assets = BLE.DBPackages.map_assets or {}
                local package = BLE.DBPackages.map_assets
                for _, asset in pairs(config) do
                    if type(asset) == "table" then
                        if asset._meta == UNIT then
                            package.unit = package.unit or {}
                            package.unit[asset.path] = true
                        elseif asset._meta == ADD or asset._meta == UNIT_LOAD then
                            local typ = asset.type or "unit"
                            package[typ] = package[typ] or {}
                            package[typ][asset.path] = true
                        end
                    end
                end
            end
        end)
        local function save()
            local assets_dir = Path:CombineDir(mod.ModPath, add.directory or "")
            if not inc_in_proj then
                project:save_xml(level._add_path, add)
                CustomPackageManager:LoadPackageConfig(assets_dir, add, true)
                self:reload()
                if clbk then
                    clbk()
                end
                return
            end
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
            project:save_xml(level._add_path, add)
            if #copy_data > 0 then
                FileIO:CopyFilesToAsync(copy_data, function(success)
                    if success then
                        CustomPackageManager:LoadPackageConfig(assets_dir, to_copy, true)
                        if failed_all then
                            BLE.Utils:Notify("Info", "Copied some assets, some have failed because not all dependencies exist in the extract path")
                        elseif not clbk then
                            BLE.Utils:Notify("Info", "Copied assets successfully")
						end
						for type, assets in pairs(self._unready_assets) do
							for asset, _ in pairs(assets) do
								if type == UNIT then
                                    BLE.DBPackages.map_assets.unit = BLE.DBPackages.map_assets.unit or {}
                                    BLE.DBPackages.map_assets.unit[asset] = true
								end
								assets[asset] = nil
							end
						end

                        self:reload()

                        if clbk then
                            clbk()
                        end
                    end
                end)
			elseif failed_all then
                BLE.Utils:Notify("Info", "No assets to copy, failed to export an asset or more.")
            else
                if clbk then
                    clbk()
                else
                    BLE.Utils:Notify("Info", "No assets to copy")
                end
            end
        end
        if not dontask then
            local warn = "This will add the files to your map assets (add.xml) proceed?"
            if inc_in_proj then
                warn = "This will copy the required files from your extract directory and add the files to your map assets (add.xml) proceed?"
            end
            BLE.Utils:YesNoQuestion(warn, save, function()
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
                name = string.format("%s has %s/%s of the missing assets(%.3fmb)", name, #package, missing_amount, size),
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

function AssetsManagerDialog:scan_assets()
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    if data then
        local level = project:current_level()
        local add = project:read_xml(level._add_path) or {_meta = "add", directory = "assets"}
        local assets_dir = Path:CombineDir(mod.ModPath, add.directory or "")
        local scanner = BLE.Utils.Export:new({
            assets_dir = assets_dir,
            fallback_to_db_assets = true,
            check_path_before_insert = true,
            return_on_missing = false,
            pack_extract_path = false
        })

        self:merge_add_configs(add, self:scan_dir(scanner, scanner.assets_dir))
        project:save_xml(level._add_path, add)
    end
end

function AssetsManagerDialog:scan_dir(scanner, path, big_path, addxml)
    big_path = big_path or path
    addxml = addxml or {}
    for _, file in pairs(FileIO:GetFiles(path)) do
		if file:ends(".unit") then
			local file_path = Path:Normalize(Path:Combine(path:gsub(big_path, ""), file))
			local splt = file_path:split("%.")
			local add = scanner:GetDependencies(splt[2], splt[1])
            if add then
                add._meta = "add"
                add.path = splt[1]
                add.type = "unit"
                table.insert(addxml, add)
            end
        end
    end
    for _, folder in pairs(FileIO:GetFolders(path)) do
        self:scan_dir(scanner, Path:Combine(path, folder), big_path, addxml)
    end
    return addxml
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

            
            if math.fmod(i, prow) == 0 then
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
        if type == "unit" then
            for k, unit in pairs(managers.worlddefinition._all_units) do
                local ud = alive(unit) and unit:unit_data()
                if ud and not ud.instance and ud.name == name then
                    managers.editor:DeleteUnit(unit, false, false)
                end
            end
            self:GetPart("select"):reload_menu("unit")
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
            local current_level = project:current_level()
			local current_add = project:read_xml(current_level._add_path)

            local add_xmls = {}
            project:for_each_level(data, function(level)
                table.insert(add_xmls, project:read_xml(level._add_path))
            end)

			if current_add then
				local function delete_asset(deleting_node, deleting_asset)
					deleting_asset = deleting_asset or deleting_node
                    local used
                    --Check all present maps in the project so we don't delete it for a different level.
                    for _, add in pairs(add_xmls) do
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
                    end
					if not used then
						local file = Path:Combine(mod.ModPath, current_add.directory, deleting_asset.path.."."..deleting_asset._meta)
						if FileIO:Exists(file) then
							FileIO:Delete(file)
						end
					end
				end

				for k, node in pairs(current_add) do
					if type(node) == "table" then
						local path = node.path or node.name
						local asset_type = node.type or node._meta
						if path == name and asset_type == typ then
							if node._meta == UNIT_LOAD or node._meta == ADD then
								for _, asset in pairs(node) do
									if type(asset) == "table" then
										delete_asset(node, asset)
									end
								end
							else
								delete_asset(node)
							end
							table.remove_key(current_add, k)
							if asset_type == UNIT then
                                BLE.DBPackages.map_assets.unit[name] = nil
							end
							break
						end
					end
                end
            end
            project:save_xml(current_level._add_path, current_add)
            FileIO:DeleteEmptyFolders(Path:Combine(mod.ModPath, current_add.directory))
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
        self._current_level = BLE.MapProject:get_current_level_node(self._tbl._data)
    end
end

function AssetsManagerDialog:get_level_packages()
    self:check_data()
    local packages = {map_assets = BLE.DBPackages.map_assets}
    for _, package in ipairs(table.merge(clone(BLE.ConstPackages), clone(self._current_level.packages or {}))) do
        packages[package] = BLE.DBPackages[package]
    end
    return packages
end

function AssetsManagerDialog:is_asset_loaded(type, asset)
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
    local unused
	local asset
	local type
    local file
    local from_db
    self._inspect:ClearItems()
    if self._tbl._selected then
		asset = self._tbl._selected.name
		type = self._tbl._selected.asset_type
        local load_from
        for _, pkg in pairs(self:get_packages_of_asset(asset, type, true)) do
            load_from = load_from or ""
            local name = pkg.name
            if name:sub(1, 6) == "levels" then
                name = BLE.Utils:ShortPath(name, 3)
            end
            local pkg_s = pkg.custom and string.format("%s(custom)", name) or string.format("%s(%.3fmb)", name, pkg.package_size)
            load_from = load_from.."\n"..pkg_s
        end
        if BLE.Utils.core_units[asset] then
            load_from = "Core Assets"
        end
        file = self._assets[type] and self._assets[type][asset] or nil
        from_db = file and file.from_db or false
        if file then
            load_from = (load_from or "") .. "\n"..(file.from_db and "Database" or "Map Assets")
            if type == UNIT and not managers.worlddefinition._all_names[asset] then
                unused = true
            end
        end
        self._inspect:divider("Asset: ".. tostring(BLE.Utils:ShortPath(asset.."."..type, 2)))
        self._inspect:divider("LoadedFrom", {text = "Loaded From: "..(load_from or "Unloaded, please load the asset using one of the methods below")})
        if unused then
            self._inspect:divider("Warning: Unused!")
        end
    else
        self._inspect:divider("NoAsset", {text = "No Asset Selected."})
    end
    local has_in_db = asset and DB:has(type:id(), asset:id()) or false
    self._unit_info:GetItem("FindPackage"):SetVisible(has_in_db)
    self._unit_info:GetItem("LoadFromDatabase"):SetVisible(not from_db and has_in_db)
    self._unit_info:GetItem("RemoveAndUnloadAsset"):SetVisible(unused or type ~= "unit" and asset ~= nil)
    self._unit_info:GetItem("Remove"):SetVisible(not unused and asset ~= nil and type == "unit")
    self._unit_info:AlignItems(true)
end

function AssetsManagerDialog:add_package(package)
    self:check_data()
    local project = BLE.MapProject
    local level = self._current_level
    level.packages = level.packages or {}
    table.insert(level.packages, package)
    PackageManager:set_resource_loaded_clbk(Idstring(UNIT), nil)
    if PackageManager:package_exists(package.."_init") and not PackageManager:loaded(package.."_init") then
        PackageManager:load(package.."_init")
    end
    if PackageManager:package_exists(package) and not PackageManager:loaded(package) then
        PackageManager:load(package)
    else
        BLE:log("[Warning] Something went wrong in AssetsManagerDialog:add_package_dialog")
    end
    PackageManager:set_resource_loaded_clbk(Idstring(UNIT), ClassClbk(managers.sequence, "clbk_pkg_manager_unit_loaded"))
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
                managers.game_play_central:restart_the_game()
                Global.editor_safe_mode = nil
            end}})
        else
            BLE.Dialog:Show(opt)
        end
    end
end

function AssetsManagerDialog:add_package_dialog()
    local packages = {}
    self._current_level.packages = self._current_level.packages or {}
    local level_packages = self._current_level.packages
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
        local packages = self._current_level.packages
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

function AssetsManagerDialog:GetPart(name)
    return managers.editor.parts[name]
end