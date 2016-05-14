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
        "EditorParts/SaveOptions.lua",
        "EditorParts/SpawnSearch.lua",
        "EnvironmentEditorManager.lua",
        "EnvironmentEditorHandler.lua",
        "ScriptDataConverterManager.lua",
        "MapEditor.lua"
    }

    self.hook_files = {
        ["core/lib/managers/mission/coremissionmanager"] = "Coremissionmanager.lua",
        ["core/lib/utils/dev/editor/coreworlddefinition"] = "Coreworlddefinition.lua",
        ["lib/setups/gamesetup"] = "Gamesetup.lua",
        ["lib/managers/navigationmanager"] = "Navigationmanager.lua",
        ["lib/managers/navfieldbuilder"] = "Navfieldbuilder.lua"
    }
end

function BeardLibEditor:_init()
    self:LoadClasses()

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
    local file = DB:open("idstring_lookup", "idstring_lookup")

    self:log("Loading Hashlist")

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

    for typ, filetbl in pairs(self.DBPaths) do
        self:log(typ .. " Count: " .. #filetbl)
    end

    self:log("Hashlist Loaded")
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
            ["BeardLibEditorScriptDataMenu_title"] = "ScriptData Converter"
        })
    end)

    Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibEditorMenu", function( menu_manager, nodes )
        --I'm going to leave this here, but I really don't like it being here
        BeardLibEditor.managers.MapEditor = MapEditor:new()
        BeardLibEditor.managers.Dialog = MenuDialog:new()

        local main_node = MenuHelperPlus:GetNode(nil, BeardLib.MainMenu)

        BeardLibEditor.managers.EnvironmentEditor:BuildNode(main_node)

        BeardLibEditor.managers.ScriptDataConveter:BuildNode(main_node)
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
