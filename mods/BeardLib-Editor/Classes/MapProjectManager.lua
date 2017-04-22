MapProjectManager = MapProjectManager or class()
local U = BeardLib.Utils
function MapProjectManager:init()
    self._templates_directory = U.Path:Combine(BeardLibEditor.ModPath, "Templates")
    local data = FileIO:ReadFrom(U.Path:Combine(self._templates_directory, "Project/main.xml"))
    if data then
        self._main_xml_template = ScriptSerializer:from_custom_xml(data)
    else
        BeardLibEditor:log("[ERROR] Failed reading main.xml template!")
    end
    data = FileIO:ReadFrom(U.Path:Combine(self._templates_directory, "LevelModule.xml"))
    self._level_module_template = ScriptSerializer:from_custom_xml(data)

    local menu = BeardLibEditor.managers.Menu
    self._diffs = {
        "Normal",
        "Hard",
        "Very Hard",
        "Overkill",
        "Mayhem",
        "Death Wish",
        "One Down"
    }       
    self._menu = menu:make_page("Projects")
    MenuUtils:new(self)
    local btns = self:DivGroup("QuickActions", {w = 300})
    self:Button("NewProject", callback(self, self, "new_project_dialog"), {group = btns})
    self:Button("CloneExistingHeist", callback(self, self, "select_narr_as_project"), {group = btns})
    self:Button("EditExistingProject", callback(self, self, "select_project_dialog"), {group = btns})
    self._curr_editing = self:DivGroup("CurrEditing")
    self:set_edit_title()
end

function MapProjectManager:current_level(data)
    for _, level in pairs(BeardLib.Utils:GetNodeByMeta(data, "level", true) or {}) do
        if level.id == Global.game_settings.level_id then
            return level
        end
    end
    return nil
end

function MapProjectManager:current_mod()
    return BeardLib.current_level and BeardLib.current_level._mod
end

function MapProjectManager:maps_path()
    return BeardLib.current_level._config.include.directory
end

function MapProjectManager:current_path()
    local mod = self:current_mod() 
    return mod and mod.ModPath
end

function MapProjectManager:current_level_path()
    local path = self:current_path()
    return path and U.Path:Combine(path, self:maps_path())
end

function MapProjectManager:set_edit_title(title)
    self:GetItem("CurrEditing"):SetText("Currently Editing: ".. (title or "None"))
end

function MapProjectManager:get_projects_list()
    local list = {}
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        table.insert(list, {name = mod._clean_config.name, mod = mod})
    end
    return list
end

function MapProjectManager:get_project_by_narrative_id(narr)
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        local narrative = U:GetNodeByMeta(data, "narrative")
        if narrative.id == narr.id then
            return mod
        end
    end
end

function MapProjectManager:get_packages_of_level(level)
    local dir = "levels/"..level.world_name .. "/"
    local packages = {dir.."world"}
    local ext = Idstring("mission")
    local path = Idstring(dir.."mission")
    if PackageManager:has(ext, path) then
        local data = PackageManager:script_data(ext, path)
        for c in pairs(data) do
            local p = dir..c.."/"..c
            if PackageManager:package_exists(p) then
                table.insert(packages, p)
            end
        end
    end
    return packages
end

function MapProjectManager:get_level_by_id(t, id)
    local levels = U:GetNodeByMeta(t, "level", true)
    for _, level in pairs(levels) do
        if level.id == id then
            return level
        end
    end
end

function MapProjectManager:get_clean_data(t)
    local data = U:CleanCustomXmlTable(deep_clone(t), true)
    local narrative = U:GetNodeByMeta(data, "narrative")
    U:RemoveAllNumberIndexes(narrative, true)
    for _, v in pairs(narrative.chain) do
        v = U:RemoveAllNumberIndexes(v, true)
    end
    for _, level in pairs(U:GetNodeByMeta(data, "level", true)) do
        U:RemoveAllNumberIndexes(level, true)
        for _, v in pairs({"include", "assets", "script_data_mods", "add"}) do
            if level and level[v] then
                level[v] = BeardLib.Utils:CleanCustomXmlTable(level[v])
            end
        end
    end
    return data
