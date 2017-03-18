_G.BeardLibEditor = _G.BeardLibEditor or ModCore:new(ModPath .. "mod_config.xml", false, true)
local self = BeardLibEditor
function self:Init()
    self:init_modules()
    self.ExtractDirectory = "assets/extract/"
    self.AssetsDirectory = self.ModPath .. "Assets/"
    self.HooksDirectory = self.ModPath .. "Hooks/"
    self.ClassDirectory = self.ModPath .. "Classes/"
    self.ModuleDirectory = self.ClassDirectory .. "Modules/"
    self.managers = {}
    self.modules = {}
    self.DBPaths = {}
    self.DBEntries = {}   
    self:LoadHashlist()
    self.InitDone = true
end

function self:InitManagers()
    local acc_color = BeardLibEditor.Options:GetValue("AccentColor")
    local M = BeardLibEditor.managers
    if Global.editor_mode then
        M.MapEditor = MapEditor:new()
    end 
    M.Menu = EditorMenu:new()
    M.EnvironmentEditor = EnvironmentEditorManager:new()    
    M.ScriptDataConverter = ScriptDataConverterManager:new()
    M.Dialog = MenuDialog:new()
    M.ListDialog = ListDialog:new({marker_highlight_color = acc_color})
    M.SelectDialog = SelectListDialog:new({marker_highlight_color = acc_color})
    M.ColorDialog = ColorDialog:new({marker_highlight_color = acc_color})
    M.FBD = FileBrowserDialog:new({marker_highlight_color = acc_color})

    M.MapProject = MapProjectManager:new()
    M.LoadLevel = LoadLevelMenu:new()
    M.EditorOptions = EditorOptionsMenu:new()
    local main_node = MenuHelperPlus:GetNode(nil, BeardLib.config.main_menu)
    M.EnvironmentEditor:BuildNode(main_node)
end

function self:RegisterModule(key, module)
    if not self.modules[key] then
        self:log("Registered module editor with key %s", key)
        self.modules[key] = module
    else
        self:log("[ERROR] Module editor with key %s already exists", key or "")
    end
end

function self:LoadHashlist()        
    self:log("Loading Hashlist")
    local has_hashlist = DB:has("idstring_lookup", "idstring_lookup")     
    local types = clone(BeardLib.config.script_data_types)
    table.insert(types, "unit")
    table.insert(types, "texture")
    table.insert(types, "movie")
    local function ProcessLine(line)
        local path
        for _, typ in pairs(types) do
            self.DBPaths[typ] = self.DBPaths[typ] or {}           

            if DB:has(typ, line) then             
                path = true
                table.insert(self.DBPaths[typ], line)
    
                local path_split = string.split(line, "/")
                local curr_tbl = self.DBEntries
                local filename = table.remove(path_split)
                for _, part in pairs(path_split) do
                    curr_tbl[part] = curr_tbl[part] or {}
                    curr_tbl = curr_tbl[part]
                end
                table.insert(curr_tbl, {
                    path = line,
                    name = filename,
                    file_type = typ
                })
            end
        end
        if not path then
            self.DBPaths.other = self.DBPaths.other or {}
            table.insert(self.DBPaths.other, line)
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
                --Iterate through each string which contains _ or /, which should include all the filepaths in the idstring_lookup
                for line in string.gmatch(file:read(), "[%w_/]+%z") do ProcessLine(string.sub(line, 1, #line - 1)) end
                file:close()
            end
        else
            local lines = io.lines(self.ModPath .. "list.txt", "r")
            if lines then for line in lines do ProcessLine(line) end
            else self:log("Failed Loading Outside Hashlist.") end
        end  
        self:log("%s Hashlist Loaded", has_hashlist and "Inside" or "Outside")   
        Global.DBPaths = self.DBPaths
        Global.DBEntries = self.DBEntries 
    end
    for typ, filetbl in pairs(self.DBPaths) do
        self:log(typ .. " Count: " .. #filetbl)
    end
    self:log("Loading Custom Assets to Hashlist")
    local mod = BeardLib.current_map_mod
    if mod and mod._config.level.add then
        for _, v in pairs(mod._config.level.add) do
            if type(v) == "table" then
                self.DBPaths[v._meta] = self.DBPaths[v._meta] or {}
                if not table.contains(self.DBPaths[v._meta], v.path) then
                    table.insert(self.DBPaths[v._meta], v.path)
                end
            end
        end
    end
end

function self:update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.update then
            manager:update(t, dt)
        end
    end
end

function self:paused_update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.paused_update then
            manager:paused_update(t, dt)
        end
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
    function MenuCallbackHandler:_dialog_end_game_yes()
        Global.editor_mode = nil
        managers.platform:set_playing(false)
        managers.job:clear_saved_ghost_bonus()
        managers.statistics:stop_session({quit = true})
        managers.savefile:save_progress()
        managers.job:deactivate_current_job()
        managers.gage_assignment:deactivate_assignments()
        if Network:multiplayer() then
            Network:set_multiplayer(false)
            managers.network:session():send_to_peers("set_peer_left")
            managers.network:queue_stop_network()
        end
        managers.network.matchmake:destroy_game()
        managers.network.voice_chat:destroy_voice()
        managers.groupai:state():set_AI_enabled(false)
        managers.menu:post_event("menu_exit")
        managers.menu:close_menu("menu_pause")
        setup:load_start_menu()
    end    
end

if Hooks then
    Hooks:Add("MenuUpdate", "BeardLibEditorMenuUpdate", function( t, dt )
        BeardLibEditor:update(t, dt)
    end)

    Hooks:Add("GameSetupUpdate", "BeardLibEditorGameSetupUpdate", function( t, dt )
        BeardLibEditor:update(t, dt)
    end)

    Hooks:Add("GameSetupPauseUpdate", "BeardLibEditorGameSetupPausedUpdate", function(t, dt)
        BeardLibEditor:paused_update(t, dt)
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

    Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibEditorMenu", function(menu_manager, nodes)
        BeardLibEditor:InitManagers()
    end)

    function self:ProcessScriptData(data, path, extension, name)
        for _, sub_data in ipairs(data) do
            if sub_data._meta == "param" then
                local next_data_path = name and name .. "/" .. sub_data.key or sub_data.key

                local next_data_path_key = next_data_path:key()
                self.managers.EnvironmentEditor:AddHandlerValue(path:key(), next_data_path_key, sub_data.value, next_data_path)
            else
                local next_data_path = name and name .. "/" .. sub_data._meta or sub_data._meta
                self:ProcessScriptData(sub_data, path, extension, next_data_path)
            end
        end
    end

    Hooks:Add("BeardLibPreProcessScriptData", "BeardLibEditorLoadEnvParams", function(PackManager, filepath, extension, data)
        if extension == Idstring("environment") and data and data.data then
            BeardLibEditor:ProcessScriptData(data.data, filepath, extension)
        end
    end)
end

if not BeardLibEditor.InitDone then
    BeardLibEditor:Init()
end



