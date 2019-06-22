local UNIT_LOAD = "unit_load"
local ADD = "add"

BLE = BeardLibEditor
BLE.DBEntries = {}
BLE.Updaters = {}
BLE.DBPaths = {}
BLE.Prefabs = {}

function BLE:Init()
	self.AssetsDirectory =  Path:CombineDir(self.ModPath, "Assets")
	self.HooksDirectory =  Path:CombineDir(self.ModPath, "Hooks")
	self.ClassDirectory =  Path:CombineDir(self.ModPath, "Classes")
	self.DataDirectory = Path:CombineDir(self.ModPath, "Data")
	self.DialogsDirectory = Path:CombineDir(self.ClassDirectory, "Dialogs")
	self.MapClassesDir = Path:CombineDir(self.ClassDirectory, "Map")
	self.PrefabsDirectory = Path:CombineDir(BeardLib.config.maps_dir, "prefabs")
	self.ElementsDir = Path:CombineDir(self.MapClassesDir, "Elements")
	self.HasFix = XAudio and FileIO:Exists(self.ModPath.."supermod.xml") --current way of knowing if it's a superblt user and the fix is running.
	self.ExtractDirectory = self.Options:GetValue("ExtractDirectory").."/"		
	self.UsableAssets = {"unit", "effect", "environment", "scene"}
end

function BLE:RunningFix()
    return self.HasFix
end

function BLE:Dofiles(path)
    for _, file in pairs(FileIO:GetFiles(path)) do
        dofile(Path:Combine(path,file))
    end
end

function BLE:MapEditorCodeReload()
    self:Dofiles(self.ClassDirectory)
    self:Dofiles(self.MapClassesDir)
    self:Dofiles(self.DialogsDirectory)

    self.Dialog:Destroy()
    self.ListDialog:Destroy()
    self.SelectDialog:Destroy()
    self.SelectDialogValue:Destroy()
    self.ColorDialog:Destroy()
    self.InputDialog:Destroy()
    self.FBD:Destroy()
    self.MSLD:Destroy()

    local data = {}
    if self.Menu then
        data.menu = self.Menu:Destroy()
        data.script_data = self.ScriptDataConverter:Destroy()
        data.project = self.MapProject:Destroy()
        data.load = self.LoadLevel:Destroy()
        data.options = self.EditorOptions:Destroy()
        data.about = self.AboutMenu:Destroy()
    end

    if self.MapEditor then
        table.delete(self.Updaters, self.MapEditor)
        data.editor = self.MapEditor:destroy()
    end

    self:InitManagers(data)
end