end

function MapProjectManager:existing_narr_new_project_clbk(selection, t, name)
    if t then
        local data = self:get_clean_data(self._main_xml_template)
        local narr = U:GetNodeByMeta(data, "narrative")
        table.merge(narr, selection.narr)
        data.name = t.name
        narr.id = t.name
        local cv = narr.contract_visuals
        narr.max_mission_xp = cv and cv.max_mission_xp or narr.max_mission_xp
        narr.min_mission_xp = cv and cv.min_mission_xp or narr.min_mission_xp
        narr.contract_visuals = nil
        narr.name_id = nil
        narr.briefing_id = nil
        local narr_pkg = narr.package
        narr.package = nil --packages should only be in levels.
        local mod_path = U.Path:Combine(BeardLib.config.maps_dir, data.name)
        local levels_path = U.Path:Combine(mod_path, "levels")
        local to_unload = {}
        PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
        for i, level_in_chain in pairs(narr.chain) do
            if type(level_in_chain) == "table" then
                self:new_level_dialog(level_in_chain.level_id, function(name)
                    local level = clone(tweak_data.levels[level_in_chain.level_id])
                    table.insert(data, level)
                    level._meta = "level"
                    level.assets = {}
                    level.id = name
                    level_in_chain.level_id = level.id
                    level.name_id = nil
                    level.briefing_id = nil 
                    level.add = {directory = "assets"}
                    level.script_data_mods = BeardLib.Utils:CleanCustomXmlTable(deep_clone(self._level_module_template).script_data_mods)
                    local level_path = U.Path:Combine(levels_path, level.id)
                    local level_dir = "levels/"..level.world_name .. "/"
                    local packages = type(level.package) == "string" and {level.package} or level.package or {}
                    if narr_pkg then
                        table.insert(packages, narr_pkg)
                    end
                    table.insert(packages, level_dir.."world")
                    for _, p in pairs(packages) do
                        if not PackageManager:loaded(p) then
                            if PackageManager:package_exists(p.."_init") then
                                PackageManager:load(p.."_init") 
                               table.insert(to_unload, p.."_init")
                            end
                            if PackageManager:package_exists(p) then
                                PackageManager:load(p)
                                table.insert(to_unload, p)
                            end
                        end
                    end
                    level.include = {directory = U.Path:Combine("levels", level.id)}
                    local world_data = PackageManager:script_data(Idstring("world"), Idstring(level_dir.."world"))
                    local continents_data = PackageManager:script_data(Idstring("continents"), Idstring(level_dir.."continents"))
                    table.insert(level.include, {_meta = "file", file = "world.world", type = "generic_xml", data = world_data})
                    table.insert(level.include, {_meta = "file", file = "continents.continents", type = "custom_xml", data = continents_data})
                    table.insert(level.include, {_meta = "file", file = "mission.mission", type = "custom_xml", data = PackageManager:script_data(Idstring("mission"), Idstring(level_dir.."mission"))})
                    table.insert(level.include, {_meta = "file", file = "nav_manager_data.nav_data", type = "generic_xml", data = PackageManager:script_data(Idstring("nav_data"), Idstring(level_dir.."nav_manager_data"))})
                    if DB:has(Idstring("cover_data"), Idstring(level_dir.."cover_data")) then
                        table.insert(level.include, {_meta = "file", file = "cover_data.cover_data", type = "custom_xml", data = PackageManager:script_data(Idstring("cover_data"), Idstring(level_dir.."cover_data"))})
                    end        
                    if DB:has(Idstring("world_sounds"), Idstring(level_dir.."world_sounds")) then
                        table.insert(level.include, {_meta = "file", file = "world_sounds.world_sounds", type = "custom_xml", data = PackageManager:script_data(Idstring("world_sounds"), Idstring(level_dir.."world_sounds"))})
                    end
                    local continents = {}
                    local missions = {}
                    for c in pairs(continents_data) do
                        local p = level_dir..c.."/"..c          
                        if PackageManager:package_exists(p) then
                            table.insert(packages, p)
                        end                        
                        local p_init = p.."_init"
                        if PackageManager:package_exists(p_init) then
                            PackageManager:load(p_init)
                            continents[c] = PackageManager:script_data(Idstring("continent"), Idstring(p))
                            missions[c] = PackageManager:script_data(Idstring("mission"), Idstring(p))
                            PackageManager:unload(p_init)
                        end
                    end
                    world_data.brush = nil --Figure out what to do with brushes...
                    level.world_name = nil      
                    level.package = nil      
                    level.packages = packages
                    for name, c in pairs(continents) do
                        local c_path = U.Path:Combine(name, name)
                        table.insert(level.include, {_meta = "file", file = c_path..".continent", type = "custom_xml", data = c})
                        table.insert(level.include, {_meta = "file", file = c_path..".mission", type = "generic_xml", data = missions[name]})
                    end
                    for k, include in pairs(level.include) do
                        if type(include) == "table" then
                            FileIO:WriteScriptDataTo(U.Path:Combine(level_path, include.file), include.data, include.type)
                            include.data = nil
                        end
                    end
                    if i == #narr.chain then -- temp
                        PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
                        FileIO:WriteScriptDataTo(U.Path:Combine(mod_path, "main.xml"), data, "custom_xml")
                        BeardLib.managers.MapFramework:Load()
                        BeardLib.managers.MapFramework:RegisterHooks()
                        for _, p in pairs(to_unload) do
                            if PackageManager:loaded(p) then
                                DelayedCalls:Add("UnloadPKG"..tostring(p), 0.01, function()
                                    log("Unloading temp package " .. tostring(p))
                                    PackageManager:unload(p)
                                end)
                            end
                        end
                    end
                end)
            end
        end
    end
