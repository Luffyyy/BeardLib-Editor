if not _G.BeardLibEditor then
    _G.BeardLibEditor = ModCore:new(ModPath .. "mod_config.xml")

    local self = BeardLibEditor

    self.HooksDirectory = self.ModPath .. "Hooks/"
    self.ClassDirectory = self.ModPath .. "Classes/"
    self.managers = {}
    self._replace_script_data = {}

    self.DBPaths = {}
    self.DBEntries = {}

    self.classes = {
        "EditorParts/ElementEditor.lua",
        "EditorParts/UnitEditor.lua",
        "EditorParts/GameOptions.lua",
        "EditorParts/SpawnSearch.lua",
        "EditorParts/UpperMenu.lua",
        "EditorParts/EditorConsole.lua",
        "EnvironmentEditorManager.lua",
        "EnvironmentEditorHandler.lua",
        "ScriptDataConverterManager.lua",
        "MapEditor.lua",
        "LoadLevelMenu.lua",
        "OptionCallbacks.lua"
    }

    self.hook_files = {
        ["core/lib/managers/mission/coremissionmanager"] = "Coremissionmanager.lua",
        ["core/lib/managers/coreshapemanager"] = "Coreshapemanager.lua",
        ["core/lib/utils/dev/editor/coreworlddefinition"] = "Coreworlddefinition.lua",
        ["lib/utils/game_state_machine/gamestatemachine"] = "Gamestatemachine.lua",
        ["lib/setups/gamesetup"] = "Gamesetup.lua",
        ["lib/states/editorstate"] = "EditorState.lua",
        ["lib/managers/navigationmanager"] = "Navigationmanager.lua",
        ["lib/managers/navfieldbuilder"] = "Navfieldbuilder.lua"
    }
end

function BeardLibEditor:_init()
    self:LoadClasses()
    self:init_modules()
    if not PackageManager:loaded("core/packages/editor") then
        PackageManager:load("core/packages/editor")
    end
    self.managers.EnvironmentEditor = EnvironmentEditorManager:new()
    self.managers.ScriptDataConveter = ScriptDataConveterManager:new()

    self:LoadHashlist()
end

function BeardLibEditor:LoadClasses()
    for _, clss in pairs(self.classes) do
        dofile(self.ClassDirectory .. clss)
    end
end

function BeardLibEditor:LoadHashlist()        
    self:log("Loading Hashlist")
    local has_hashlist = DB:has("idstring_lookup", "idstring_lookup") 
    local function AddPathEntry(line, typ)
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
    local types = clone(BeardLib.script_data_types)
    table.insert(types, "unit")
	if has_hashlist then 
        local file = DB:open("idstring_lookup", "idstring_lookup")
        if file ~= nil then
            --Iterate through each string which contains _ or /, which should include all the filepaths in the idstring_lookup
            for line in string.gmatch(file:read(), "[%w_/]+%z") do
                --Remove the Zero byte at the end of the path
                line = string.sub(line, 1, #line - 1)

                for _, typ in pairs(types) do
                    self.DBPaths[typ] = self.DBPaths[typ] or {}
                    if DB:has(typ, line) then
                        table.insert(self.DBPaths[typ], line)
                        AddPathEntry(line, typ)
                        --I wish I could break so we don't have to iterate more than needed, but some files exist with the same name but a different type
                        --break
                    end
                end
            end
            file:close()
        end
    else
        local lines = io.lines(self.ModPath .. "list.txt", "r")
        if lines then
            for line in lines do
                for _, typ in pairs(types) do
                    self.DBPaths[typ] = self.DBPaths[typ] or {}
                    if DB:has(typ, line) then
                        table.insert(self.DBPaths[typ], line)
                        AddPathEntry(line, typ)                    
                    end
                end
            end
        else
            self:log("Failed Loading Hashlist.")
        end
    end       
    for typ, filetbl in pairs(self.DBPaths) do
        self:log(typ .. " Count: " .. #filetbl)
    end
    self:log("Hashlist Loaded[Method %s]", has_hashlist and "A" or "B")
end

if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if BeardLibEditor.hook_files[requiredScript] then
        dofile( BeardLibEditor.HooksDirectory .. BeardLibEditor.hook_files[requiredScript] )
    end
end

function BeardLibEditor:update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.update then
            manager:update(t, dt)
        end
    end
end

function BeardLibEditor:paused_update(t, dt)
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
            ["BeardLibEditorLoadLevel_title"] = "Load Level"
        })
    end)

    Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibEditorMenu", function( menu_manager, nodes )
        --I'm going to leave this here, but I really don't like it being here
        BeardLibEditor.managers.MapEditor = MapEditor:new()
        BeardLibEditor.managers.Dialog = MenuDialog:new()
        BeardLibEditor.managers.LoadLevel = LoadLevelMenu:new()

        local main_node = MenuHelperPlus:GetNode(nil, BeardLib.MainMenu)

        BeardLibEditor.managers.EnvironmentEditor:BuildNode(main_node)

        BeardLibEditor.managers.ScriptDataConveter:BuildNode(main_node)

        BeardLibEditor.managers.LoadLevel:BuildNode(main_node)
    end)

    function BeardLibEditor:ProcessScriptData(data, path, extension, name)
        for _, sub_data in ipairs(data) do
            if sub_data._meta == "param" then
                local next_data_path = name and name .. "/" .. sub_data.key or sub_data.key

                local next_data_path_key = next_data_path:key()
                BeardLibEditor.managers.EnvironmentEditor:AddHandlerValue(path:key(), next_data_path_key, sub_data.value, next_data_path)
            else
                local next_data_path = name and name .. "/" .. sub_data._meta or sub_data._meta
                self:ProcessScriptData(sub_data, path, extension, next_data_path)
            end
        end
    end

    Hooks:Add("BeardLibPreProcessScriptData", "BeardLibEditorLoadEnvParams", function(PackManager, filepath, extension, data)
        if extension ~= Idstring("environment") then
            return
        end

        if not data or (data and not data.data) then
            return
        end

        BeardLibEditor:ProcessScriptData(data.data, filepath, extension)
    end)



end

if not BeardLibEditor.setup then
    BeardLibEditor:_init()
    BeardLibEditor.setup = true
end
