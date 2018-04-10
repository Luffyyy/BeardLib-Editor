if not ModCore then
    log("[ERROR][BeardLibEditor] BeardLib is not installed!")
    return
end

BeardLibEditor = BeardLibEditor or ModCore:new(ModPath .. "Data/Config.xml", false, true)
BLE = BeardLibEditor

function BLE:Init()
    self:init_modules()
    self.ExtractDirectory = self.Options:GetValue("ExtractDirectory").."/"
    self.AssetsDirectory = self.ModPath .. "Assets/"
    self.HooksDirectory = self.ModPath .. "Hooks/"
    self.ClassDirectory = self.ModPath .. "Classes/"
    self.DataDirectory = self.ModPath .. "Data/"
    self.MapClassesDir = self.ClassDirectory .. "Map/"
    self.PrefabsDirectory = Path:Combine(BeardLib.config.maps_dir, "prefabs")
    self.ElementsDir = self.MapClassesDir .. "Elements/"
    self.Version = self.AssetUpdates.version or 2

    self.updaters = {}
    self.modules = {}
    self.DBPaths = {}
    self.DBEntries = {}
    self.Prefabs = {}
    self:LoadHashlist()
    self.InitDone = true
    self.HasFix = XAudio and FileIO:Exists(self.ModPath.."supermod.xml") --current way of knowing if it's a superblt user and the fix is running.
end

function BLE:RunningFix()
    return self.HasFix
end

function BLE:InitManagers()
    local acc_color = BeardLibEditor.Options:GetValue("AccentColor")
    local bg_color = BeardLibEditor.Options:GetValue("BackgroundColor")
    local M = BeardLibEditor.managers
    self._dialogs_opt = {accent_color = acc_color, background_color = bg_color}
    self.Dialog = MenuDialog:new(self._dialogs_opt)
    self.ListDialog = ListDialog:new(self._dialogs_opt)
    self.SelectDialog = SelectListDialog:new(self._dialogs_opt)
    self.SelectDialogValue = SelectListDialogValue:new(self._dialogs_opt)
    self.ColorDialog = ColorDialog:new(self._dialogs_opt)
    self.InputDialog = InputDialog:new(self._dialogs_opt)
    self.FBD = FileBrowserDialog:new(self._dialogs_opt)
       
    if Global.editor_mode then
        self.MapEditor = MapEditor:new()
        table.insert(self.updaters, self.MapEditor)
    end

    self.Menu = EditorMenu:new()
    self.ScriptDataConverter = ScriptDataConverterManager:new()
    self.MapProject = MapProjectManager:new()
    self.LoadLevel = LoadLevelMenu:new()
    self.EditorOptions = EditorOptionsMenu:new()
    AboutMenu:new()

    local prefabs = FileIO:GetFiles(self.PrefabsDirectory)
    if prefabs then
        for _, prefab in pairs(prefabs) do
            self.Prefabs[Path:GetFileNameWithoutExtension(prefab)] = FileIO:ReadScriptDataFrom(Path:Combine(self.PrefabsDirectory, prefab), "binary")
        end
    end
    --Packages that are always loaded
    self.ConstPackages = {
        "packages/game_base_init",
        "packages/game_base",
        "packages/start_menu",
        "packages/load_level",
        "packages/load_default",
        "packages/boot_screen",
        "packages/toxic",
        "packages/dyn_resources",
        "packages/wip/game_base",
        "core/packages/base",
        "core/packages/editor"
    }
    local prefix = "packages/dlcs/"
    local sufix = "/game_base"
    for dlc_package, bundled in pairs(tweak_data.BUNDLED_DLC_PACKAGES) do
        table.insert(self.ConstPackages, prefix .. tostring(dlc_package) .. sufix)
    end
    for i, difficulty in ipairs(tweak_data.difficulties) do
        table.insert(self.ConstPackages, "packages/" .. (difficulty or "normal"))
    end
    
    self:LoadCustomAssets()
end

function BLE:LoadCustomAssets()
    local project = self.MapProject
    local mod = project:current_mod()
    local data = mod and project:get_clean_data(mod._clean_config)
    if data then
        if data.AddFiles then
            local config = data.AddFiles
            local directory = config.full_directory or BeardLib.Utils.Path:Combine(mod.ModPath, config.directory)
            self:LoadCustomAssetsToHashList(config, directory)
        end
        local level = project:get_level_by_id(data, Global.game_settings.level_id)
        if level then
            self:log("Loading Custom Assets to Hashlist")
            level.add = level.add or {}
            local add_path = Path:Combine(level.include.directory, "add.xml")
            if not FileIO:Exists(Path:Combine(mod.ModPath, add_path)) then
                local add = table.merge({directory = "assets"}, deep_clone(level.add)) --TODO just copy the xml template
                project:map_editor_save_xml(add_path, add)
            end
            level.add = {file = add_path}
            project:map_editor_save_main_xml(data, true)
            local add = project:map_editor_read_xml(level.add.file)
            if add then
                local directory = add.full_directory or BeardLib.Utils.Path:Combine(mod.ModPath, add.directory)
                self:LoadCustomAssetsToHashList(add, directory)
            end
            for i, include_data in ipairs(level.include) do
                if include_data.file then
                    local file_split = string.split(include_data.file, "[.]")
                    local typ = file_split[2]
                    local path = Path:Combine("levels/mods/", level.id, file_split[1])
                    if FileIO:Exists(Path:Combine(mod.ModPath, level.include.directory, include_data.file)) then
                        self.DBPaths[typ] = self.DBPaths[typ] or {}
                        self.DBPaths[typ][path] = true
                    end
                end
            end            
        end
    end