end

function MapProjectManager:select_narr_as_project()
    local levels = {}
    for id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.custom then
            table.insert(levels, {name = id, narr = narr})
        end
    end
    BeardLibEditor.managers.ListDialog:Show({
        list = levels,
        callback = function(selection)
            BeardLibEditor.managers.ListDialog:hide()   
            self:new_project_dialog("", callback(self, self, "existing_narr_new_project_clbk", selection))
        end
    })  
end


function MapProjectManager:select_project_dialog()
    BeardLibEditor.managers.ListDialog:Show({
        list = self:get_projects_list(),
        callback = callback(self, self, "select_project")
    }) 
end

function MapProjectManager:select_project(selection)
    self:_select_project(selection.mod)
end

function MapProjectManager:reload_mod(old_name, name, save_prev)
    local mod = self._current_mod
    for _, module in pairs(mod._modules) do
        module.Registered = false
    end
    BeardLib.managers.MapFramework._loaded_mods[old_name] = nil
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
    if BeardLib.managers.MapFramework._loaded_mods[name] then
        self:_select_project(BeardLib.managers.MapFramework._loaded_mods[name], save_prev)
    else
        BeardLibEditor:log("[Warning] Something went wrong while trying reload the project")
    end
end

function MapProjectManager:_select_project(mod, save_prev)
    if save_prev then
        local save = self:GetItem("SaveProject")
        if save then
            save:RunCallback()
        end
    end
    self._current_mod = mod
    BeardLibEditor.managers.ListDialog:hide()
    self:edit_main_xml(mod._clean_config, function()        
        local t = self._current_data
        local id = t.orig_id or t.name
        local map_path = U.Path:Combine(BeardLib.config.maps_dir, id)
        local levels = U:GetNodeByMeta(t, "level", true)
        local something_changed
        for _, level in pairs(levels) do
            if level.orig_id then
                local include_dir = U.Path:Combine("levels", level.id)
                level.include.directory = include_dir
                FileIO:MoveTo(U.Path:Combine(map_path, "levels", level.orig_id), U.Path:Combine(map_path, include_dir))
                tweak_data.levels[level.orig_id] = nil
                table.delete(tweak_data.levels._level_index, level.orig_id)
                level.orig_id = nil
                something_changed = true
            end
        end
        t.orig_id = nil
        FileIO:WriteTo(U.Path:Combine(map_path, "main.xml"), FileIO:ConvertToScriptData(t, "custom_xml"))
        mod._clean_config = t
        if t.name ~= id then
            tweak_data.narrative.jobs[id] = nil
            table.delete(tweak_data.narrative._jobs_index, id)
            FileIO:MoveTo(map_path, U.Path:Combine(BeardLib.config.maps_dir, t.name))
            something_changed = true
        end
        if something_changed then
            self:reload_mod(id, t.name)
        end
    end)
