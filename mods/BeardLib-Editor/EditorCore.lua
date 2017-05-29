_G.BeardLibEditor = _G.BeardLibEditor or ModCore:new(ModPath .. "Config.xml", false, true)
local self = BeardLibEditor
function self:Init()
    self:init_modules()
    self.ExtractDirectory = "assets/extract/"
    self.AssetsDirectory = self.ModPath .. "Assets/"
    self.HooksDirectory = self.ModPath .. "Hooks/"
    self.ClassDirectory = self.ModPath .. "Classes/"
    self.MapClassesDir = self.ClassDirectory .. "Map/"
    self.PrefabsDirectory = Path:Combine(BeardLib.config.maps_dir, "prefabs")
    self.ElementsDir = self.MapClassesDir .. "Elements/"
    self.Version = 6
    
    self.managers = {}
    self.modules = {}
    self.DBPaths = {}
    self.DBEntries = {}
    self.Prefabs = {}
    self:LoadHashlist()
    self.InitDone = true
end

function self:InitManagers()
    local acc_color = BeardLibEditor.Options:GetValue("AccentColor")
    local bg_color = BeardLibEditor.Options:GetValue("BackgroundColor")
    local M = BeardLibEditor.managers
    local dialogs_opt = {marker_highlight_color = acc_color, background_color = bg_color}
    M.Dialog = MenuDialog:new()
    M.ListDialog = ListDialog:new(dialogs_opt)
    M.SelectDialog = SelectListDialog:new(dialogs_opt)
    M.ColorDialog = ColorDialog:new(dialogs_opt)
    M.InputDialog = InputDialog:new(dialogs_opt)
    M.FBD = FileBrowserDialog:new(dialogs_opt)
       
    if Global.editor_mode then
        M.MapEditor = MapEditor:new()
    end 

    M.Menu = EditorMenu:new()
    M.ScriptDataConverter = ScriptDataConverterManager:new()
    M.MapProject = MapProjectManager:new()
    M.LoadLevel = LoadLevelMenu:new()
    M.EditorOptions = EditorOptionsMenu:new()
    AboutMenu:new()

    local prefabs = FileIO:GetFiles(self.PrefabsDirectory)
    if prefabs then
        for _, prefab in pairs(prefabs) do
            self.Prefabs[Path:GetFileNameWithoutExtension(prefab)] = FileIO:ReadScriptDataFrom(Path:Combine(self.PrefabsDirectory, prefab), "binary")
        end
    end

    self:LoadCustomAssetsToHashListt(self._config.AddFiles)
    local mod = self.managers.MapProject:current_mod()
    if mod and mod._config.level.add then
        self:log("Loading Custom Assets to Hashlist")
        local level = mod._config.level
        self:LoadCustomAssetsToHashListt(mod._config.level.add)   
        if level.include then
            for i, include_data in ipairs(level.include) do
                if include_data.file then
                    local file_split = string.split(include_data.file, "[.]")
                    local typ = file_split[2]
                    local path = Path:Combine("levels/mods/", level.id, file_split[1])
                    if FileIO:Exists(Path:Combine(mod.ModPath, level.include.directory, include_data.file)) then
                        self.DBPaths[typ] = self.DBPaths[typ] or {}
                        if not table.contains(self.DBPaths[typ], path) then
                            table.insert(self.DBPaths[typ], path)
                        end     
                    end
                end
            end
        end
    end
end

function self:RegisterModule(key, module)
    if not self.modules[key] then
        self:log("Registered module editor with key %s", key)
        self.modules[key] = module
    else
        self:log("[ERROR] Module editor with key %s already exists", key or "")
    end
end