end

function BLE:RegisterModule(key, module)
    if not self.modules[key] then
        self:log("Registered module editor with key %s", key)
        self.modules[key] = module
    else
        self:log("[ERROR] Module editor with key %s already exists", key or "")
    end
end

function BLE:LoadHashlist()
    local t = os.clock()
    self:log("Loading DBPaths")
    if Global.DBPaths and Global.DBPackages and Global.WorldSounds then
        self.DBPaths = clone(Global.DBPaths)
        self.DBPackages = clone(Global.DBPackages)
        self.WorldSounds = Global.WorldSounds
        self.DefaultAssets = Global.DefaultAssets
        self:log("DBPaths already loaded")
    else
        self.DBPaths = FileIO:ReadScriptDataFrom(Path:Combine(self.DataDirectory, "Paths.bin"), "binary")
        self.DBPackages = FileIO:ReadScriptDataFrom(Path:Combine(self.DataDirectory, "PackagesPaths.bin"), "binary")
        self.WorldSounds = FileIO:ReadScriptDataFrom(Path:Combine(self.DataDirectory, "WorldSounds.bin"), "binary")
        self.DefaultAssets = FileIO:ReadScriptDataFrom(Path:Combine(self.DataDirectory, "DefaultAssets.bin"), "binary")

        self:log("Successfully loaded DBPaths, It took %.2f seconds", os.clock() - t)
        Global.DBPaths = self.DBPaths
        Global.DBPackages = self.DBPackages
        Global.WorldSounds = self.WorldSounds
        Global.DefaultAssets = self.DefaultAssets
    end
    for _, pkg in pairs(CustomPackageManager.custom_packages) do
        local id = pkg.id
        self.DBPackages[id] = self.DBPackages[id] or table.list_add(clone(BeardLib.config.script_data_types), {"unit", "texture", "movie", "effect", "scene"})
        self:ReadCustomPackageConfig(id, pkg.config, pkg.dir)
    end
end

function BLE:ReadCustomPackageConfig(id, config, directory)
    for _, child in pairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path

            if typ == "unit_load" or typ == "add" then
                self:ReadCustomPackageConfig(id, child, directory)
            elseif typ and path then
                path = BeardLib.Utils.Path:Normalize(path)
                local file_path = BeardLib.Utils.Path:Combine(directory, path) ..".".. typ
                if SystemFS:exists(file_path) then
                    self.DBPackages[id][typ] = self.DBPackages[id][typ] or {}
                    self.DBPaths[typ] = self.DBPaths[typ] or {}

                    self.DBPackages[id][typ][path] = true
                    self.DBPaths[typ][path] = true
                else
                    self:log("[ERROR][ReadCustomPackageConfig] File does not exist! %s", tostring(file_path))
                end
            end
        end
    end
end

--Converts a list of packages - assets of packages to premade tables to be used in the editor
function BLE:GeneratePackageData()
    local types = table.list_add(clone(BeardLib.config.script_data_types), {"unit", "texture", "movie", "effect", "scene"})
    local file = io.open(self.ModPath .. "packages.txt", "r")
    local packages_paths = {}
    local paths = {}
    local current_pkg
    self:log("[GeneratePackageData] Writing package data...")
    if file then
        for line in file:lines() do 
            if string.sub(line, 1, 1) == "@" then
                current_pkg = string.sub(line, 2)
            elseif current_pkg then
                packages_paths[current_pkg] = packages_paths[current_pkg] or {}
                local pkg = packages_paths[current_pkg]
                local path, typ = unpack(string.split(line, "%."))
                pkg[typ] = pkg[typ] or {}
                paths[typ] = paths[typ] or {}
                if DB:has(typ, path) then
                    paths[typ][path] = true
                    pkg[typ][path] = true
                end
            end
        end
        file:close()
        self:log("[GeneratePackageData] Done!")
    else
        self:log("[GeneratePackageData] packages.txt is missing...")
    end
    
    FileIO:WriteScriptDataTo(Path:Combine(self.ModPath, "Data", "Paths.bin"), paths, "binary")
    FileIO:WriteScriptDataTo(Path:Combine(self.ModPath, "Data", "PackagesPaths.bin"), packages_paths, "binary")
    Global.DBPaths = nil
    self:LoadHashlist()
end

