local XML = BeardLib.Utils.XML
local CXML = "custom_xml"
--- This class at the moment is used for maps only. However, hopefully in the future will expand to other places.

MapProjectManager = MapProjectManager or class()

function MapProjectManager:init()
    self._templates_directory = Path:Combine(BLE.ModPath, "Templates")
    self._add_xml_template = BLE.Utils:ReadConfig(Path:Combine(self._templates_directory, "Level/add.xml"))
    self._main_xml_template = BLE.Utils:ReadConfig(Path:Combine(self._templates_directory, "Project/main.xml"))
    self._level_module_template = BLE.Utils:ReadConfig(Path:Combine(self._templates_directory, "LevelModule.xml"))
    self._narr_module_template = BLE.Utils:ReadConfig(Path:Combine(self._templates_directory, "NarrativeModule.xml"))
    self._instance_module_template = BLE.Utils:ReadConfig(Path:Combine(self._templates_directory, "InstanceModule.xml"))

    self._packages_to_unload = {}

    self._menu = BLE.Menu:make_page("Projects", nil, {align_method = "centered_grid"})

    ItemExt:add_funcs(self)

    local opt = {w = 150, text_align = "center", border_bottom = true}
    self._editing = self:divgroup("CurrEditing", {
        text = "Select a Project To Edit",
        h = self._menu:ItemsHeight() - self._menu:OffsetY() * 2,
        auto_height = false,
        border_left = false,
        private = {size = 24}
    })

    local tb = self._editing:GetToolbar()
    local more = tb:popup("...", opt)
    more:button("CloneMapAsProject", ClassClbk(self, "create_new_cloned_map"), opt)
    tb:button("EditExistingProject", ClassClbk(self, "select_project_dialog"), opt)
    tb:button("NewProject", ClassClbk(self, "create_new_map_dialog", false), opt)

    self:set_edit_title()
end

--- Load function for the class. Used for code refreshing.
--- @param data table
function MapProjectManager:Load(data)
    if data and data.selected_mod then
        self:select_project(data.selected_mod)
    end
end

--- Destroy function for the class. Used for code refreshing.
function MapProjectManager:Destroy()
    return {selected_mod = self._current_mod}
end

--- Let's you run a function on each level & instance in the project.
--- @param data table
--- @param func function
function MapProjectManager:for_each_level(data, func)
    for _, level in pairs(XML:GetNodes(data, "level")) do
        func(level)
    end
    for _, level in pairs(XML:GetNodes(data, "instance")) do
        func(level)
    end
end

--- Returns the current loaded level's data.
--- @param data table
--- @return table
function MapProjectManager:current_level(data)
    for _, level in pairs(XML:GetNodes(data, Global.editor_loaded_instance and "instance" or "level")) do
        if level.id == Global.current_level_id then
            return level
        end
    end
    return nil
end

--- Goes through data and searches for a level using the level ID.
--- @param data table
--- @param id string
--- @return table
function MapProjectManager:get_level_by_id(data, id)
    for _, level in pairs(XML:GetNodes(data, "level")) do
        if level.id == id then
            return level
        end
    end
    for _, level in pairs(XML:GetNodes(data, "instance")) do
        if level.id == id then
            return level
        end
    end
end

--- Returns current loaded level's mod.
--- @return ModCore
function MapProjectManager:current_mod()
    return BeardLib.current_level and BeardLib.current_level._mod
end

--- Returns the directory of the current level module's include.
--- @return string
function MapProjectManager:maps_path()
    return BeardLib.current_level._config.include.directory
end

--- Saves the main.xml of the current loaded level.
--- @param data table
--- @param no_reload boolean
function MapProjectManager:save_main_xml(data, no_reload)
    self:save_xml("main.xml", data)
    if not no_reload then
        self:reload_mod(data.name)
    end
end

--- Saves an XML file stored in the project.
--- @param file string
--- @param data table
function MapProjectManager:save_xml(file, data)
    local mod = self:current_mod()
    FileIO:WriteScriptData(mod:GetRealFilePath(Path:Combine(mod.ModPath, file)), data, CXML)
end

--- Reads and returns table data of an XML file stored in the project.
--- @param file string
--- @return table
function MapProjectManager:read_xml(file)
    local mod = self:current_mod()
    return FileIO:ReadScriptData(mod:current_mod():GetRealFilePath(Path:Combine(mod.ModPath, file)), CXML, true)
end

--- Returns the full path of the current project.
--- @return string
function MapProjectManager:current_path()
    local mod = self:current_mod()
    return mod and mod.ModPath
end

--- Returns the full path of the current level.
--- @return string
function MapProjectManager:current_level_path()
    local path = self:current_path()
    return path and Path:Combine(path, self:maps_path())
end

--- Returns a list of all MapFramework projects.
--- @return table
function MapProjectManager:get_projects_list()
    local list = {}
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        table.insert(list, {name = mod._clean_config.name, mod = mod})
    end
    return list
end

--- Returns the current mod and main.xml config of it.
--- @return ModCore
--- @return table
function MapProjectManager:get_mod_and_config()
    local mod = self:current_mod()
    if mod then
        return mod, self:get_clean_config(mod)
    end
    return nil, nil
end

local ignore_modules = {["GlobalValue"] = true}

--- Returns a clean config of a mod. The cleaning makes sure the config has no custom xml issues.
--- @param mod ModCore
--- @param do_clone boolean
--- @return table
function MapProjectManager:get_clean_config(mod, do_clone)
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

