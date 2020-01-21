MapProjectManager = MapProjectManager or class()
local U = BeardLib.Utils
local EU = BLE.Utils
local XML = U.XML
local Project = MapProjectManager
local CXML = "custom_xml"

function Project:init()
    self._diffs = {"Normal", "Hard", "Very Hard", "Overkill", "Mayhem", "Death Wish", "Death Sentence"}
    self._templates_directory = Path:Combine(BLE.ModPath, "Templates")
    self._add_xml_template = self:ReadConfig(Path:Combine(self._templates_directory, "Level/add.xml"))
    self._main_xml_template = self:ReadConfig(Path:Combine(self._templates_directory, "Project/main.xml"))
    self._level_module_template = self:ReadConfig(Path:Combine(self._templates_directory, "LevelModule.xml"))
    self._instance_module_template = self:ReadConfig(Path:Combine(self._templates_directory, "InstanceModule.xml"))

    self._menu = BLE.Menu:make_page("Projects", nil, {align_method = "centered_grid"})
    ItemExt:add_funcs(self)

    local btns = self:pan("QuickActions", {align_method = "centered_grid", inherit_values = {
        offset = 4,
        scrollbar = false,
        text_align = "center"
    }})
    local opt = {w = btns:ItemsWidth() / 3, border_bottom = true}
    btns:button("NewProject", ClassClbk(self, "new_project_dialog", ""), opt)
    btns:button("CloneExistingHeist", ClassClbk(self, "select_narr_as_project"), opt)
    btns:button("EditExistingProject", ClassClbk(self, "select_project_dialog"), opt)

    self:set_edit_title()
end

function Project:Load(data)
    if data then
        self:_select_project(data.selected_mod)
    end
end

function Project:Destroy()
    return {selected_mod = self._current_mod}
end

function Project:ReadConfig(file)
    return FileIO:ReadScriptData(file, CXML, true)
end

function Project:for_each_level(data, func)
    for _, level in pairs(XML:GetNodes(data, "level")) do
        func(level)
    end
    for _, level in pairs(XML:GetNodes(data, "instance")) do
        func(level)
    end
end

function Project:current_level(data)
    for _, level in pairs(XML:GetNodes(data, Global.editor_loaded_instance and "instance" or "level")) do
        if level.id == Global.current_level_id then
            return level
        end
    end
    return nil
end

function Project:get_level_by_id(t, id)
    for _, level in pairs(XML:GetNodes(t, "level")) do
        if level.id == id then
            return level
        end
    end
    for _, level in pairs(XML:GetNodes(t, "instance")) do
        if level.id == id then
            return level
        end
    end
end

function Project:current_mod()
    return BeardLib.current_level and BeardLib.current_level._mod
end

function Project:maps_path()
    return BeardLib.current_level._config.include.directory
end

function Project:save_main_xml(data, no_reload)
    self:save_xml("main.xml", data)
    if not no_reload then
        self:reload_mod(data.name)
    end
end

function Project:save_xml(file, data)
    FileIO:WriteScriptData(self:current_mod():GetRealFilePath(Path:Combine(self:current_path(), file)), data, CXML)
end

function Project:read_xml(file)
    return FileIO:ReadScriptData(self:current_mod():GetRealFilePath(Path:Combine(self:current_path(), file)), CXML, true)
end

function Project:current_path()
    local mod = self:current_mod()
    return mod and mod.ModPath
end

function Project:current_level_path()
    local path = self:current_path()
    return path and Path:Combine(path, self:maps_path())
end

function Project:set_edit_title(title)
   -- self:GetItem("CurrEditing"):SetText("Currently Editing: ".. (title or "None"))
end

function Project:get_projects_list()
    local list = {}
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        table.insert(list, {name = mod._clean_config.name, mod = mod})
    end
    return list
end

function Project:get_project_by_narrative_id(narr)
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        local narrative = XML:GetNode(data, "narrative")
        if narrative and narrative.id == narr.id then
            return mod
        end
    end
end

function Project:get_packages_of_level(level)
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

local ignore_modules = {["GlobalValue"] = true}

function Project:get_mod_and_config()
    local mod = self:current_mod()
    if mod then
        return mod, self:get_clean_config(mod)
    end
    return nil, nil
end

