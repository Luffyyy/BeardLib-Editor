local ret, err = pcall(function()
log("Editor")
if not _G.BeardLibEditor then
    _G.BeardLibEditor = ModCore:new(ModPath .. "mod_config.xml")
    
    local self = BeardLibEditor
    
    self.HooksDirectory = "Hooks/"
    self.ClassDirectory = "Classes/"
    self.managers = {}
    self._replace_script_data = {}
    
    self.DBPaths = {}
    self.DBEntries = {}
    
    self.classes = {
        "EnvironmentEditorManager.lua",
        "EnvironmentEditorHandler.lua",      
        "ScriptDataConverterManager.lua",          
        "MapEditor.lua"
    }

    self.hook_files = {
        ["core/lib/managers/mission/coremissionmanager"] = "Coremissionmanager.lua",
        ["core/lib/utils/dev/editor/coreworlddefinition"] = "Coreworlddefinition.lua",
        ["lib/setups/gamesetup"] = "Gamesetup.lua",
        ["lib/managers/navigationmanager"] = "navigationmanager.lua",      
        ["lib/managers/navfieldbuilder"] = "navfieldbuilder.lua"
    }
end

function BeardLibEditor:_init()
    self.managers.EnvironmentEditor = EnvironmentEditorManager:new()
    self.managers.ScriptDataConveter = ScriptDataConveterManager:new()
    
    log("init editor")
    
    self:LoadHashlist()
end

function BeardLibEditor:LoadHashlist()
    local file = DB:open("idstring_lookup", "idstring_lookup")
    
    self:log("Loading Hashlist")
    
    local function AddPathEntry(line, typ)
        local path_split = string.split(line, "/")
        local curr_tbl = self.DBEntries
        
        local filename = table.remove(path_split, #path_split)
        
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
        dofile( BeardLibEditor.ModPath .. BeardLibEditor.HooksDirectory .. BeardLibEditor.hook_files[requiredScript] )
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
        --Because of GUI manager 3:
        BeardLibEditor.managers.MapEditor = MapEditor:new()
        BeardLibEditor.managers.Dialog = MenuDialog:new()
    
        local main_node = MenuHelperPlus:GetNode(nil, BeardLib.MainMenu)
        
        BeardLibEditor.managers.EnvironmentEditor:BuildNode(main_node)
        
        BeardLibEditor.managers.ScriptDataConveter:BuildNode(main_node)
    end)
end

if not BeardLibEditor.setup then
    for _, class in pairs(BeardLibEditor.classes) do
        dofile(BeardLibEditor.ModPath .. BeardLibEditor.ClassDirectory .. class)
    end
    
    BeardLibEditor:_init()
    BeardLibEditor.setup = true
end

end)

--if not ret then 
log(tostring(err)) 
--then