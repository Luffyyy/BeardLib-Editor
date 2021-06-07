---Editor for BeardLib level module.
---@class ProjectLevelEditor : ProjectModuleEditor
ProjectLevelEditor = ProjectLevelEditor or class(ProjectModuleEditor)
ProjectLevelEditor.LEVELS_DIR = "levels"
ProjectEditor.EDITORS.level = ProjectLevelEditor
ProjectEditor.ACTIONS["CloneSingleLevel"] = function(parent, create_data)
    local levels = {}
    for _, id in pairs(tweak_data.levels._level_index) do
		local level = tweak_data.levels[id]
		if level and not level.custom then
            --dunno why the name_id is nil for some of them..
            table.insert(levels, {name = (level.name_id and managers.localization:text(level.name_id) or "").." / "..id, id = id})
        end
    end
    BLE.ListDialog:Show({
        list = levels,
        callback = function(selection)
            BLE.ListDialog:hide()
            ProjectLevelEditor:new(parent, nil, table.merge({clone_id = selection.id}, create_data))
        end
    })
end

--- @param menu Menu
--- @param data table
function ProjectLevelEditor:build_menu(menu, data)
    local up = ClassClbk(self, "set_data_callback")

    data.orig_id = data.orig_id or data.id
    local is_current = (BeardLib.current_level and BeardLib.current_level._config.id or nil) == data.id
    self._deletable = not is_current
    menu:textbox("LevelID", up, data.id, {forbidden_chars = {':','*','?','"','<','>','|'}, enabled = self._deletable})
    menu:textbox("BriefingDialog", up, data.briefing_dialog)
    data.intro_event = type(data.intro_event) == "table" and data.intro_event[1] or data.intro_event
    data.outro_event = type(data.outro_event) == "table" and data.outro_event or {data.outro_event}

    menu:textbox("IntroEvent", up, data.intro_event)
    menu:textbox("OutroEvent", up, table.concat(data.outro_event, ","))
    menu:numberbox("GhostBonus", up, data.data or 0, {max = 1, min = 0, step = 0.1})
    menu:numberbox("MaxBags", up, data.max_bags, {max = 999, min = 0, floats = 0})

    local aitype = table.map_keys(LevelsTweakData.LevelType)
    menu:combobox("AiGroupType", up, aitype, table.get_key(aitype, data.ai_group_type) or 1)

    local styles = table.map_keys(tweak_data.scene_poses.player_style)
    menu:combobox("PlayerStyle", up, styles, table.get_key(styles, data.player_style or "generic"), {
        help = "Set the player style for the map, make sure the packages for the suits are loaded!"
    })
    menu:tickbox("TeamAiOff", up, data.team_ai_off)
    menu:tickbox("RetainBags", up, data.repossess_bags)
    menu:tickbox("PlayerInvulnerable", up, data.player_invulnerable)
    menu:button("ManageMissionAssets", ClassClbk(self, "set_mission_assets_dialog"))

    if data.ghost_bonus == 0 then
        data.ghost_bonus = nil
    end
end

function ProjectLevelEditor:create(create_data)
    BLE.InputDialog:Show({
        title = "Enter a name for the level",
        yes = "Create",
        text = create_data.name or "",
        check_value = function(name)
            local warn
            for _, id in pairs(table.list_add(table.map_keys(tweak_data.levels), create_data.taken_names or {})) do
                if string.lower(id) == name:lower() then
                    warn = string.format("A level with the id %s already exists! Please use a unique id", id)
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
        no_callback = function()
            if create_data.final_callback then
                create_data.final_callback(false)
            end
        end,
        callback = function(name)
            if create_data.taken_names then
                table.insert(create_data.taken_names, name)
            end
            local template
            if create_data.chain_level then
                create_data.chain_level.level_id = name
            end
            if create_data.clone_id then
                create_data.name = name
                template = self:clone_level(create_data)
            else
                template = deep_clone(BLE.MapProject._level_module_template)
                template.id = name
                local proj_path = self._parent:get_dir()
                local level_path = Path:Combine(self.LEVELS_DIR, template.id)
                template.include.directory = level_path

                FileIO:MakeDir(Path:Combine(proj_path, level_path))
                FileIO:CopyToAsync(Path:Combine(BLE.MapProject._templates_directory, "Level"), Path:Combine(proj_path, level_path))
            end
            --If we need to insert this into a chain of a narrative
            if create_data.chain then
                table.insert(create_data.chain, {level_id = template.id, type = "d", type_id = "heist_type_assault"})
            end
            self:finalize_creation(template, create_data)
        end
    })
end

