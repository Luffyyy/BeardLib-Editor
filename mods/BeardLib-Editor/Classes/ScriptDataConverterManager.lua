ScriptDataConverterManager = ScriptDataConverterManager or class()
local scm = ScriptDataConverterManager
function scm:init()
    scm.script_file_from_types = {
        {name = "binary", func = "ScriptSerializer:from_binary", open_type = "rb"},
        {name = "json", func = "json.custom_decode"},
        {name = "xml", func = "ScriptSerializer:from_xml"},
        {name = "generic_xml", func = "ScriptSerializer:from_generic_xml"},
        {name = "custom_xml", func = "ScriptSerializer:from_custom_xml"},
    }
    scm.script_file_to_types = {
        {name = "binary", open_type = "wb"},
        {name = "json"},
        {name = "generic_xml"},
        {name = "custom_xml"},
    }
    scm.script_data_paths = {
        {path = "%userprofile%", name = "User Folder"},
        {path = "%userprofile%/Documents/", name = "Documents"},
        {path = "%userprofile%/Desktop/", name = "Desktop"},
        {path = string.gsub(Application:base_path(), "\\", "/"), name = "PAYDAY 2 Directory"},
        {name = "PAYDAY 2 Assets", assets = true},
        {path = "C:/", name = "C Drive"},
        {path = "D:/", name = "D Drive"},
        {path = "E:/", name = "E Drive"},
        {path = "F:/", name = "F Drive"},
    }
    local user_path = string.gsub(Application:windows_user_folder(),  "\\", "/")
    local split_user_path = string.split(user_path, "/")
    for i = 1, 3 do
        table.remove(split_user_path, #split_user_path)
    end
    user_path = table.concat(split_user_path, "/")
    for i, path_data in pairs(self.script_data_paths) do
        if path_data.path then
            path_data.path = string.gsub(path_data.path, "%%userprofile%%", user_path)
            if not string.ends(path_data.path, "/") then
                path_data.path = path_data.path .. "/"
            end
        end

        if not path_data.assets then
            path_data.assets = false
        end
    end
    local menu = BeardLibEditor.managers.Menu
    self._menu = menu:make_page("ScriptData")
    MenuUtils:new(self)
    self:CreateRootItems()
end

function scm:ConvertFile(file, from_i, to_i, filename_dialog)
    local to_data = self.script_file_to_types[to_i]
    local file_split = string.split(file, "%.")
    local filename_split = string.split(file_split[1], "/")

    local convert_data = not self.assets and FileIO:ReadScriptDataFrom(file, self.script_file_from_types[from_i].name)
    if not convert_data and not self.assets then
        BeardLibEditor:log("[Error] File not accessible")
        return
    end
    local convert_data = convert_data or PackageManager:_script_data(file_split[2]:id(), file_split[1]:id())
    local new_path = self.assets and string.gsub(Application:base_path(),  "\\", "/") .. filename_split[#filename_split] .. "." .. to_data.name or file .. "." .. to_data.name
    if filename_dialog then
        managers.system_menu:show_keyboard_input({text = new_path, title = "File name", callback_func = callback(self, self, "SaveConvertedData", {to_data = to_data, convert_data = convert_data})})
    else
        self:SaveConvertedData({to_data = to_data, convert_data = convert_data}, true, new_path)
    end
end

function scm:SaveConvertedData(params, success, value)
    if not success then
        return
    end
    FileIO:WriteScriptDataTo(value, params.convert_data, params.to_data.name)
    self:RefreshFilesAndFolders()
end

function scm:GetFilesAndFolders(current_path)
    local folders, files

    if self.assets then
        local path_split = string.split(current_path, "/")
        local tbl = BeardLibEditor.DBEntries
        for _, part in pairs(path_split) do
            if tbl[part] then
                tbl = tbl[part]
            else
                tbl = {}
            end
        end

        folders = {}
        files = {}

        for i, j in pairs(tbl) do
            if tonumber(i) ~= nil then
                table.insert(files, j.name .. "." .. j.file_type)
            else
                table.insert(folders, i)
            end
        end
    else
        folders = file.GetDirectories(current_path)
        files = file.GetFiles(current_path)
    end

    return files or {}, folders or {}
end

function scm:RefreshFilesAndFolders()
    self:ClearItems()
    local panel = self._menu:Panel()
    self.path_text = self.path_text or panel:text({
        name = "BeardLibEditorPathText",
        text = "",
        font =  tweak_data.menu.pd2_medium_font,
        font_size = 25,
        layer = 20,
        color = Color.yellow
    })
    self.path_text:set_text(self.current_script_path)
    self.path_text:set_visible(true)
    local _,_,w,h = self.path_text:text_rect()
    self.path_text:set_size(w, h)
    self.path_text:set_position(0, 0)

    self:Button("BackToShortcuts", callback(self, self, "BackToShortcuts"), {offset = {2, 32}})

    if not self.assets then
        self:Button("OpenFolderInExplorer", callback(self, self, "OpenFolderInExplorer"))
    end
    local up_level = string.split(self.current_script_path, "/")
    if #up_level > 0 then
        table.remove(up_level, #up_level)

        local up_string = table.concat(up_level, "/")
        self:Button("UpADirectory...", callback(self, self, "FolderClick"), {base_path = up_string .. (up_string == "" and "" or "/")})
    end

    local foldersgroup = self:Group("Folders")
    local filesgroup = self:Group("Files")
    local files, folders = self:GetFilesAndFolders(self.current_script_path)
    if folders then
        table.sort(folders)
        for i, folder in pairs(folders) do
            self:Button(folder, callback(self, self, "FolderClick"), {text = folder, base_path = self.current_script_path .. folder .. "/", group = foldersgroup})
        end
    end
    if files then
        table.sort(files)
        for i, file in pairs(files) do
            local file_parts = string.split(file, "%.")
            local extension = file_parts[#file_parts]
            local enabled = true
            if self.assets and not PackageManager:has(extension:id(), (self.current_script_path .. file_parts[1]):id()) then
                enabled = false
            end
            if table.contains(BeardLib.config.script_data_types, extension) or table.contains(BeardLib.config.script_data_formats, extension) then
                self:Button(file, callback(self, self, "FileClick"), {text = file, base_path = self.current_script_path .. file, enabled = enabled, group = filesgroup})
            end
        end
    end
end

function scm:CreateScriptDataFileOption()
    self:ClearItems()
    self:Button("BackToShortcuts", callback(self, self, "BackToShortcuts"), {offset = {2, 32}})
    local up_level = string.split(self.current_script_path, "/")
    if #up_level > 0 then
        table.remove(up_level, #up_level)

        local up_string = table.concat(up_level, "/")
        self:Button("UpADirectory...", callback(self, self, "FolderClick"), {base_path = up_string .. (up_string == "" and "" or "/")})
    end
    if self.path_text then
        self.path_text:set_visible(true)
        self.path_text:set_text(self.current_selected_file_path)
        local x, y, w, h = self.path_text:text_rect()
        self.path_text:set_size(w, h)
        self.path_text:set_position(0, 0)
    end

    local file_parts = string.split(self.current_selected_file, "%.")
    local extension = file_parts[#file_parts]
    local selected_from = 1
    for i, typ in pairs(self.script_file_from_types) do
        if typ.name == extension then
            selected_from = i
            break
        end
    end
    self:ComboBox("From", nil, BeardLib.Utils:GetSubValues(self.script_file_from_types, "name"), selected_from, {enabled = not self.assets})
    self:ComboBox("To", nil, BeardLib.Utils:GetSubValues(self.script_file_to_types, "name"), selected_from)
    self:Button("Convert", callback(self, self, "ConvertClick"))
    self:Button("Cancel", callback(self, self, "FolderClick"), {base_path = self.current_script_path})
end

function scm:CreateRootItems()
    self:ClearItems()
    for i, path_data in pairs(self.script_data_paths) do
        self:Button(path_data.name, callback(self, self, "FolderClick"), {base_path = path_data.path, assets = path_data.assets})
    end
end

function scm:BackToRoot(menu, item)
    self:CreateRootItems()
    self.current_script_path = ""
    if self.path_text then
        self.path_text:set_visible(false)
    end
end

function scm:FileClick(menu, item)
    self.current_selected_file = item.name
    self.current_selected_file_path = item.base_path

    self:CreateScriptDataFileOption()
end

function scm:FolderClick(menu, item)
    self.current_script_path = item.base_path or ""
    self.assets = self.assets or item.assets
    self:RefreshFilesAndFolders()
end

function scm:OpenFolderInExplorer(menu, item)
    local open_path = string.gsub(self.current_script_path, "%./", "")
    open_path = string.gsub(self.current_script_path, "/", "\\")

    os.execute('start "" "' .. open_path .. '"')
end

function scm:BackToShortcuts(menu, item)
    local panel = self._menu:Panel()
    if alive(self.path_text) then
        self.path_text:parent():remove(self.path_text)
        self.path_text = nil
    end
    self:ClearItems()
    self.assets = false
    self.current_script_path = ""
    self:CreateRootItems()
end

function scm:ConvertClick(menu, item)
    local convertfrom_item = self:GetItem("From")
    local convertto_item = self:GetItem("To")
    if convertfrom_item and convertto_item then
        self:ConvertFile(self.current_selected_file_path, convertfrom_item:Value(), convertto_item:Value(), true)
    end    
end