end

function MapProjectManager:new_project_dialog(name, clbk)
    managers.system_menu:show_keyboard_input({
        text = name or "",
        title = "Enter a name for the project:",
        callback_func = callback(self, self, "new_project_dialog_clbk", type(clbk) == "function" and clbk or callback(self, self, "new_project_clbk")),
    }) 
end

function MapProjectManager:new_level_dialog(name, clbk)
    managers.system_menu:show_keyboard_input({
        text = name or "",
        title = "Enter a name for the level:",
        callback_func = callback(self, self, "new_level_dialog_clbk", type(clbk) == "function" and clbk or callback(self, self, "create_new_level")),
    }) 
end

function MapProjectManager:delete_level_dialog(level)
    QuickMenuPlus:new("Are you sure?", "This will delete the level from your project! [Note: custom levels that are inside your project will be deleted entirely]", 
        {{text = "Yes", callback = callback(self, self, "delete_level_dialog_clbk", level)}, {text = "No"}})
end

function MapProjectManager:delete_level_dialog_clbk(level)
    local t = self._current_data
    if not t then
        BeardLibEditor:log("[ERROR] Project needed to delete levels!")
        return
    end
    local chain = U:GetNodeByMeta(self._current_data, "narrative").chain
    local level_id = type(level) == "table" and level.id or level
    for k, v in pairs(chain) do
        if v.level_id == level_id then
            chain[k] = nil
            break
        end
    end
    if type(level) == "table" then
        FileIO:Delete(U.Path:Combine(BeardLib.config.maps_dir, t.name, level.include.directory))
        table.delete(t, level)
    end
    self:reload_mod(t.name, t.name, true)
end

function MapProjectManager:create_new_level(name)
    local t = self._current_data
    if not t then
        BeardLibEditor:log("[ERROR] Project needed to create levels!")
        return
    end
    local narr = U:GetNodeByMeta(t, "narrative")
    local level = U:RemoveAllNumberIndexes(self._level_module_template, true)
    table.insert(t, level)
    level.id = name
    local proj_path = U.Path:Combine(BeardLib.config.maps_dir, t.name)
    local level_path = U.Path:Combine("levels", level.id)
    table.insert(narr.chain, {level_id = level.id, type = "d", type_id = "heist_type_assault"})
    level.include.directory = level_path
    FileIO:WriteTo(U.Path:Combine(proj_path, "main.xml"), FileIO:ConvertToScriptData(t, "custom_xml"))
    FileIO:CopyTo(U.Path:Combine(self._templates_directory, "Level"), U.Path:Combine(proj_path, level_path))
    self:reload_mod(t.name, t.name, true)
end

function MapProjectManager:create_new_narrative(name)
    local data = self:get_clean_data(self._main_xml_template)
    local narr = U:GetNodeByMeta(data, "narrative")
    data.name = name
    narr.id = name
    local proj_path = U.Path:Combine(BeardLib.config.maps_dir, name)
    FileIO:CopyTo(U.Path:Combine(self._templates_directory, "Project"), proj_path)
    FileIO:MakeDir(U.Path:Combine(proj_path, "assets"))
    FileIO:MakeDir(U.Path:Combine(proj_path, "levels"))
    FileIO:WriteTo(U.Path:Combine(proj_path, "main.xml"), FileIO:ConvertToScriptData(data, "custom_xml"))  
    return data 
end

function MapProjectManager:new_level_dialog_clbk(clbk, success, name)
    if success then
        if tweak_data.levels[name] then
            QuickMenuPlus:new("Error", string.format("A level with the id %s already exists! Please use a unique id", name))
            self:new_level_dialog(name, clbk)
            return
        elseif name == "" then
            QuickMenuPlus:new("Error", string.format("Id cannot be empty!", name))
            self:new_level_dialog(name, clbk)
            return
        end
    else
        return
    end
    clbk(name)
