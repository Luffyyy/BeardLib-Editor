---Editor for BeardLib AddFiles module.
---This class DOES NOT deal with actual file system. 
---We leave this job to the map makers, just place the assets in the directory you want and let the editor do the rest.
ProjectAddFilesModule = ProjectAddFilesModule or class(ProjectModuleEditor)
ProjectAddFilesModule.HAS_ID = false
ProjectEditor.EDITORS.AddFiles = ProjectAddFilesModule

--- @param menu Menu
--- @param data table
function ProjectAddFilesModule:build_menu(menu, data)
    local up = ClassClbk(self, "set_data_callback")
    menu:textbox("directory", up, data.directory)
    local buttons = menu:divgroup("Add", {align_method = "grid"})

    buttons:divider("FromDatabase")
    buttons:s_btn("AddUnit", ClassClbk(self, "add_file_db_dialog", "unit"), {help = "Adds a unit from database"})
    buttons:s_btn("AddAnimation", ClassClbk(self, "add_file_db_dialog", "animation"), {help = "Adds an animation from database"})
    buttons:s_btn("AddMaterialConfig", ClassClbk(self, "add_file_db_dialog", "material_config"), {help = "Adds a material config from database"})
    buttons:s_btn("AddEnvironment", ClassClbk(self, "add_file_db_dialog", "environment"), {help = "Adds an environment from database"})
    buttons:s_btn("AddSomethingElse", ClassClbk(self, "add_file_db_any_ext_dialog"), {help = "Adds a file from database"})

    buttons:divider("FromDisk")

    buttons:s_btn("AddSingleFile", ClassClbk(self, "add_file_dialog", false), {help = "Adds a single file without trying to scan for its dependencies"})
    buttons:s_btn("AddFileWithDependencies", ClassClbk(self, "add_file_dialog", true), {
        help = "Adds a file but scans its dependencies and adds them. If the dependency doesn't exist in the assets directory, but exists in the database, the database version will be picked"
    })
    buttons:s_btn("AddFolder", ClassClbk(self, "add_folder_dialog"))
    buttons:s_btn("AddFolderWithDependencies", ClassClbk(self, "add_folder_dialog", true))
    menu:divgroup("Files", {auto_align = false})
    self:load_files()
end

function ProjectAddFilesModule:load_files()
    local list = self._menu:GetItem('Files')
    list:ClearItems()
    for _, file in pairs(self._data) do
        if type(file) == "table" and file.path then
            local meta = file._meta
            local is_grouped = (meta == "add" or meta == "unit_load")
            local list_file = list:divider(file.path.."."..(is_grouped and file.type or meta)..(is_grouped and "[Has Dependencies]" or ""), {background_color = Color(0.1, 1, 1, 1)})
            list_file:tb_imgbtn("Delete", ClassClbk(self, "remove_file", file), "textures/editor_icons_df", BLE.Utils.EditorIcons["cross"], {highlight_color = Color.red})
        end
    end
    list:AlignItems(true)
end

function ProjectAddFilesModule:add_folder_dialog(search_deps)
    local assets_dir = Path:CombineDir(self._parent:get_dir(), self._data.directory or "assets")
    BLE.FBD:Show({
        folder_browser = true,
        where = assets_dir,
        folder_click = function(path)
            self:add_folder(path, search_deps)
            BLE.FBD:Hide()
        end
    })
end

function ProjectAddFilesModule:remove_file(file)
    table.delete_value(self._data, file)
    self:load_files()
end

function ProjectAddFilesModule:add_file_db_any_ext_dialog()
	BLE.ListDialog:Show({
	    list = table.map_keys(BLE.DBPaths),
		force = true,
        callback = function(ext)
            self:add_file_db_dialog(ext)
            BLE.ListDialog:Hide()
	    end
	})
end