function Project:get_clean_config(mod, do_clone)
    mod = mod or self:current_mod()
    if not mod then
        return
    end
    local config = deep_clone(mod._clean_config)
    if mod._modules then
        for i, module in pairs(mod._modules) do
            if module.clean_table and not ignore_modules[module.type_name] and config[i] then
                module:DoCleanTable(config[i])
            end
        end
    end
    local data = XML:Clean(config)
    return do_clone and deep_clone(data) or data
end

function Project:load_temp_package(p)
    if not PackageManager:loaded(p) and PackageManager:package_exists(p) then
        PackageManager:load(p)
        table.insert(self._packages_to_unload, p)
    end
end

function Project:add_existing_level_to_project(data, narr, level_in_chain, narr_pkg, done_clbk)
    local id = level_in_chain.level_id
    self:new_level_dialog(tostring(id), function(name)
        local level = clone(tweak_data.levels[id])

        table.insert(data, level)
        local packages = type(level.package) == "string" and {level.package} or level.package or {}
        local level_dir = "levels/"..level.world_name .. "/"

        table.merge(level, {
            _meta = "level",
            assets = {},
            id = name,
            add = {directory = "assets"},
            include = {directory = Path:Combine("levels", name)},
            packages = packages,
            script_data_mods = deep_clone(self._level_module_template).script_data_mods
        })

        local preplanning = tweak_data.preplanning.locations[id]
        if preplanning then
            level.preplanning = deep_clone(preplanning)
        end

        if narr_pkg then
            table.insert(packages, narr_pkg)
        end

        local function extra_package(p)
            if not table.contains(packages, p) then
                table.insert(packages, p)
            end
        end

        local custom_level_dir = Path:Combine(BeardLib.config.maps_dir, data.name, "levels", name)
        local function extra_file(name, typ, path, data_func)
            path = path or level_dir
            typ = typ or name
            local data
            local typeid = typ:id()
            local nameid = name:id()
            local inpath = Path:Combine(path, name)
            if PackageManager:has(typeid, inpath:id()) then
                data = PackageManager:script_data(typeid, inpath:id())
                if data_func then
                    data_func(data)
                end
                local infolder = path:gsub(level_dir, "")                
                local file = (infolder:len() > 0 and infolder.."/" or infolder) .. name.."."..typ
                FileIO:WriteScriptData(Path:Combine(custom_level_dir, file), data, "binary")
                table.insert(level.include, {_meta = "file", file = file, type = "binary"})
            else
                BeardLibEditor:log("[add_existing_level_to_project][extra_file] File is unloaded %s", inpath)
            end
            if PackageManager:package_exists(inpath) then
                extra_package(inpath)
            end
            return data
        end

        local function extra_cube_lights()
            local path = level_dir
            local inpath = Path:Combine(path, "cube_lights")
            local typ = "texture"
            local bytes, file_path
            local add = {_meta = "add", directory = "assets"}
            for k, v  in pairs(Global.DBPaths[typ]) do
                if v and k:sub(1, #inpath) == inpath then 
                    bytes = DB:open(typ, k):read()
                    file_path = Path:Combine("levels/mods", name, string.sub(k, #path))
                    FileIO:WriteTo(Path:Combine(BeardLib.config.maps_dir, data.name, "assets", file_path) .. "." .. typ , bytes)
                    table.insert(add, {_meta = "texture", path = file_path})
                end
            end
            FileIO:WriteScriptData(Path:Combine(custom_level_dir, "add.xml"), add, CXML)
        end

        extra_package(level_dir.."world")
        for _, p in pairs(packages) do
            self:load_temp_package(p.."_init")
            self:load_temp_package(p)
        end

        local world_data = extra_file("world", nil, nil, function(data) data.brush = nil end)
        local continents_data = extra_file("continents")
        extra_file("mission")
        extra_file("nav_manager_data", "nav_data")
        extra_file("cover_data")
        extra_file("world_sounds")
        extra_file("world_cameras")

        extra_cube_lights()

        for c in pairs(continents_data) do
            local c_path = Path:Combine(level_dir, c)
            self:load_temp_package(Path:Combine(c_path, c).."_init")
            extra_file(c, "continent", c_path)
            extra_file(c, "mission", c_path)
        end

        level.world_name = nil      
        level.name_id = nil
        level.briefing_id = nil 
        level.package = nil 
        level_in_chain.level_id = name

        if done_clbk then
            done_clbk()
        end
    end, done_clbk)
end

function Project:existing_narr_new_project_clbk_finish(data, narr)
    local mod_path = Path:Combine(BeardLib.config.maps_dir, data.name)
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), ClassClbk(managers.sequence, "clbk_pkg_manager_unit_loaded"))
    FileIO:WriteScriptData(Path:Combine(mod_path, "main.xml"), data, CXML)
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
    BLE.LoadLevel:load_levels()
    for _, p in pairs(self._packages_to_unload) do
        if PackageManager:loaded(p) then
            DelayedCalls:Add("UnloadPKG"..tostring(p), 0.01, function()
                log("Unloading temp package " .. tostring(p))
                PackageManager:unload(p)
            end)
        end
    end
end

function Project:existing_narr_new_project_clbk(selection, t, name)
    if t then
        local data = deep_clone(self._main_xml_template)
        local narr = XML:GetNode(data, "narrative")
        table.merge(narr, deep_clone(selection.narr))
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
        self._packages_to_unload = {}
        PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
        local clbk = ClassClbk(self, "existing_narr_new_project_clbk_finish", data, narr)
        for i, level_in_chain in pairs(narr.chain) do
            local last = i == #narr.chain
            if type(level_in_chain) == "table" then
                if #level_in_chain > 0 then
                    for k, level in pairs(level_in_chain) do
                        self:add_existing_level_to_project(data, narr, level, narr_pkg, last and (k == #level_in_chain) and clbk)
                    end
                else
                    self:add_existing_level_to_project(data, narr, level_in_chain, narr_pkg, last and clbk)
                end
            end
        end
    end
end

function Project:select_narr_as_project()
    local levels = {}
    for id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.custom and not narr.hidden then
            --dunno why the name_id is nil for some of them..
            table.insert(levels, {name = id.." / " .. managers.localization:text((narr.name_id or ("heist_"..id)):gsub("_prof", ""):gsub("_night", "")), narr = narr})
        end
    end
    BLE.ListDialog:Show({
        list = levels,
        callback = function(selection)
            BLE.ListDialog:hide()
            self:new_project_dialog("", ClassClbk(self, "existing_narr_new_project_clbk", selection))
        end
    })
end

function Project:select_project_dialog()
    BLE.ListDialog:Show({
        list = self:get_projects_list(),
        callback = ClassClbk(self, "select_project")
    })
end

function Project:select_project(selection)
    self:_select_project(selection.mod)
end

function Project:reload_mod(name)
    BeardLib.managers.MapFramework._loaded_mods[name] = nil
    BeardLib.managers.MapFramework._loaded_instances = nil
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
    BLE.LoadLevel:load_levels()
end

function Project:save_current_project(mod)
    local t = self._current_data
    local id = t.orig_id or t.name
    local map_path = Path:Combine(BeardLib.config.maps_dir, id)
    local levels = XML:GetNodes(t, "level")
    local something_changed
    for _, level in pairs(levels) do
        if level.orig_id then
            local include_dir = Path:Combine("levels", level.id)
            level.include.directory = include_dir
            if level.add.file then
                level.add.file = Path:Combine(include_dir, "add.xml")
            end
            FileIO:MoveTo(Path:Combine(map_path, "levels", level.orig_id), Path:Combine(map_path, include_dir))
            tweak_data.levels[level.orig_id] = nil
            table.delete(tweak_data.levels._level_index, level.orig_id)
            level.orig_id = nil
            something_changed = true
        end
    end
    t.orig_id = nil
    FileIO:WriteTo(Path:Combine(map_path, "main.xml"), FileIO:ConvertToScriptData(t, CXML, true))
    mod._clean_config = t
    if t.name ~= id then
        tweak_data.narrative.jobs[id] = nil
        table.delete(tweak_data.narrative._jobs_index, id)
        FileIO:MoveTo(map_path, Path:Combine(BeardLib.config.maps_dir, t.name))
        something_changed = true
    end
    if something_changed then
        self:do_reload_mod(id, t.name)
    end
end

function Project:_select_project(mod)
    self._current_mod = mod
    BLE.ListDialog:hide()

    if self._project then
        --TODO: Do you want to save the previous project?
    end

    self:reset_menu()
    self._project = ProjectEditor:new(self._menu, mod)
end

function Project:new_project_dialog(name, clbk, no_callback)
    BLE.InputDialog:Show({
        title = "Enter a name for the project",
        yes = "Create project",
        text = name or "",
        no_callback = no_callback,
        check_value = ClassClbk(self, "check_narrative_name"),
        callback = ClassClbk(self, "new_project_dialog_clbk", type(clbk) == "function" and clbk or ClassClbk(self, "new_project_clbk"))
    })
end

function Project:new_level_dialog(name, clbk, no_callback)
    BLE.InputDialog:Show({
        title = "Enter a name for the level",
        yes = "Create",
        text = name or "",
        no_callback = no_callback,
        check_value = ClassClbk(self, "check_level_name"),
        callback = type(clbk) == "function" and clbk or ClassClbk(self, "create_new_level")
    })
end

function Project:new_instance_dialog(name, clbk, no_callback)
    BLE.InputDialog:Show({
        title = "Enter a name for the instance",
        yes = "Create",
        text = name or "",
        no_callback = no_callback,
        check_value = function(name) return self:check_level_name(name, true) end,
        callback = type(clbk) == "function" and clbk or ClassClbk(self, "create_new_instance")
    })
end

function Project:delete_level_dialog(level)
    EU:YesNoQuestion("This will delete the level from your project! [Note: custom levels that are inside your project will be deleted entirely]", ClassClbk(self, "delete_level_dialog_clbk", level))
end

function Project:delete_level_dialog_clbk(level)
    local t = self._current_data
    if not t then
        BLE:log("[ERROR] Project needed to delete levels!")
        return
    end
    local chain = XML:GetNode(self._current_data, "narrative").chain
    local level_id = type(level) == "table" and level.id or level

    for k, v in ipairs(chain) do
        if success then
            break
        end
        if v.level_id and v.level_id == level_id then
            table.remove(chain, k)
            break
        else
            local success
            for i, level in pairs(v) do
                if level.level_id == level_id then
                    table.remove(v, i)
                    success = true
                    break
                end
            end
        end
    end
    if type(level) == "table" then
        FileIO:Delete(Path:Combine(BeardLib.config.maps_dir, t.name, level.include.directory))
        if tweak_data.levels[level_id].custom then
            tweak_data.levels[level_id] = nil
		end
		table.delete_value(t, level)
    end
    local save = self:GetItem("Save")
    if save then
		save:RunCallback()
    end   
    self:do_reload_mod(t.name, t.name)
end

function Project:create_new_level(name)
    local t = self._current_data
    if not t then
        BLE:log("[ERROR] Project needed to create levels!")
        return
    end
    local narr = XML:GetNode(t, "narrative")
	local level = deep_clone(self._level_module_template)
	XML:InsertNode(t, level)
    level.id = name
    local proj_path = Path:Combine(BeardLib.config.maps_dir, t.name)
    local level_path = Path:Combine("levels", level.id)
    table.insert(narr.chain, {level_id = level.id, type = "d", type_id = "heist_type_assault"})
    level.include.directory = level_path
	FileIO:WriteScriptData(Path:Combine(proj_path, "main.xml"), t, "custom_xml")
	FileIO:MakeDir(Path:Combine(proj_path, level_path))
    FileIO:CopyToAsync(Path:Combine(self._templates_directory, "Level"), Path:Combine(proj_path, level_path))
    self:do_reload_mod(t.name, t.name, true)
end

function Project:create_new_instance(name)
    local t = self._current_data
    if not t then
        BLE:log("[ERROR] Project needed to create levels!")
        return
    end
	local level = deep_clone(self._instance_module_template)
	XML:InsertNode(t, level)
    level.id = name
    local proj_path = Path:Combine(BeardLib.config.maps_dir, t.name)
    local level_path = Path:Combine("instances", level.id)
    level.include.directory = level_path
	FileIO:WriteScriptData(Path:Combine(proj_path, "main.xml"), t, "custom_xml")
	FileIO:MakeDir(Path:Combine(proj_path, level_path))
    FileIO:CopyToAsync(Path:Combine(self._templates_directory, "Instance"), Path:Combine(proj_path, level_path))
    self:do_reload_mod(t.name, t.name, true)
end

function Project:create_new_narrative(name)
    local data = deep_clone(self._main_xml_template)
    local narr = XML:GetNode(data, "narrative")
    data.name = name
    narr.id = name
    local proj_path = Path:Combine(BeardLib.config.maps_dir, name)
    FileIO:CopyDirTo(Path:Combine(self._templates_directory, "Project"), proj_path)
    FileIO:MakeDir(Path:Combine(proj_path, "assets"))
    FileIO:MakeDir(Path:Combine(proj_path, "levels"))
    FileIO:WriteTo(Path:Combine(proj_path, "main.xml"), FileIO:ConvertToScriptData(data, CXML, true))  
    return data
end

function Project:check_level_name(name, is_instance)
    --Windows is not case sensitive.
    if is_instance then
        for k in pairs(BeardLib.managers.MapFramework._loaded_instances) do
            if string.lower(k) == name:lower() then
                EU:Notify("Error", string.format("An instance with the id %s already exists! Please use a unique id", k))
                return false
            end
        end
    else
        for k in pairs(tweak_data.levels) do
            if string.lower(k) == name:lower() then
                EU:Notify("Error", string.format("A level with the id %s already exists! Please use a unique id", k))
                return false
            end
        end
    end
    if name == "" then
        EU:Notify("Error", string.format("Id cannot be empty!", name))
        return false
    elseif string.begins(name, " ") then
        EU:Notify("Error", "Invalid ID!")
        return false
    end
    return true
end

function Project:check_narrative_name(name)
    for k in pairs(tweak_data.narrative.jobs) do
        if string.lower(k) == name:lower() then
            EU:Notify("Error", string.format("A narrative with the id %s already exists! Please use a unique id", k))
            return false
        end
    end
    if name:lower() == "backups" or name:lower() == "prefabs" or string.begins(name, " ") then
        EU:Notify("Error", string.format("Invalid Id"))
        return false
    elseif name == "" then
        EU:Notify("Error", string.format("Id cannot be empty!", name))
        return false
    end
    return true
end

function Project:new_project_dialog_clbk(clbk, name) clbk(self:create_new_narrative(name), name) end

function Project:new_project_clbk(data, name)
    local save = self:GetItem("Save")
    if save then
        save:RunCallback()
    end
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
    BLE.LoadLevel:load_levels()
    local mod = BeardLib.managers.MapFramework._loaded_mods[name]
    self:_select_project(mod, true)
    EU:QuickDialog({title = "New Project", message = "Do you want to create a new level for the project?"}, {{"Yes", ClassClbk(self, "new_level_dialog", "")}})
end

function Project:_edit_main_xml(data, save_clbk)
    self:reset_menu()
    self:set_edit_title(tostring(data.name))
    local narr = XML:GetNode(data, "narrative")
    local levels = XML:GetNodes(data, "level")
    if not narr then
        BLE:log("[ERROR] Narrative data is missing from the main.xml!")
        return
    end
    local divgroup_opt = {border_position_below_title = true, private = {size = 22}}
    local up = ClassClbk(self, "set_project_data")
    local narrative = self._curr_editing:divgroup("Narrative", divgroup_opt)
    narrative:textbox("ProjectName", up, data.name)
    local contacts = table.map_keys(tweak_data.narrative.contacts)
    narrative:combobox("Contact", up, contacts, table.get_key(contacts, narr.contact or "custom"))
    narrative:textbox("BriefingEvent", up, narr.briefing_event)
    narr.crimenet_callouts = type(narr.crimenet_callouts) == "table" and narr.crimenet_callouts or {narr.crimenet_callouts}
    narr.debrief_event = type(narr.debrief_event) == "table" and narr.debrief_event or {narr.debrief_event}

    narrative:textbox("DebriefEvent", up, table.concat(narr.debrief_event, ","))
    narrative:textbox("CrimenetCallouts", up, table.concat(narr.crimenet_callouts, ","))
    narrative:button("SetCrimenetVideos", ClassClbk(self, "set_crimenet_videos_dialog"))
    narrative:tickbox("HideFromCrimenet", up, data.hide_from_crimenet)
    local updating = self._curr_editing:divgroup("Updating", divgroup_opt)
    local mod_assets = XML:GetNode(data, "AssetUpdates")
    if not mod_assets then
        mod_assets = {_meta = "AssetUpdates", id = -1, version = 1, provider = "modworkshop", use_local_dir = true}
        data.AssetUpdates = mod_assets
    end
    if mod_assets.provider == "lastbullet" then
        mod_assets.provider = "modworkshop"
    end
    updating:textbox("DownloadId", up, mod_assets.id, {filter = "number", floats = 0})
    updating:textbox("Version", up, mod_assets.version, {filter = "number"})
    updating:tickbox("Downloadable", up, mod_assets.is_standalone ~= false, {
        help = "Can the level be downloaded by clients connecting? this can only work if the level has no extra dependencies"
    })

    local chain = self._curr_editing:divgroup("Chain", divgroup_opt)
    chain:button("AddExistingLevel", ClassClbk(self, "add_exisiting_level_dialog"))
    chain:button("AddNewLevel", ClassClbk(self, "new_level_dialog", ""))
    chain:button("CreateInstance", ClassClbk(self, "new_instance_dialog", ""))
    chain:button("CloneLevel", ClassClbk(self, "new_level_dialog", ""))
    local levels_group = chain:divgroup("Levels", {last_y_offset = 6})
    local function get_level(level_id)
        for _, v in pairs(levels) do
            if v.id == level_id then
                return v
            end
        end
    end
    local level_ids = {}
    local function build_level_ctrls(level_in_chain, chain_group, btn, level)
        local narr_chain = chain_group or narr.chain
        local my_index = table.get_key(narr_chain, level_in_chain)

        local tx = "textures/editor_icons_df"
        local toolbar = btn
        if level_in_chain.level_id then
            btn:tb_imgbtn(level_in_chain.level_id, ClassClbk(self, "delete_level_dialog", level and level or level_in_chain.level_id), tx, EU.EditorIcons["cross"], {highlight_color = Color.red})
            if chain_group then
                btn:tb_imgbtn("Ungroup", ClassClbk(self, "ungroup_level", narr, level_in_chain, chain_group), tx, EU.EditorIcons["minus"], {highlight_color = Color.red})
            else
                btn:tb_imgbtn("Group", ClassClbk(self, "group_level", narr, level_in_chain), tx, EU.EditorIcons["plus"], {highlight_color = Color.red})
            end
        else
            toolbar = btn:GetToolbar()
        end
        toolbar:tb_imgbtn("MoveDown", ClassClbk(self, "set_chain_index", narr_chain, level_in_chain, my_index + 1), tx, EU.EditorIcons["arrow_down"], {highlight_color = Color.red, enabled = my_index < #narr_chain})
        toolbar:tb_imgbtn("MoveUp", ClassClbk(self, "set_chain_index", narr_chain, level_in_chain, my_index - 1), tx, EU.EditorIcons["arrow_up"], {highlight_color = Color.red, enabled = my_index > 1})
    end
    local function build_level_button(level_in_chain, chain_group, group)
        local level_id = level_in_chain.level_id
        local level = get_level(level_id)
        local btn = (group or levels_group):button(level_id, level and ClassClbk(self, "edit_main_xml_level", data, level, level_in_chain, chain_group, save_clbk), {
            text = level_id
        })
        return btn, level
    end
    for i, v in ipairs(narr.chain) do
        if type(v) == "table" then
            if v.level_id then
                local btn, actual_level = build_level_button(v, false)
                build_level_ctrls(v, false, btn, actual_level)
            else
                local grouped = levels_group:divgroup("Day "..tostring(i).."[Grouped]")
                build_level_ctrls(v, nil, grouped)
                for k, level in pairs(v) do
                    local btn, actual_level = build_level_button(level, v, grouped, k == 1)
                    build_level_ctrls(level, v, btn, actual_level)
                end
            end
        end
    end
    if #levels_group._my_items == 0 then
        levels_group:divider("NoLevelsNotice", {text = "No levels found, sadly."})
    end
    self._contract_costs = {}
    self._experience_multipliers = {}
    self._max_mission_xps = {}
    self._min_mission_xps = {}
    self._payouts = {}  
    local function convertnumber(n)
        local t = {}
        for i=1, #self._diffs do table.insert(t, n) end
        return t
    end
    narr.contract_cost = type(narr.contract_cost) == "table" and narr.contract_cost or convertnumber(narr.contract_cost)
    narr.experience_mul = type(narr.experience_mul) == "table" and narr.experience_mul or convertnumber(narr.experience_mul)
    narr.max_mission_xp = type(narr.max_mission_xp) == "table" and narr.max_mission_xp or convertnumber(narr.max_mission_xp)
    narr.min_mission_xp = type(narr.min_mission_xp) == "table" and narr.min_mission_xp or convertnumber(narr.min_mission_xp)
    narr.payout = type(narr.payout) == "table" and narr.payout or convertnumber(narr.payout)
    local diff_settings = self._curr_editing:divgroup("DifficultySettings", divgroup_opt)
    local diff_settings_holder = diff_settings:pan("DifficultySettingsHolder", {
        text_offset_y = 0, align_method = "grid", offset = {diff_settings.offset[1], 0}})

    local diff_settings_opt = {w = diff_settings_holder:ItemsWidth() / (#self._diffs + 1) - 2, offset = {2, 6}, size = 18}
    local diff_settings_texts = diff_settings_holder:divgroup("Setting", diff_settings_opt)

    diff_settings_opt.border_left = false 

    local div_texts_opt = {size_by_text = true, offset = {0, diff_settings_texts.offset[2]}}
    diff_settings_texts:divider("Contract Cost", div_texts_opt)
    diff_settings_texts:divider("Payout", div_texts_opt)
    diff_settings_texts:divider("Stealth XP bonus", div_texts_opt)
    diff_settings_texts:divider("Maximum XP", div_texts_opt)
    diff_settings_texts:divider("Minimum XP", div_texts_opt)

    for i, diff in pairs(self._diffs) do
        local group = diff_settings_holder:divgroup(diff, diff_settings_opt)
        self._contract_costs[i] = group:numberbox("ContractCost"..i, up, narr.contract_cost[i] or 0, {max = 10000000, min = 0, size_by_text = true, text = "", control_slice = 1})
        self._payouts[i] = group:numberbox("Payout"..i, up, narr.payout[i] or 0, {max = 100000000, min = 0, size_by_text = true, text = "", control_slice = 1})
        self._experience_multipliers[i] = group:numberbox("ExperienceMul"..i, up, narr.experience_mul[i] or 0, {max = 5, min = 0, size_by_text = true, text = "", control_slice = 1})
        self._max_mission_xps[i] = group:numberbox("MaxMissionXp"..i, up, narr.max_mission_xp[i] or 0, {max = 10000000, min = 0, size_by_text = true, text = "", control_slice = 1})
        self._min_mission_xps[i] = group:numberbox("MinMissionXp"..i, up, narr.min_mission_xp[i] or 0, {max = 100000, min = 0, size_by_text = true, text = "", control_slice = 1})
    end 

    self:small_button("Save", save_clbk)
    self:small_button("Delete", ClassClbk(self, "delete_project", self._current_mod))
    self:small_button("Close", ClassClbk(self, "disable"))
    self._current_data = data
    self._refresh_func = ClassClbk(self, "edit_main_xml", data, save_clbk)
end

function Project:delete_project(mod, item)
    EU:YesNoQuestion("This will delete the project and its files completely. This cannot be undone!", function()
        EU:YesNoQuestion("Are you 100% sure?", function()
            FileIO:Delete(Path:Combine("Maps", self._current_data.name))
            local narr = tweak_data.narrative.jobs[mod.Name]
            if narr and narr.custom then
                tweak_data.narrative.jobs[mod.Name] = nil
                table.delete(tweak_data.narrative._jobs_index, mod.Name)
            end
            for _, level in pairs(XML:GetNodes(self._current_data, "level")) do
                local tweak = tweak_data.levels[level.id]
                if tweak and tweak.custom then
                    tweak_data.levels[level.id] = nil
                    table.delete(tweak_data.levels._level_index, level.id)
                end
            end
            self:reload_mod(mod.Name)
            self:disable()
        end)
    end)
end

function Project:small_button(name, clbk)
    self._curr_editing:GetToolbar():tb_btn(name, clbk, {
        min_width = 100,
        text_offset = {8, 2},
        border_bottom = true,
    })
end

function Project:reset_menu()
    if self._project then
        self._project:destroy()
    end
end

function Project:disable()
    self._current_data = nil
    self._current_mod = nil
    self._refresh_func = nil
    self:reset_menu()
end