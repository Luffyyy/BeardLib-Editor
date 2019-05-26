ScriptDataConverterManager = ScriptDataConverterManager or class()
local SConverter = ScriptDataConverterManager
function SConverter:init()
    SConverter.script_file_from_types = {
        {name = "binary", func = "ScriptSerializer:from_binary", open_type = "rb"},
        {name = "json", func = "json.custom_decode"},
        {name = "generic_xml", func = "ScriptSerializer:from_generic_xml"},
        {name = "custom_xml", func = "ScriptSerializer:from_custom_xml"},
    }
    SConverter.script_file_to_types = {
        {name = "binary", open_type = "wb"},
        {name = "json"},
        {name = "generic_xml"},
        {name = "custom_xml"},
    }
    SConverter.script_data_paths = {
        {path = "%userprofile%", name = "User Folder"},
        {path = "%userprofile%/Documents/", name = "Documents"},
        {path = "%userprofile%/Desktop/", name = "Desktop"},
        {path = string.gsub(Application:base_path(), "\\", "/"), name = "PAYDAY 2 Directory"},
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
    local menu = BeardLibEditor.Menu
    self._menu = menu:make_page("ScriptData")
    ItemExt:add_funcs(self)
    self:CreateRootItems()
end

function SConverter:ConvertFile(file, from_i, to_i, filename_dialog)
    if not from_i or not to_i then
        return
    end
    local to_data = self.script_file_to_types[to_i]
    local file_split = string.split(file, "%.")
    local filename_split = string.split(file_split[1], "/")
	local convert_data
	if not self.assets then
		local read = FileIO:ReadFrom(file, "rb")
		local data
		if read then
			local t = self.script_file_from_types[from_i].name
			convert_data = (t == "binary" and read:sub(0, 2):find("<%w") and FileIO:ConvertScriptData(read, "custom_xml")) or FileIO:ConvertScriptData(read, t)
		end
	end
    if not convert_data and not self.assets then
        BeardLibEditor:log("[Error] File not accessible")
        return
    end
    local convert_data = convert_data or PackageManager:_script_data(file_split[2]:id(), file_split[1]:id())
    local new_path = self.assets and string.gsub(Application:base_path(),  "\\", "/") .. filename_split[#filename_split] .. "." .. to_data.name or file .. "." .. to_data.name
    if filename_dialog then
        BeardLibEditor.InputDialog:Show({title = "File name", text = new_path, callback = ClassClbk(self, "SaveConvertedData", {to_data = to_data, convert_data = convert_data})})
    else
        self:SaveConvertedData({to_data = to_data, convert_data = convert_data}, true, new_path)
    end
end

function SConverter:SaveConvertedData(params, value)
    FileIO:WriteScriptData(value, params.convert_data, params.to_data.name)
    self:RefreshFilesAndFolders()
end

function SConverter:GetFilesAndFolders(current_path)
    return FileIO:GetFiles(current_path), FileIO:GetFolders(current_path)
end

function SConverter:MainItems()
    self.path_text = self:divider("BeardLibEditorPathText", {text = self.current_script_path})
	self:button("BackToShortcuts", ClassClbk(self, "BackToShortcuts"))
	self:button("BrowseTo", ClassClbk(self, "OpenBrowseDialog"))
end

function SConverter:RefreshFilesAndFolders()
    self:ClearItems()
    self:MainItems()
	
    if not self.assets then
        self:button("OpenFolderInExplorer", ClassClbk(self, "OpenFolderInExplorer"))
    end
    local up_level = string.split(self.current_script_path, "/")
    if #up_level > 0 then
        table.remove(up_level, #up_level)

        local up_string = table.concat(up_level, "/")
        self:button("UpADirectory...", ClassClbk(self, "FolderClick"), {base_path = up_string .. (up_string == "" and "" or "/")})
    end

    local holder = self:pan("Holder", {align_method = "grid"})
    local w,h = (holder:ItemsWidth() - 16) / 2, self._menu:Height() - holder:Y()  - 8
    local foldersgroup = holder:group("Folders", {w = w, h = h, auto_height = false, auto_align = false})
    local filesgroup = holder:group("Files", {w = w, h = h, auto_height = false, auto_align = false})
    local files, folders = self:GetFilesAndFolders(self.current_script_path)
    if folders then
        table.sort(folders)
        for i, folder in pairs(folders) do
            foldersgroup:button(folder, ClassClbk(self, "FolderClick"), {text = folder, base_path = self.current_script_path .. folder .. "/"})
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
                filesgroup:button(file, ClassClbk(self, "FileClick"), {text = file, base_path = self.current_script_path .. file, enabled = enabled})
            end
        end
    end
    foldersgroup:AlignItems(true)
    filesgroup:AlignItems(true)
end

function SConverter:CreateScriptDataFileOption()
    self:ClearItems()
	self:MainItems()
	
    local up_level = string.split(self.current_script_path, "/")
    if #up_level > 0 then
        table.remove(up_level, #up_level)

        local up_string = table.concat(up_level, "/")
        self:button("UpADirectory...", ClassClbk(self, "FolderClick"), {base_path = up_string .. (up_string == "" and "" or "/")})
    end
    if self.path_text then
        self.path_text:SetVisible(true)
        self.path_text:SetText(self.current_selected_file_path)
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
    self:combobox("From", nil, BeardLib.Utils:GetSubValues(self.script_file_from_types, "name"), selected_from, {enabled = not self.assets})
    self:combobox("To", nil, BeardLib.Utils:GetSubValues(self.script_file_to_types, "name"), selected_from)
    self:button("Convert", ClassClbk(self, "ConvertClick"))
    self:button("Cancel", ClassClbk(self, "FolderClick"), {base_path = self.current_script_path})
end

function SConverter:CreateRootItems()
    self:ClearItems()
    for i, path_data in pairs(self.script_data_paths) do
        self:button(path_data.name, ClassClbk(self, "FolderClick"), {base_path = path_data.path, assets = path_data.assets})
    end
end

function SConverter:BackToRoot(item)
    self:CreateRootItems()
    self.current_script_path = ""
    if alive(self.path_text) then
        self.path_text:SetVisible(false)
    end
end

function SConverter:OpenBrowseDialog()
	BeardLibEditor.InputDialog:Show({title = "Browse to..", text = "", callback = function(path)
		path = path:gsub("\\", "/")
		if FileIO:Exists(path) then
			self.current_script_path = path
			self:RefreshFilesAndFolders()
		end
	end})
end

function SConverter:FileClick(item)
    self.current_selected_file = item.name
    self.current_selected_file_path = item.base_path

    self:CreateScriptDataFileOption()
end

function SConverter:FolderClick(item)
    self.current_script_path = item.base_path or ""
    self:RefreshFilesAndFolders()
end

function SConverter:OpenFolderInExplorer(item)
    local open_path = string.gsub(self.current_script_path, "%./", "")
    open_path = string.gsub(self.current_script_path, "/", "\\")
    Application:shell_explore_to_folder(open_path)
end

function SConverter:BackToShortcuts(item)
    self:ClearItems()
    self.assets = false
    self.current_script_path = ""
    self:CreateRootItems()
end

function SConverter:ConvertClick(item)
    local convertfrom_item = self:GetItem("From")
    local convertto_item = self:GetItem("To")
    if convertfrom_item and convertto_item then
        self:ConvertFile(self.current_selected_file_path, convertfrom_item:Value(), convertto_item:Value(), true)
    end    
end