function BeardLibEditor:LoadHashlist()
    local t = os.clock()
    self:log("Loading Hashlist")
    local has_hashlist = DB:has("idstring_lookup", "idstring_lookup")     
    local types = clone(BeardLib.config.script_data_types)
    table.insert(types, "unit")
    table.insert(types, "texture")
    table.insert(types, "movie")
    table.insert(types, "effect")
    table.insert(types, "scene")
    local remove = table.remove
    local insert = table.insert
    local split = string.split
    local entries = self.DBEntries
    for k, typ in pairs(types) do
        self.DBPaths[typ] = {}
    end
    local function ProcessLine(line)
        local path
        local path_split = split(line, "/")
        local filename = remove(path_split)
        local curr_tbl = entries
        for _, part in pairs(path_split) do
            curr_tbl[part] = curr_tbl[part] or {}
            curr_tbl = curr_tbl[part]
        end
        local line_split = split(line, ";")
        local t = split(line_split[2] or "", ",")
        line = line_split[1]
        if line and t then
            for _, typ in pairs(t) do
                typ = types[tonumber(typ)]
                insert(self.DBPaths[typ], line)
                insert(curr_tbl, {
                    path = line,
                    name = filename,
                    file_type = typ
                })
            end
        end
    end
    if Global.DBPaths and Global.DBEntries then
        self.DBPaths = Global.DBPaths
        self.DBEntries = Global.DBEntries
        self:log("Hashlist is Already Loaded.")
    else
        if has_hashlist then 
            local file = DB:open("idstring_lookup", "idstring_lookup")
            if file ~= nil then
                local gmatch = string.gmatch
                local sub = string.sub
                --Iterate through each string which contains _ or /, which should include all the filepaths in the idstring_lookup
                for line in gmatch(file:read(), "[%w_/]+%z") do ProcessLine(sub(line, 1, #line - 1)) end
                file:close()
            end
        else
            local lines = io.lines(self.ModPath .. "list.txt", "r")
            if lines then for line in lines do ProcessLine(line) end
            else self:log("Failed Loading Outside Hashlist") end
        end  
        self:log("%s Hashlist Loaded, It took %.2f seconds", has_hashlist and "Inside" or "Outside", os.clock() - t)   
        Global.DBPaths = self.DBPaths
        Global.DBEntries = self.DBEntries 
    end
    for typ, filetbl in pairs(self.DBPaths) do
        self:log(typ .. " Count: " .. #filetbl)
    end
end

function self:LoadCustomAssetsToHashListt(add)
    for _, v in pairs(add) do
        if type(v) == "table" then
            self.DBPaths[v._meta] = self.DBPaths[v._meta] or {}
            if not table.contains(self.DBPaths[v._meta], v.path) then
                table.insert(self.DBPaths[v._meta], v.path)
            end
        end
    end
end

function self:Update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.update then
            manager:update(t, dt)
        end
    end
end

function self:PausedUpdate(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.paused_update then
            manager:paused_update(t, dt)
        end
    end
end

function self:SetLoadingText(text)
    if alive(Global.LoadingText) then
        local project = BeardLib.current_level and BeardLib.current_level._mod
        local s = "Level ".. tostring(Global.game_settings.level_id)
        if project then
            s = "Project " .. tostring(project.Name) .. " - " .. tostring(Global.game_settings.level_id)
        end
        Global.LoadingText:set_name(s .. "\n" .. tostring(text))
    end
end

if MenuManager then
    function MenuManager:create_controller()
        if not self._controller then
            self._controller = managers.controller:create_controller("MenuManager", nil, true)
            local setup = self._controller:get_setup()
            local look_connection = setup:get_connection("look")
            self._look_multiplier = look_connection:get_multiplier()
            if not managers.savefile:is_active() then
                self._controller:enable()
            end
        end
    end
    local o = MenuCallbackHandler._dialog_end_game_yes
    function MenuCallbackHandler:_dialog_end_game_yes(...)
        Global.editor_mode = nil
        o(self, ...)
    end
end

if Hooks then
    Hooks:Add("MenuUpdate", "BeardLibEditorMenuUpdate", function( t, dt )
        BeardLibEditor:Update(t, dt)
    end)

    Hooks:Add("GameSetupUpdate", "BeardLibEditorGameSetupUpdate", function( t, dt )
        BeardLibEditor:Update(t, dt)
    end)

    Hooks:Add("GameSetupPauseUpdate", "BeardLibEditorGameSetupPausedUpdate", function(t, dt)
        BeardLibEditor:PausedUpdate(t, dt)
    end)

    Hooks:Add("LocalizationManagerPostInit", "BeardLibEditorLocalization", function(loc)
        LocalizationManager:add_localized_strings({
            ["BeardLibEditorEnvMenu"] = "Environment Mod Menu",
            ["BeardLibEditorEnvMenuHelp"] = "Modify the params of the current Environment",
            ["BeardLibEditorSaveEnvTable_title"] = "Save Current modifications",
            ["BeardLibEditorResetEnv_title"] = "Reset Values",
            ["BeardLibEditorScriptDataMenu_title"] = "ScriptData Converter",
            ["BeardLibEditorLoadLevel_title"] = "Load Level",
            ["BeardLibLevelManage_title"] = "Manage Levels",
            ["BeardLibEditorMenu"] = "BeardLibEditor Menu"
        })
    end)

    Hooks:Add("MenuManagerPopulateCustomMenus", "BeardLibEditorInitManagers", callback(self, self, "InitManagers"))
end

if not self.InitDone then
    if BeardLib.Version and BeardLib.Version >= 2.2 then
        BeardLibEditor:Init()
    else
        log("[ERROR], BeardLibEditor requires at least version 2.2 of Beardlib installed!")
    end
end