--Gets all emitters and occasionals from extracted .world_sounds
function BLE:GenerateSoundData()
    local sounds = {}
    local function get_sounds(path)
        for _, file in pairs(FileIO:GetFiles(path)) do
            if string.ends(file, ".world_sounds") then
                local data = FileIO:ReadScriptDataFrom(Path:Combine(path, file), "binary")
                if not table.contains(sounds, data.default_ambience) then
                    table.insert(sounds, data.default_ambience)
                end
                if not table.contains(sounds, data.default_occasional) then
                    table.insert(sounds, data.default_occasional)
                end
                for _, v in pairs(data.sound_area_emitters) do
                    if not table.contains(sounds, v.emitter_event) then
                        table.insert(sounds, v.emitter_event)
                    end
                end
                for _, v in pairs(data.sound_emitters) do
                    if not table.contains(sounds, v.emitter_event) then
                        table.insert(sounds, v.emitter_event)
                    end
                end
                for _, v in pairs(data.sound_environments) do
                    if not table.contains(sounds, v.ambience_event) then
                        table.insert(sounds, v.ambience_event)
                    end
                    if not table.contains(sounds, v.occasional_event) then
                        table.insert(sounds, v.occasional_event)
                    end
                end
            end
        end
        for _, folder in pairs(FileIO:GetFolders(path)) do
            get_sounds(Path:Combine(path, folder))
        end
    end
    get_sounds(self.ExtractDirectory)
    FileIO:WriteScriptDataTo(Path:Combine(self.ModPath, "Data", "WorldSounds.bin"), sounds, "binary")
    self.WorldSounds = sounds
    Global.WorldSounds = sounds
end

--Uses a completely empty map to find out which assets are always loaded, this will help save map file size, might be dangerous though.
--We use _has instead of has so we can exclude any custom assets.
function BLE:GenerateDefaultAssetsData()
    self.DefaultAssets = {}
    for typ, v in pairs(self.DBPaths) do
        for path in pairs(v) do
            if PackageManager:_has(typ:id(), path:id()) then
                self.DefaultAssets[typ] = self.DefaultAssets[typ] or {}
                self.DefaultAssets[typ][path] = true
            end
        end
    end
    FileIO:WriteScriptDataTo(Path:Combine(self.ModPath, "Data", "DefaultAssets.bin"), self.DefaultAssets, "binary")
    Global.DefaultAssets = self.DefaultAssets
end

function BLE:LoadCustomAssetsToHashList(add, directory)
    for _, v in pairs(add) do
        if type(v) == "table" then
            local path = v.path
            local typ = v._meta
            if typ == "unit_load" then
                self:LoadCustomAssetsToHashList(v, directory)
            else
                path = BeardLib.Utils.Path:Normalize(path)

                self.DBPaths[typ] = self.DBPaths[typ] or {}
                self.DBPaths[typ][path] = true

                local file_path = BeardLib.Utils.Path:Combine(directory, path) ..".".. typ

                if FileIO:Exists(file_path) then
                    self.Utils.allowed_units[path] = true
                end
            end
        end
    end
end

function BLE:Update(t, dt)
    for _, manager in pairs(self.updaters) do
        if manager.update then
            manager:update(t, dt)
        end
    end
end

function BLE:PausedUpdate(t, dt)
    for _, manager in pairs(self.updaters) do
        if manager.paused_update then
            manager:paused_update(t, dt)
        end
    end
end

function BLE:SetLoadingText(text)
    if alive(Global.LoadingText) then
        local project = BeardLib.current_level and BeardLib.current_level._mod
        local s = "Level ".. tostring(Global.game_settings.level_id)
        if project then
            s = "Project " .. tostring(project.Name) .. ":" .. tostring(Global.game_settings.level_id)
        end
        if Global.editor_safe_mode then
        	s = "[SAFE MODE]" .. "\n" .. s
        end
        s = s .. "\n" .. tostring(text)
        Global.LoadingText:set_name(s)
        return s
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

if not BLE.InitDone then
    if BeardLib.Version and BeardLib.Version >= 2.9 then
        BeardLibEditor:Init()
    else
        log("[ERROR] BeardLibEditor requires at least version 2.9 of Beardlib installed!")
        return
    end
end

if Hooks then
    Hooks:Add("MenuUpdate", "BeardLibEditorMenuUpdate", ClassClbk(BLE, "Update"))
    Hooks:Add("GameSetupUpdate", "BeardLibEditorGameSetupUpdate", ClassClbk(BLE, "Update"))
    Hooks:Add("GameSetupPauseUpdate", "BeardLibEditorGameSetupPausedUpdate", ClassClbk(BLE, "PausedUpdate"))
    Hooks:Add("LocalizationManagerPostInit", "BeardLibEditorLocalization", function(loc)
        LocalizationManager:add_localized_strings({BeardLibEditorMenu = "BeardLibEditor Menu"})
    end)
    Hooks:Add("MenuManagerPopulateCustomMenus", "BeardLibEditorInitManagers", callback(BLE, BLE, "InitManagers"))
end