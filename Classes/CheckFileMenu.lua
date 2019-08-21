CheckFileMenu = CheckFileMenu or class()
function CheckFileMenu:init(data)
    data = data or {}
    self:Load(data)

    local EMenu = BeardLibEditor.Menu
    self._menu = EMenu:make_page("Check file", nil, {scrollbar = false, align_method = "centered_grid"})
    ItemExt:add_funcs(self, self._menu)
    self:lbl("Having trouble finding out why a unit or other file isn't loading properly? You can check it here!", {size_by_text = true})
    self:textbox("FilePath", nil, self._last_dir, {text = false, w = 650, control_slice = 1, border_size = 4, offset = {0, 4}})
    self:small_button("Browse", ClassClbk(self, "OpneFileBrowser"))
    self:small_button("BrowseDirectory", ClassClbk(self, "OpneFileBrowser", true))
    self:small_button("Check", ClassClbk(self, "CheckFile"))
    self._holder = self:pan("ErrorsHolder", {max_height = 600})
end

function CheckFileMenu:small_button(name, clbk)
    self:tb_btn(name, clbk, {
        min_width = 100,
        text_offset = {8, 2},
        border_bottom = true,
    })
end

function CheckFileMenu:CheckFile()
    self._holder:ClearItems()

    local path = self:GetItem("FilePath"):Value()
    if not FileIO:Exists(path) then
        self:Error("File or directory does not exist!")
        return
    end
    local type = lfs.attributes(path, "mode")
    if type == "file" then
        self:DoCheckFile(path)
    elseif type == "directory" then
        self:DoCheckDir(path)
    end
end

function CheckFileMenu:DoCheckDir(path)
    for _, file in pairs(FileIO:GetFiles(path)) do
        if file:ends(".unit") then
            self:DoCheckFile(Path:Combine(path, file))
        end
    end
    for _, folder in pairs(FileIO:GetFolders(path)) do
        self:DoCheckDir(Path:Combine(path, folder))
    end
end

function CheckFileMenu:DoCheckFile(file)
    local mod = BeardLib.Utils:FindModWithMatchingPath(file)
    if mod then    
        local Checker = BLE.Utils.Export:new()
        Checker.pack_extra_info = true
        Checker.assets_dir = Path:CombineDir(mod.ModPath, mod.AddFiles._config.directory)
        Checker.return_on_missing = false

        local splt = string.split(file:gsub(Checker.assets_dir, ""), "%.")
        local path = splt[1]
        local ext = splt[2]

        local errors = Checker:CheckFileFromMod(ext, path, mod)
        if not errors then
            self._holder:Divider({text = string.format("Missing file %s", tostring(file))})
        else
            if #errors > 0 then
                local group = self._holder:group(file, {text = file, background_color = self._menu.background_color, font_size = 18})
                for _, err_file in pairs(errors) do
                    group:Button({
                        on_callback = function()
                            os.execute(string.format('start explorer.exe /select,"%s"', file:gsub("/", "\\")))
                        end,
                        text = string.format("Missing file %s. Used by %s in %s", err_file.path.."."..err_file._meta, tostring(err_file.extra_info.file), tostring(err_file.extra_info.where))
                    })
                end
            end
        end
    else

    end
end

function CheckFileMenu:Error(err)
    self._holder:lbl(err)
end

function CheckFileMenu:Load(data)
    self._last_dir = data.last_dir or "assets/mod_overrides"
end

function CheckFileMenu:OpneFileBrowser(folder_browser)
    local base_path = Path:Normalize(Application:base_path())
    BLE.FBD:Show({
        where = self._last_dir or base_path, 
        extensions = table.map_keys(BLE.Utils.Export.Reading),
        folder_browser = folder_browser,
        file_click = function(path)
            self:GetItem("FilePath"):SetValue(Path:Normalize(path):gsub(base_path, ""))
            self._last_dir = BLE.FBD._current_dir
            BLE.FBD:Hide()
        end
    })
end

function CheckFileMenu:Destroy()
    return {last_dir = self._last_dir, last_path = self:GetItem("FilePath"):Value()}
end