function ProjectLevelEditor:pre_clone_level(create_data)
    local name = create_data.name
    local level = clone(tweak_data.levels[create_data.clone_id])
    table.merge(level, {
        _meta = "level",
        assets = {},
        id = name,
        add = {directory = "assets"},
        include = {directory = Path:Combine(self.LEVELS_DIR, name)},
        packages = type(level.package) == "string" and {level.package} or level.package or {},
        script_data_mods = deep_clone(BLE.MapProject._level_module_template).script_data_mods
    })
    return level, "levels/"..level.world_name .. "/"
end

function ProjectLevelEditor:clone_level(create_data)
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)

    --Merge module stuff into the cloned level tweakdata entry
    local level, level_dir = self:pre_clone_level(create_data)
    local clone_id = create_data.clone_id
    local name = create_data.name

    --Clone preplanning
    local preplanning = tweak_data.preplanning.locations[clone_id]
    if preplanning then
        level.preplanning = deep_clone(preplanning)
    end

    local function extra_package(p)
        if not table.contains(level.packages, p) then
            table.insert(level.packages, p)
        end
    end

    --Search for the narrative package if exists, some levels may depend on it.
    local found_narr = false
    for _, narr in pairs(tweak_data.narrative.jobs) do
        if found_narr then
            break
        end
        if narr.chain then
            for _, chain_level in ipairs(narr.chain) do
                if found_narr then
                    break
                end
                if level.level_id then
                    if chain_level.level_id == clone_id then
                        extra_package(narr.package)
                        found_narr = true
                        break
                    end
                else
                    for _, inner_chain_level in pairs(chain_level) do
                        if inner_chain_level.level_id == clone_id then
                            extra_package(narr.package)
                            found_narr = true
                            break
                        end
                    end
                end
            end
        end
    end

    local dir = self._parent:get_dir()
    local custom_level_dir = Path:Combine(dir, self.LEVELS_DIR, name)

    --Create scriptdata mod for the objectives if it doesn't exist already.
    local scriptdata_dir = Path:Combine(dir, "scriptdata")
    if not FileIO:Exists(scriptdata_dir) then
        FileIO:MakeDir(scriptdata_dir)
        local file_path = Path:Combine(scriptdata_dir, "objectives.objective")
        if not FileIO:Exists(file_path) then
            FileIO:WriteTo(file_path, "<table></table>")
        end
    end
    --This local function is used to extract the files of the map by reading the scriptdata.
    --To actually have it work we ofc need to load the packages first or else the game will go into shit.
    local function extra_file(name, typ, path, data_func)
        path = path or level_dir
        typ = typ or name
        local data
        local typeid = typ:id()
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
            BLE:log("[ProjectLevelEditor:pre_clone_level:extra_file] Cannot access file %s", inpath)
        end
        if PackageManager:package_exists(inpath) then
            extra_package(inpath)
        end
        return data
    end

    --Here we go through possible files of the map to extract them.
    extra_package(level_dir.."world")
    for _, p in pairs(level.packages) do
        BLE.MapProject:load_temp_package(p.."_init")
        BLE.MapProject:load_temp_package(p)
    end

    extra_file("world", nil, nil, function(data) data.brush = nil end)
    extra_file("mission")
    extra_file("nav_manager_data", "nav_data")
    extra_file("cover_data")
    extra_file("world_sounds")
    extra_file("world_cameras")
    extra_file("world_cameras")
    extra_file("blacklist")

    --Here we extract the cube lights. There is no need to load any packages as binary files such as textures are easily extractable.
    local cube_lights_dir = Path:Combine(level_dir, "cube_lights")
    local texture = "texture"
    local file_path
    local add = {_meta = "add", directory = "assets"}
    for k, v  in pairs(Global.DBPaths[texture]) do
        if v and k:sub(1, #cube_lights_dir) == inpath then
            file_path = Path:Combine(self.LEVELS_DIR.."/mods", name, string.sub(k, #path))
            FileIO:WriteTo(Path:Combine(BeardLib.config.maps_dir, data.name, "assets", file_path) .. "." .. typ , DB:open(texture, k):read())
            table.insert(add, {_meta = "texture", path = file_path})
        end
    end

    --Write to the add.xml of the level
    FileIO:WriteScriptData(Path:Combine(custom_level_dir, "add.xml"), add, "custom_xml")

    local continents_data = extra_file("continents")
    for c in pairs(continents_data) do
        local c_path = Path:Combine(level_dir, c)
        BLE.MapProject:load_temp_package(Path:Combine(c_path, c).."_init")
        extra_file(c, "continent", c_path)
        extra_file(c, "mission", c_path)
    end

    --Removing stuff that the module doesn't require/use.
    level.world_name = nil
    level.name_id = nil
    level.briefing_id = nil
    level.package = nil

    PackageManager:set_resource_loaded_clbk(Idstring("unit"), ClassClbk(managers.sequence, "clbk_pkg_manager_unit_loaded"))
    BLE.MapProject:unload_temp_packages()
    return level
end

--- Opens a dialog for editing the mission assets of a level
function ProjectLevelEditor:set_mission_assets_dialog()
    local data = self._data
	local selected_assets = {}
	data.assets = data.assets or {_meta = "assets"}
    for _, asset in pairs(data.assets) do
        if type(asset) == "table" and asset._meta == "asset" then
            table.insert(selected_assets, {name = asset.name, value = asset.exclude == true})
        end
    end
    local assets = {}
	for _, asset in pairs(table.map_keys(tweak_data.assets)) do
		if asset.stages ~= "all" then
			table.insert(assets, {name = asset, value = false})
		end
    end
	BLE.SelectDialogValue:Show({
		selected_list = selected_assets,
		list = assets,
		values_name = "Exclude",
        values_list_width = 100,
		callback = function(list)
            local new_assets = {}
            for _, asset in pairs(list) do
                table.insert(new_assets, {_meta = "asset", name = asset.name, exclude = asset.value == true and true or nil})
            end
            data.assets = new_assets
        end
	})
end

--- The callback function for all items for this menu.
function ProjectLevelEditor:set_data_callback()
    local data = self._data

    local name_item = self:GetItem("LevelID")
    local new_name = name_item:Value()
    local title = "Level ID"
    if data.id ~= new_name then
        local exists = false
        for _, mod in pairs(self._parent:get_modules("level")) do
            if mod.id == new_name then
                exists = true
            end
        end
        if exists or new_name == "" or (data.orig_id ~= new_name and tweak_data.levels[new_name]) then
            title = title .. "[Invalid]"
        else
            for _, mod in pairs(self._parent:get_modules("narrative")) do
                if mod.chain then
                    for _, level in ipairs(mod.chain) do
                        if level.level_id == data.id then
                            level.level_id = new_name
                            break
                        else
                            for i, inner_level in pairs(level) do
                                if inner_level.level_id == data.id then
                                    inner_level.level_id = new_name
                                end
                            end
                        end
                    end
                end
            end
            data.id = new_name
        end
    end
    name_item:SetText(title)

    data.ai_group_type = self:GetItem("AiGroupType"):SelectedItem()
    data.player_style = self:GetItem("PlayerStyle"):SelectedItem()
    data.briefing_dialog = self:GetItem("BriefingDialog"):Value()
    data.ghost_bonus = self:GetItem("GhostBonus"):Value()
    if data.ghost_bonus == 0 then
        data.ghost_bonus = nil
    end
    data.max_bags = self:GetItem("MaxBags"):Value()
    data.team_ai_off = self:GetItem("TeamAiOff"):Value()
    data.intro_event = self:GetItem("IntroEvent"):Value()
    data.repossess_bags = self:GetItem("RetainBags"):Value()
    data.player_invulnerable = self:GetItem("PlayerInvulnerable"):Value()
    local outro = self:GetItem("OutroEvent"):Value()
    data.outro_event = outro:match(",") and string.split(outro, ",") or {outro}
end

function ProjectLevelEditor:save_data()
    local level = self._data
    local level_id = level.id
    local orig_id = level.orig_id or level_id
    local dir = self._parent:get_dir()

    if orig_id ~= level_id then -- Level ID has been changed, let's delete the old ID to let the new ID replace it and move the folder.
        local include_dir = Path:Combine("levels", level_id)
        level.include.directory = include_dir
        if level.add.file then
            level.add.file = Path:Combine(include_dir, "add.xml")
        end
        FileIO:MoveTo(Path:Combine(dir, "levels", orig_id), Path:Combine(dir, include_dir))
        tweak_data.levels[orig_id] = nil
        table.delete(tweak_data.levels._level_index, orig_id)
    end
    level.orig_id = nil
    return ProjectLevelEditor.super.save_data(self)
end

function ProjectLevelEditor:delete()
    local id = self._data.id
    for _, mod in pairs(self._parent:get_modules("narrative")) do
        if mod.chain then
            for _, level in ipairs(mod.chain) do
                if level.level_id == id then
                    table.delete_value(mod.chain, level)
                    break
                else
                    for i, inner_level in pairs(level) do
                        if inner_level.level_id == id then
                            table.delete_value(level, inner_level)
                        end
                    end
                end
            end
        end
    end
    local path = Path:Combine(self._parent:get_dir(), self.LEVELS_DIR, self._data.orig_id or id)
    if FileIO:Exists(path) then
        FileIO:Delete(path)
    end
end