end

function MapProjectManager:new_project_dialog_clbk(clbk, success, name)
    if success then
        if tweak_data.narrative.jobs[name] then
            QuickMenuPlus:new("Error", string.format("A narrative with the id %s already exists! Please use a unique id", name))
            self:new_project_dialog(name, clbk)
            return
        elseif name == "" then
            QuickMenuPlus:new("Error", string.format("Id cannot be empty!", name))
            self:new_project_dialog(name, clbk)
            return
        end
    else
        return
    end
    clbk(self:create_new_narrative(name), name)
end
function MapProjectManager:new_project_clbk(data, name)
    local save = self:GetItem("SaveProject")
    if save then
        save:RunCallback()
    end
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
    local mod = BeardLib.managers.MapFramework._loaded_mods[name]
    self:_select_project(mod, true)
    QuickMenuPlus:new("New Project", "Do you want to create a new level for the project?", {{text = "Yes", callback = callback(self, self, "new_level_dialog")}, {text = "No"}})
end

function MapProjectManager:add_exisiting_level_dialog()
    local levels = {}
    for k, level in pairs(tweak_data.levels) do
        if type(level) == "table" then
            table.insert(levels, k)
        end
    end
    BeardLibEditor.managers.ListDialog:Show({
        list = levels,
        callback = function(id)
            local chain = U:GetNodeByMeta(self._current_data, "narrative").chain
            table.insert(chain, {level_id = id, type = "d", type_id = "heist_type_assault"})
            BeardLibEditor.managers.ListDialog:hide()
            self:_select_project(self._current_mod, true)
        end
    })
end

function MapProjectManager:set_crimenet_videos_dialog()
    local t = self._current_data
    local crimenet_videos = U:GetNodeByMeta(self._current_data, "narrative").crimenet_videos
    BeardLibEditor.managers.SelectDialog:Show({
        selected_list = crimenet_videos,
        list = BeardLibEditor.Utils:FromHashlist({type = "movie", path = "movies/"}),
        callback = function(list) crimenet_videos = list end
    })
end