function ProjectAddFilesModule:add_file_db_dialog(ext)
    local assets = {}
    for asset in pairs(BLE.DBPaths[ext]) do
        table.insert(assets, asset)
    end
	BLE.MSLD:Show({
	    list = assets,
		force = true,
        callback = function(asset)
            self:add_file(asset.."."..ext, true, false, true)
            BLE.ListDialog:Hide()
	    end,
        select_multi_clbk = function(assets)
            for _, asset in pairs(assets) do
                self:add_file(asset.."."..ext, true, false, true)
            end
            BLE.ListDialog:Hide()
        end
	})
end

function ProjectAddFilesModule:add_file_dialog(search_deps)
    local assets_dir = Path:CombineDir(self._parent:get_dir(), self._data.directory or "assets")
    BLE.FBD:Show({
        where = assets_dir,
        extensions = table.list_add({"png", "dds"}, table.map_keys(BeardLib.Constants.FileTypes)),
        file_click = function(path)
            self:add_file(path, search_deps)
            BLE.FBD:Hide()
        end
    })
end

local types_with_deps = {
    unit = true,
}

function ProjectAddFilesModule:add_folder(path, search_deps, deps, check_later)
    local first = deps == nil
    deps = deps or {}
    check_later = check_later or {}
    for _, file in pairs(FileIO:GetFiles(path)) do
        local ext = Path:GetFileExtension(file)
        local full_path = Path:Combine(path, file)
        if not search_deps or types_with_deps[ext] then
            local cfg = self:add_file(full_path, search_deps, true)
            if search_deps and cfg then
                -- We save all dependencies to later know whether or not an asset is a dependency or an asset that loaded by itself.
                for _, dep in pairs(cfg) do
                    deps[dep._meta] = deps[dep._meta] or {}
                    deps[dep._meta][deps.path] = true
                end
            end
        else
            table.insert(check_later, {full_path = full_path, path = file})
        end
    end

    for _, folder in pairs(FileIO:GetFolders(path)) do
        self:add_folder(Path:Combine(path, folder), search_deps, deps, check_later)
    end

    -- This should be called last so we can be more confident about these assets
    if first then
        for _, file in pairs(check_later) do
            local path = file.path
            local full_path = file.full_path

            local ext = Path:GetFileExtension(file)
            if deps[ext] and not deps[ext][path] then
                self:add_file(full_path, true, true)
            end
        end
    end

    self:load_files()
end

function ProjectAddFilesModule:add_file(path, search_deps, no_reload, from_db)
    local assets_dir = not from_db and Path:CombineDir(self._parent:get_dir(), self._data.directory or "assets") or nil
    self._exporter = BLE.Utils.Export:new({assets_dir = assets_dir, fallback_to_db_assets = true, pack_extract_path = false})

    local ext = Path:GetFileExtension(path)
    local path_no_ext = Path:GetFilePathNoExt(assets_dir and path:gsub(assets_dir, "") or path)
    local temp
    local cfg
    if search_deps then
        cfg = self._exporter:GetDependencies(ext, path_no_ext)
        temp = table.add_merge({table.merge({_meta = "add", path = path_no_ext, type = ext}, cfg)}, self._data)
    else
        temp = table.add_merge({{_meta = ext, path = path_no_ext, unload = true}}, self._data)
    end

    local new_add = {_meta = "AddFiles"}
    for k, v in pairs(self._data) do
        if tonumber(k) and type(v) ~= "table" then
            new_add[k] = v
        end
    end

    for _, child in pairs(temp) do
        if type(child) == "table" and child.path then
            local exists
            for _, _child in ipairs(new_add) do
                if type(child) == "table" and child.path == _child.path and (child._meta == _child._meta or ((child.type and _child.type) and child.type == _child.type)) then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(new_add, child)
            end
        end
    end
    self._data = new_add
    if not no_reload then
        self:load_files()
    end
    return cfg
end

function ProjectAddFilesModule:create()
    return {_meta = "AddFiles", path = "assets"}
end

--- The callback function for all items for this menu.
function ProjectAddFilesModule:set_data_callback(item)
    local data = self._data
    data.description = self:GetItemValue("Description")
    return data
end