function BLE:InitManagers(data)
    data = data or {}
    if not self.ConstPackages then
        self:LoadHashlist()
    end
	
    self._dialogs_opt = {accent_color = self.Options:GetValue("AccentColor"), background_color = self.Options:GetValue("BackgroundColor")}
    self.Dialog = MenuDialog:new(self._dialogs_opt)
    self.ListDialog = ListDialog:new(self._dialogs_opt)
    self.SelectDialog = SelectListDialog:new(self._dialogs_opt)
    self.SelectDialogValue = SelectListDialogValue:new(self._dialogs_opt)
    self.ColorDialog = ColorDialog:new(self._dialogs_opt)
    self.InputDialog = InputDialog:new(self._dialogs_opt)
    self.FBD = FileBrowserDialog:new(self._dialogs_opt)
    self.MSLD = MultiSelectListDialog:new(self._dialogs_opt)    

    if Global.editor_mode then
        if not self._vp then
            self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
            self._camera_object = World:create_camera()
            self._camera_object:set_near_range(20)
            self._camera_object:set_far_range(BLE.Options:GetValue("Map/CameraFarClip"))
            self._camera_object:set_fov(BLE.Options:GetValue("Map/CameraFOV"))
            self._camera_object:set_position(Vector3(864, -789, 458))
            self._camera_object:set_rotation(Rotation(54.8002, -21.7002, 8.53774e-007))
            self._vp:set_camera(self._camera_object)
        end
        
        self.MapEditor = MapEditor:new(data.editor)
        table.insert(self.Updaters, self.MapEditor)
    end

    if not self.FileWatcher and FileIO:Exists("mods/developer.txt") then --Code refresh is only for developers!
        self.FileWatcher = FileWatcher:new(Path:Combine(self.ClassDirectory), {
            callback = ClassClbk(self, "MapEditorCodeReload"),
            scan_t = 0.5
        })
    end

    self.Menu = EditorMenu:new()
    self.ScriptDataConverter = ScriptDataConverterManager:new(data.script_data)
    self.MapProject = MapProjectManager:new(data.project)
    self.LoadLevel = LoadLevelMenu:new(data.load)
    self.EditorOptions = EditorOptionsMenu:new(data.options)
    self.AboutMenu = AboutMenu:new(data.about)
    self.Menu:Load(data.menu)

    if not self.ConstPackages then
        local prefabs = FileIO:GetFiles(self.PrefabsDirectory)
        if prefabs then
            for _, prefab in pairs(prefabs) do
                self.Prefabs[Path:GetFileNameWithoutExtension(prefab)] = FileIO:ReadScriptData(Path:Combine(self.PrefabsDirectory, prefab), "binary")
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
        for path, _ in pairs(self.Utils.allowed_units) do
            Global.DBPaths.unit[path] = true
        end
        self:LoadCustomAssets()
    end
end

function BLE:LoadCustomAssets()
    local project = self.MapProject
    local mod, data = project:get_mod_and_config()
    if data then
        if data.AddFiles then
            local config = data.AddFiles
            local directory = config.full_directory or Path:Combine(mod.ModPath, config.directory)
            self:LoadCustomAssetsToHashList(config, directory)
        end
        local level = project:get_level_by_id(data, Global.current_level_id)
        if level then
            self:log("Loading Custom Assets to Hashlist")
            level.add = level.add or {}
            local add_path = Path:Combine(level.include.directory, "add.xml")
            if not FileIO:Exists(Path:Combine(mod.ModPath, add_path)) then
                local add = table.merge({directory = "assets"}, deep_clone(level.add)) --TODO just copy the xml template
                project:save_xml(add_path, add)
            end
            level.add = {file = add_path}
            project:save_main_xml(data, true)
            local add = project:read_xml(level.add.file)
            if add then
                local directory = add.full_directory or Path:Combine(mod.ModPath, add.directory)
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
        self.DBPaths = FileIO:ReadScriptData(Path:Combine(self.DataDirectory, "Paths.bin"), "binary")
        self.DBPackages = FileIO:ReadScriptData(Path:Combine(self.DataDirectory, "PackagesPaths.bin"), "binary")
        self.WorldSounds = FileIO:ReadScriptData(Path:Combine(self.DataDirectory, "WorldSounds.bin"), "binary")
        self.DefaultAssets = FileIO:ReadScriptData(Path:Combine(self.DataDirectory, "DefaultAssets.bin"), "binary")

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

            if typ == UNIT_LOAD or typ == ADD then
                self:ReadCustomPackageConfig(id, child, directory)
            elseif typ and path then
                path = Path:Normalize(path)
                local file_path = Path:Combine(directory, path) ..".".. typ
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
	local current_pkg_ids
    self:log("[GeneratePackageData] Writing package data...")
    if file then
        for line in file:lines() do
            if string.sub(line, 1, 1) == "@" then
				current_pkg = string.sub(line, 2)
				current_pkg_ids = line:sub(2, 9) == "Idstring"
			elseif current_pkg then
				local pkg
				if not current_pkg_ids then
					packages_paths[current_pkg] = packages_paths[current_pkg] or {}
					pkg = packages_paths[current_pkg]
                end
                
				local path, typ = unpack(string.split(line, "%."))
                if pkg then
                    if typ then -- Added typ check here
                        pkg[typ] = pkg[typ] or {}
                    end
                end
                if typ then -- Added typ check here
                    paths[typ] = paths[typ] or {}
                
                    if DB:has(typ, path) then
                        paths[typ][path] = true
                        if pkg then
                            pkg[typ][path] = true
                        end
                    end
                end
            end
        end
        file:close()
        self:log("[GeneratePackageData] Done!")
    else
        self:log("[GeneratePackageData] packages.txt is missing...")
    end
    
    FileIO:WriteScriptData(Path:Combine(self.ModPath, "Data", "Paths.bin"), paths, "binary")
    FileIO:WriteScriptData(Path:Combine(self.ModPath, "Data", "PackagesPaths.bin"), packages_paths, "binary")
    Global.DBPaths = nil
    self:LoadHashlist()