function MapProjectManager:edit_main_xml(data, save_clbk)
    self:ClearItems(self._curr_editing)
    self:set_edit_title(tostring(data.name))
    data = self:get_clean_data(data)
    local narr = U:GetNodeByMeta(data, "narrative")
    local levels = U:GetNodeByMeta(data, "level", true)
    if not narr then
        BeardLibEditor:log("[ERROR] Narrative data is missing from the main.xml!")
        return
    end
    local up = callback(self, self, "set_project_data")
    local narrative = self:DivGroup("Narrative", {group = self._curr_editing})
    self:TextBox("ProjectName", up, data.name, {group = narrative})
    local contacts = table.map_keys(tweak_data.narrative.contacts)
    self:ComboBox("Contact", up, contacts, table.get_key(contacts, narr.contact), {group = narrative})
    self:TextBox("BriefingEvent", up, narr.briefing_event, {group = narrative})
    narr.crimenet_callouts = type(narr.crimenet_callouts) == "table" and narr.crimenet_callouts or {narr.crimenet_callouts}
    narr.debrief_event = type(narr.debrief_event) == "table" and narr.debrief_event or {narr.debrief_event}

    self:TextBox("DebriefEvent", up, table.concat(narr.debrief_event, ","), {group = narrative})
    self:TextBox("CrimenetCallouts", up, table.concat(narr.crimenet_callouts, ","), {group = narrative})
    self:Button("SetCrimenetVideos", callback(self, self, "set_crimenet_videos_dialog"), {group = narrative})
    local chain = self:DivGroup("Chain", {group = self._curr_editing})
    self:Button("AddExistingLevel", callback(self, self, "add_exisiting_level_dialog"), {group = chain})
    self:Button("AddNewLevel", callback(self, self, "new_level_dialog"), {group = chain})
    local function get_level(level_id)
        for _, v in pairs(levels) do
            if v.id == level_id then
                return v
            end
        end
    end
    for _, level_in_chain in pairs(narr.chain) do
        if type(level_in_chain) == "table" then
            local level_id = level_in_chain.level_id
            local level = get_level(level_id)
            local btn = self:Button(level_id, level and function() self:edit_main_xml_level(data, level, level_in_chain, save_clbk) end, {group = chain})
            self:SmallButton(tostring(i), callback(self, self, "delete_level_dialog", level and level or level_id), btn, {text = "x", marker_highlight_color = Color.red})
        end
    end
    self._contract_costs = {}
    self._experience_multipliers = {}
    self._max_mission_xps = {}
    self._min_mission_xps = {}
    self._payouts = {}  
    local function convertnumber(n)
        local t = {}
        for i=1, #self._diffs do
            table.insert(t, n)
        end
        return t
    end
    narr.contract_cost = type(narr.contract_cost) == "table" and narr.contract_cost or convertnumber(narr.contract_cost)
    narr.experience_mul = type(narr.experience_mul) == "table" and narr.experience_mul or convertnumber(narr.experience_mul)
    narr.max_mission_xp = type(narr.max_mission_xp) == "table" and narr.max_mission_xp or convertnumber(narr.max_mission_xp)
    narr.min_mission_xp = type(narr.min_mission_xp) == "table" and narr.min_mission_xp or convertnumber(narr.min_mission_xp)
    narr.payout = type(narr.payout) == "table" and narr.payout or convertnumber(narr.payout)
    local diff_settings = self:DivGroup("DifficultySettings", {group = self._curr_editing})
    for i, diff in pairs(self._diffs) do
        local group = self:Group(diff, {group = diff_settings, closed = true})
        self._contract_costs[i] = self:NumberBox("ContractCost"..i, up, narr.contract_cost[i] or 0, {max = 10000000, min = 0, group = group, text = "Contract Cost"})
        self._experience_multipliers[i] = self:NumberBox("ExperienceMul"..i, up, narr.experience_mul[i] or 0, {max = 5, min = 0, group = group, text = "Stealth XP bonus"})
        self._max_mission_xps[i] = self:NumberBox("MaxMissionXp"..i, up, narr.max_mission_xp[i] or 0, {max = 10000000, min = 0, group = group, text = "Minimum mission XP"})
        self._min_mission_xps[i] = self:NumberBox("minMissionXp"..i, up, narr.min_mission_xp[i] or 0, {max = 100000, min = 0, group = group, text = "Maximum mission XP"})
        self._payouts[i] = self:NumberBox("Payout"..i, up, narr.payout[i] or 0, {max = 100000000, min = 0, group = group, text = "Payout"})
    end 
    self:Button("SaveProject", save_clbk, {group = self._curr_editing})
    self:Button("Close", callback(self, self, "disable"), {group = self._curr_editing})
    self._current_data = data
end

function MapProjectManager:set_project_data(menu, item)
    local t = self._current_data  
    local narr = U:GetNodeByMeta(t, "narrative")
    local old_name = t.orig_id or t.name
    t.name = self:GetItem("ProjectName"):Value()
    local title = tostring(t.name)
    narr.id = self:GetItem("ProjectName"):Value()
    if old_name ~= t.name then
        if t.name == "" or tweak_data.narrative.jobs[t.name] then
            t.name = old_name
            narr.id = old_name
            title = tostring(t.name).."[Warning: current project name already exists or name is empty, not saving name]"
        else
            t.orig_id = t.orig_id or old_name
        end        
    end
    for i in pairs(self._diffs) do
        narr.contract_cost[i] = self._contract_costs[i]:Value()
        narr.experience_mul[i] = self._experience_multipliers[i]:Value()
        narr.max_mission_xp[i] = self._max_mission_xps[i]:Value()
        narr.min_mission_xp[i] = self._min_mission_xps[i]:Value()
        narr.payout[i] = self._payouts[i]:Value()
    end
    narr.crimenet_callouts = narr.crimenet_callouts or {}
    narr.debrief_event = narr.debrief_event or {}
    local callouts = self:GetItem("CrimenetCallouts"):Value()
    local events = self:GetItem("DebriefEvent"):Value()
    narr.crimenet_callouts = callouts:match(",") and string.split(callouts, ",") or {callouts}
    narr.debrief_event = events:match(",") and string.split(events, ",") or {events}
    narr.briefing_event = self:GetItem("BriefingEvent"):Value()
    narr.contact = self:GetItem("Contact"):SelectedItem()
    self:set_edit_title(title)