--- Loads a package temporarily.
--- @param p string
function MapProjectManager:load_temp_package(p)
    if not PackageManager:loaded(p) and PackageManager:package_exists(p) then
        PackageManager:load(p)
        table.insert(self._packages_to_unload, p)
    end
end

--- Unloads all packages that were lodaed and inserted into self._packages_to_unload.
function MapProjectManager:unload_temp_packages()
    for _, p in pairs(self._packages_to_unload) do
        if PackageManager:loaded(p) then
            DelayedCalls:Add("UnloadPKG"..tostring(p), 0.01, function()
                BLE:log("Unloading temp package " .. tostring(p))
                PackageManager:unload(p)
            end)
        end
    end
    self._packages_to_unload = {}
end

--- Opens a dialog to select a project to edit.
function MapProjectManager:select_project_dialog()
    BLE.ListDialog:Show({
        list = self:get_projects_list(),
        callback = function(selection)
            self:select_project(selection.mod)
        end
    })
end

--- Sets the current editing title.
--- @param title string
function MapProjectManager:set_edit_title(title)
    if title then
        self._editing:SetText("Currently Editing: ".. (title or "None"))
    else
        self._editing:SetText("Select a Project To Edit")
    end
end

--- Reloads a mod by unloading it and letting BeardLib load it again.
--- @param mod_name string
function MapProjectManager:reload_mod(mod_name)
    local mod = BeardLib.managers.MapFramework._loaded_mods[mod_name]
    if mod._modules then
        for _, module in pairs(mod._modules) do
            module.Registered = false
        end
    end
    BeardLib.managers.MapFramework._loaded_mods[mod_name] = nil
    BeardLib.managers.MapFramework._loaded_instances = nil
    self:load_mods()
end

--- Loads BeardLib mods again (MapFramework).
function MapProjectManager:load_mods()
    BeardLib.managers.MapFramework:Load()
    BeardLib.managers.MapFramework:RegisterHooks()
    BLE.LoadLevel:load_levels()
end

--- Selects a project to edit in the ProjectEditor
--- @param mod ModCore
function MapProjectManager:select_project(mod)
    self._current_mod = mod
    BLE.ListDialog:hide()

    self:close_current_project()
    self._project = ProjectEditor:new(self._editing, mod)
end

function MapProjectManager:create_new_map_dialog(clbk)
    BLE.InputDialog:Show({
        title = "Enter a name for the project",
        yes = "Create",
        text = name or "",
        check_value = function(name)
            local warn
            for k in pairs(BeardLib.managers.MapFramework._loaded_mods) do
                if string.lower(k) == name:lower() then
                    warn = string.format("A project with the id %s already exists! Please use a unique id", k)
                end
            end
            if name == "" then
                warn = string.format("Id cannot be empty!", name)
            elseif string.begins(name, " ") then
                warn = "Invalid ID!"
            end
            if warn then
                BLE.Utils:Notify("Error", warn)
            end
            return warn == nil
        end,
        callback = clbk or ClassClbk(self, "create_new_map")
    })
end

--- Creates a new clean map project (without asking the user to make a level and narrative)
--- @param name string
function MapProjectManager:create_new_map_clean(name)
    local data = deep_clone(self._main_xml_template)
    data.name = name
    local path = Path:Combine(BeardLib.config.maps_dir, name)
    FileIO:CopyDirTo(Path:Combine(self._templates_directory, "Project"), path)
    FileIO:MakeDir(Path:Combine(path, "assets"))
    FileIO:MakeDir(Path:Combine(path, "levels"))
    FileIO:WriteTo(Path:Combine(path, "main.xml"), FileIO:ConvertToScriptData(data, CXML, true))
    self:load_mods()
    self:select_project(BeardLib.managers.MapFramework._loaded_mods[name])
end

--- Creates a new map project
--- @param name string
function MapProjectManager:create_new_map(name)
    self:create_new_map_clean(name)
    ProjectNarrativeEditor:new(self._project, nil, {name = name, no_reload = true, final_callback = function(success, data)
        if success then
            ProjectLevelEditor:new(self._project, nil, {name = name, chain = data.chain, final_callback = function(success)
                if not success then
                    self._project:reload_mod()
                end
            end})
        end
    end})
end

--- Creates a new map project by cloning
--- @param name string
function MapProjectManager:create_new_cloned_map()
    local levels = {}
    for id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.custom and not narr.hidden then
            --dunno why the name_id is nil for some of them..
            table.insert(levels, {name = id.." / " .. managers.localization:text((narr.name_id or ("heist_"..id)):gsub("_prof", ""):gsub("_night", "")), id = id})
        end
    end
    BLE.ListDialog:Show({
        list = levels,
        callback = function(selection)
            BLE.ListDialog:hide()
            self:create_new_map_dialog(function(name)
                self:create_new_map_clean(name)
                ProjectNarrativeEditor:new(self._project, nil, table.merge({clone_id = selection.id, name = name}))
            end)
        end
    })
end

--- Closes currently opened project
function MapProjectManager:close_current_project()
    if self._project then
        self._project:destroy()
    end
    self:set_edit_title()
    self._current_data = nil
    self._current_mod = nil
end

function MapProjectManager:delete_project(mod, item)
    BLE.Utils:YesNoQuestion("This will delete the project and its files completely. This cannot be undone!", function()
        BLE.Utils:YesNoQuestion("Are you 100% sure?", function()
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