end

--Gets all emitters and occasionals from extracted .world_sounds
function BLE:GenerateSoundData()
    local sounds = {}
    local function get_sounds(path)
        for _, file in pairs(FileIO:GetFiles(path)) do
            if string.ends(file, ".world_sounds") then
                local data = FileIO:ReadScriptData(Path:Combine(path, file), "binary")
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
    FileIO:WriteScriptData(Path:Combine(self.ModPath, "Data", "WorldSounds.bin"), sounds, "binary")
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
    FileIO:WriteScriptData(Path:Combine(self.ModPath, "Data", "DefaultAssets.bin"), self.DefaultAssets, "binary")
    Global.DefaultAssets = self.DefaultAssets
end

function BLE:LoadCustomAssetsToHashList(add, directory)
    for _, v in pairs(add) do
        if type(v) == "table" then
            local path = v.path
            local typ = v._meta
            if typ == UNIT_LOAD or typ == ADD then
                self:LoadCustomAssetsToHashList(v, directory)
            else
                path = Path:Normalize(path)

                local file_path = Path:Combine(directory, path) ..".".. typ
				if FileIO:Exists(file_path) then
					self.DBPaths[typ] = self.DBPaths[typ] or {}
					self.DBPaths[typ][path] = true
					self.Utils.allowed_units[path] = true
                end
            end
        end
    end
end

function BLE:Update(t, dt)
    for _, manager in pairs(self.Updaters) do
        if manager.update then
            manager:update(t, dt)
        end
    end
    if self.FileWatcher then
        self.FileWatcher:Update(t, dt)
    end
end

function BLE:PausedUpdate(t, dt)
    for _, manager in pairs(self.Updaters) do
        if manager.paused_update then
            manager:paused_update(t, dt)
        end
    end
    if self.FileWatcher then
        self.FileWatcher:Update(t, dt)
    end
end

function BLE:SetLoadingText(text)
    if alive(Global.LoadingText) then
        local project = BeardLib.current_level and BeardLib.current_level._mod
        local typ = Global.editor_loaded_instance and "Instance level " or "Level "
        local s = typ.. tostring(Global.current_level_id)
        if project then
            s = typ.."in project " .. tostring(project.Name) .. ":" .. tostring(Global.current_level_id)
        end

        if Global.editor_safe_mode then
        	s = "[SAFE MODE]" .. "\n" .. s
        end
        s = s .. "\n" .. tostring(text)
        Global.LoadingText:set_name(s)
        return s
    end
end

Hooks:Add("MenuUpdate", "BeardLibEditorMenuUpdate", ClassClbk(BLE, "Update"))
Hooks:Add("GameSetupUpdate", "BeardLibEditorGameSetupUpdate", ClassClbk(BLE, "Update"))
Hooks:Add("GameSetupPauseUpdate", "BeardLibEditorGameSetupPausedUpdate", ClassClbk(BLE, "PausedUpdate"))
Hooks:Add("LocalizationManagerPostInit", "BeardLibEditorLocalization", function(loc)
	LocalizationManager:add_localized_strings({BeardLibEditorMenu = "BeardLibEditor Menu"})
end)
Hooks:Add("MenuManagerPopulateCustomMenus", "BeardLibEditorInitManagers", ClassClbk(BLE, "InitManagers"))