end

function MapProjectManager:set_mission_assets_dialog()
    local assets = U:GetNodeByMeta(self._current_data, "level").assets
    BeardLibEditor.managers.SelectDialog:Show({
        selected_list = assets,
        list = table.map_keys(tweak_data.assets),
        callback = function(list) assets = list end
    })
end

function MapProjectManager:edit_main_xml_level(data, level, level_in_chain, save_clbk)
    self:ClearItems(self._curr_editing)
    local level_group = self:Group("Level", {group = self._curr_editing})
    local up = callback(self, self, "set_project_level_data", level_in_chain)
    self:TextBox("LevelId", up, level.id, {group = level_group})    
    --self:Button("ManagePackages", nil, {group = level_group}) Should be managed in the map editor imo
    local aitype = table.map_keys(LevelsTweakData.LevelType)
    self:ComboBox("AiGroupType", up, aitype, table.get_key(aitype, level.ai_group_type) or 1, {group = level_group})
    self:TextBox("BriefingDialog", up, level.briefing_dialog, {group = level_group}, {group = level_group})
    self:NumberBox("GhostBonus", up, level.ghost_bonus, {max = 1, min = 0, group = level_group})
    self:NumberBox("MaxBags", up, level.max_bags, {max = 999, min = 0, floats = 0, group = level_group})    
    self:Toggle("TeamAiOff", up, level.team_ai_off, {group = level_group})
    level.intro_event = type(level.intro_event) == "table" and level.intro_event or {level.intro_event}
    level.outro_event = type(level.outro_event) == "table" and level.outro_event or {level.outro_event}
    self:TextBox("IntroEvent", up, table.concat(level.intro_event, ","), {group = level_group})
    self:TextBox("OutroEvent", up, table.concat(level.outro_event, ","), {group = level_group})
    --self:Button("ManageMissionAssets", callback(self, self, "set_mission_assets_dialog"), {group = level_group})
    self:Button("SaveAndGoBackToProject", save_clbk, {group = self._curr_editing})
    self:Button("GoBackToProject", function() self:edit_main_xml(data, save_clbk) end, {group = self._curr_editing})
    self:set_edit_title(tostring(data.name) .. " > " .. tostring( level.id ))
end 

function MapProjectManager:set_project_level_data(level_in_chain)
    local t = self._current_data
    local level = U:GetNodeByMeta(t, "level")   
    local old_name = level.orig_id or level.id
    level.id = self:GetItem("LevelId"):Value()
    local title = tostring(t.name) .. " > " .. tostring(level.id)
    if old_name ~= level.id then
        if level.id == "" and tweak_data.levels[level.id] then
            level.id = old_name
            title = tostring(t.name) .. " > " .. tostring(level.id).."[Warning: current level id already exists or id is empty, not saving Id]"
        else
            level.orig_id = level.orig_id or old_name
        end
    end
    level_in_chain.level_id = level.id
    level.ai_group_type = self:GetItem("AiGroupType"):SelectedItem()
    level.briefing_dialog = self:GetItem("BriefingDialog"):Value()
    level.ghost_bonus = self:GetItem("GhostBonus"):Value()
    level.max_bags = self:GetItem("MaxBags"):Value()
    level.team_ai_off = self:GetItem("TeamAiOff"):Value()
    local intro = self:GetItem("IntroEvent"):Value()
    local outro = self:GetItem("OutroEvent"):Value()
    level.intro_event = intro:match(",") and string.split(intro, ",") or {intro}
    level.outro_event = outro:match(",") and string.split(outro, ",") or {outro}
    self:set_edit_title(title)
end

function MapProjectManager:disable()
    self._current_data = nil
    self._current_mod = nil
    self:ClearItems(self._curr_editing)
    self:set_edit_title()
end