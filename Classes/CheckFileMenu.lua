CheckFileMenu = CheckFileMenu or class()
function CheckFileMenu:init(data)
    data = data or {}
    self:Load(data)

    local EMenu = BLE.Menu
    self._menu = EMenu:make_page("Check file", nil, {scrollbar = false, align_method = "centered_grid", auto_align=false})
    ItemExt:add_funcs(self, self._menu)
    self:lbl("Having trouble finding out why a unit or other file isn't loading properly? You can check it here!", {text_align = "center"})
    self:textbox("Path", ClassClbk(self, "FixPath"), self._last_dir, {text = false, w = 650, border_size = 4})
    self:small_button("BrowseFile", ClassClbk(self, "OpneFileBrowser"))
    self:small_button("BrowseDirectory", ClassClbk(self, "OpneFileBrowser", true))
    self:small_button("Check", ClassClbk(self, "CheckFile"))
    self._holder = self:pan("ErrorsHolder", {max_height = 600})

    self:AlignItems()
end

function CheckFileMenu:small_button(name, clbk)
    self:tb_btn(name, clbk, {
        min_width = 60,
        text_offset = {8, 2},
        border_bottom = true,
    })
end
function CheckFileMenu:FixPath(item)
    local text = Path:Normalize(item:Value())
    local base_path = Path:Normalize(Application:base_path())
    if text:find(base_path) then
        local result = text:gsub(base_path, "")
        if result:len() > 0 then
            item:SetValue(result) 
        end
    end
    self._last_dir = item:Value()
end

function CheckFileMenu:CheckFile()
    self._holder:ClearItems()

    local path = self:GetItem("Path"):Value()
    local folder = FileIO:DirectoryExists(path)
    if not folder then
        if not FileIO:FileExists(path) then
            self._holder:lbl("File given does not exist! "..tostring(file))
            return
        end
    end
    if folder then
        self:DoCheckDir(path)
    else
        self:DoCheckFile(path)
    end
end

function CheckFileMenu:DoCheckDir(path)
    for _, file in pairs(FileIO:GetFiles(path)) do
        if file:ends(".unit") then
            self:DoCheckFile(Path:Normalize(Path:Combine(path, file)))
        end
    end
    for _, folder in pairs(FileIO:GetFolders(path)) do
        self:DoCheckDir(Path:Combine(path, folder))
    end
end
function BeardLib.Utils:FindModWithMatchingPath(path)
    for _, mod in pairs(BeardLib.Mods) do
        if Path:Normalize(path):find(Path:Normalize(mod.ModPath), 1, true) ~= nil then
            return mod
        end
    end
    return nil
end

function FileBrowserDialog:FolderClick(item)
    self._old_dir = nil
    self:Browse(self._current_dir == "" and item.text or Path:CombineDir(self._current_dir, item.text))
    if item.press_clbk then
        item.press_clbk()
    end
end
function CheckFileMenu:DoCheckFile(file)
    local mod = BeardLib.Utils:FindModWithMatchingPath(file)
    local Checker = BLE.Utils.Export:new()
    Checker.pack_extra_info = true
    local assets_dir
    if mod and mod.AddFiles then
        assets_dir = Path:CombineDir(mod.ModPath, mod.AddFiles._config.directory)
    elseif BeardLib.Frameworks.add.add_configs then
        for path, _ in pairs(BeardLib.Frameworks.add.add_configs) do
            if file:find(path, 1, true) ~= nil then
                assets_dir = path
            end
        end
    end

    if not assets_dir then
        if mod then
            assets_dir = Path:CombineDir(mod.ModPath, "assets")
        else
            return
        end
    end

    if not FileIO:Exists(assets_dir) then
        return
    end

    Checker.assets_dir = assets_dir
    Checker.return_on_missing = false

    file = Path:Normalize(file):gsub(Path:Normalize(Application:base_path()), "")

    local splt = string.split(file:gsub(Checker.assets_dir, ""), "%.")
    local path = splt[1]
    local ext = splt[2]

    local errors = Checker:CheckFile(ext, path)
    if errors and  #errors > 0 then
        local color1 = Color(0.6, 0.6, 1)
        local color2 = Color(0.8, 0.2, 1)
        local s0, e0 = file:find(string.split(file, "%.")[1])
        local group = self._holder:group(file, {text = file, range_color = {{s0-1, e0, color1}, {e0, color2}}, background_color = self._menu.background_color, font_size = 18})
        for _, err_file in pairs(errors) do
            if err_file._meta ~= "cooked_physics" then
                local text
                local range_color
                if err_file.extra_info then
                    local missing_file = err_file.path.."."..err_file._meta
                    local extra = err_file.extra_info
                    text = string.format("File not loaded %s. Used by %s in %s", missing_file, tostring(extra.file), tostring(extra.where))
                    local exta_splt = string.split(extra.file, "%.")
                    local s1,e1 = text:find(err_file.path, 1, true)
                    local s2,e2 = text:find(err_file._meta, e1, true)
                    local s3,e3 = text:find(exta_splt[1], e2, true)
                    local s4,e4 = text:find(exta_splt[2], e3, true)
                    local s5,e5 = text:find(extra.where, e4, true)  
                    range_color = {
                        s1 and {s1-1, e1, color1} or nil,
                        s2 and {e1, e2, color2},
                        s3 and {s3-1, e3, color1} or nil,
                        s4 and {e3, e4, color2} or nil,
                        s5 and {s5-1, e5, color2} or nil,
                    }
                else
                    text = "The file itself is not loaded"
                end
                group:Button({
                    on_callback = function()
                        os.execute(string.format('start explorer.exe /select,"%s"', file:gsub("/", "\\")))
                    end,
                    range_color = range_color,
                    text = text
                })
            end
        end
        if #group:Items() == 0 then
            group:Destroy()
        end
    end
end

function CheckFileMenu:Load(data)
    self._last_dir = data.last_dir or "assets/mod_overrides/"
end

function CheckFileMenu:OpneFileBrowser(folder_browser)
    local base_path = Path:Normalize(Application:base_path())
    local dir = Path:GetDirectory(self._last_dir)
    BLE.FBD:Show({
        where = dir:len() > 0 and dir or base_path, 
        extensions = table.map_keys(BLE.Utils.Export.Reading),
        folder_browser = folder_browser,
        file_click = function(path)
            self:GetItem("Path"):SetValue(Path:Normalize(path):gsub(base_path, ""))
            self._last_dir = BLE.FBD._current_dir
            BLE.FBD:Hide()
        end
    })
end

function CheckFileMenu:Destroy()
    return {last_dir = self._last_dir, last_path = self:GetItem("Path"):Value()}
end