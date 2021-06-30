MainLayerEditor = MainLayerEditor or class(LayerEditor)
function MainLayerEditor:init(parent)
	MainLayerEditor.super.init(self, parent, "MainLayerEditor", {visible = true})
    if BeardLib.current_level then
        self._continent_settings = ContinentSettingsDialog:new(BLE._dialogs_opt)
        self._objectives_manager = ObjectivesManagerDialog:new(BLE._dialogs_opt)
    end
end

function MainLayerEditor:build_menu()
    self._holder:ClearItems()

    if not BeardLib.current_level then
        local s = "Preview mode"
        s = s .. "\nSaving the map will not clone the map, it'll just save it."
        s = s .. "\nIf you wish to clone it please use the 'Clone Existing Heist' feature in projects menu."
        self._holder:alert(s)
    end
    if Global.editor_safe_mode then
        local warn = self._holder:alert("Safe mode\nMost features are disabled")
        warn:tb_btn("Load normal mode", function()
            BLE.Utils:YesNoQuestion("Are you sure you want to load into normal mode?", function()
                managers.game_play_central:restart_the_game()
                Global.editor_safe_mode = nil
            end)
        end)
    end
    if not managers.editor._has_fix then
        self._holder:alert("Physics settings fix is not enabled!\nPlease enable it through the BLE settings menu\nSome features will not work.")
    end

    local load = self._holder:divgroup("LoadWithPackages", {enabled = BeardLib.current_level ~= nil, align_method = "grid"})
    local load_extract = self._holder:divgroup("LoadFromDatabase", {align_method = "grid"})

    local assets = self:GetPart("assets")
    for _, ext in pairs(BLE.UsableAssets) do
        local text = ext:capitalize()
        load:s_btn(ext, ClassClbk(self, "open_load_dialog", {ext = ext}), {text = text})
        load_extract:s_btn(ext, ClassClbk(self, "open_load_dialog", {on_click = ClassClbk(assets, "quick_load_from_db", ext), ext = ext}), {text = text})
    end

    local mng = self._holder:divgroup("Managers", {align_method = "grid", enabled = BeardLib.current_level ~= nil})
    mng:s_btn("Assets", ClassClbk(self:GetPart("assets"), "Show") or nil)
    mng:s_btn("Objectives", self._objectives_manager and ClassClbk(self._objectives_manager, "Show") or nil)

    self:build_continents()
end

--Continents
function MainLayerEditor:build_continents()
    local tx = "textures/editor_icons_df"
    local all_continents = managers.editor._continents
    if all_continents then
        local continents = self._holder:group("Continents")
        local toolbar = continents:GetToolbar()
        local all_scripts = table.map_keys(managers.mission._scripts)
        self._current_continent = continents:combobox("CurrentContinent", ClassClbk(self, "set_current_continent"), all_continents, table.get_key(all_continents, managers.editor._current_continent) or 1)
        self._current_script = continents:combobox("CurrentScript", ClassClbk(self, "set_current_script"), all_scripts, table.get_key(all_scripts, managers.editor._current_script) or 1)    
        local icons = BLE.Utils.EditorIcons

        toolbar:tb_imgbtn("NewContinent", ClassClbk(self, "new_continent"), tx, icons.plus, {help = "Add continent"})
        for name, data in pairs(managers.worlddefinition._continent_definitions) do
            local continent = continents:group(name, {text = name, divider_type = table.size(managers.mission._missions[name]) == 0})
            local ctoolbar = continent:GetToolbar()
            ctoolbar:tb_imgbtn("Remove", ClassClbk(self, "remove_continent", name), nil, icons.cross, {highlight_color = Color.red, help = "Remove Continent"})
            ctoolbar:tb_imgbtn("ClearUnits", ClassClbk(self, "clear_all_units_from_continent", name), nil, icons.trash, {highlight_color = Color.red, help = "Delete all Units"})
            ctoolbar:tb_imgbtn("Settings", ClassClbk(self, "open_continent_settings", name), nil, icons.settings_gear, {help = "Continent Settings"})
            ctoolbar:tb_imgbtn("SelectUnits", ClassClbk(self, "select_all_units_from_continent", name), nil, icons.select, {help = "Select All"})
            ctoolbar:tb_imgbtn("AddScript", ClassClbk(self, "add_new_mission_script", name), nil, icons.plus, {help = "Add mission script"})
            ctoolbar:tb_imgbtn("SetVisible", function(item) 
                local alpha = self:toggle_unit_visibility(name) and 1 or 0.5
                item.enabled_alpha = alpha
                item:SetEnabled(item.enabled)
            end, tx, icons.eye, {help = "Toggle Visibility"})

            for sname, data in pairs(managers.mission._missions[name]) do
                local script = continent:divider(sname, {continent = name, align_method = "grid_from_right", border_color = Color.green, text = sname, offset = {8, 4}})
                script:tb_imgbtn("RemoveScript", ClassClbk(self, "remove_script", sname), nil, icons.cross, {highlight_color = Color.red, help = "Remove Script"})
                script:tb_imgbtn("ClearElements", ClassClbk(self, "clear_all_elements_from_script", sname), nil, icons.trash, {highlight_color = Color.red, help = "Delete all Elements"})
                script:tb_imgbtn("Rename", ClassClbk(self, "rename_script", sname), nil, icons.pen, {help = "Rename Script"})
                script:tb_imgbtn("SelectElements", ClassClbk(self, "select_all_units_from_script", sname), nil, icons.select, {help = "Select All"})
            end
        end
    end
end

function MainLayerEditor:set_current_script(item)
    managers.editor._current_script = item:SelectedItem()
    self:GetPart("mission"):set_elements_vis()
end

function MainLayerEditor:set_current_continent(item) 
    managers.editor._current_continent = item:SelectedItem()
end

function MainLayerEditor:open_continent_settings(continent)
    self._continent_settings:Show({continent = continent, callback = ClassClbk(self, "build_default_menu")})
end

function MainLayerEditor:remove_continent(continent)
    BLE.Utils:YesNoQuestion("This will remove the continent!", function()
        self:clear_all_units_from_continent(continent, true, true)
        managers.mission._missions[continent] = nil
        managers.worlddefinition._continents[continent] = nil
        managers.worlddefinition._continent_definitions[continent] = nil
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
        self:build_menu()
    end)
end

function MainLayerEditor:toggle_unit_visibility(units)
    local visible
    for _, unit in pairs(self:get_all_units_from_continent(units)) do
        if alive(unit) then unit:set_visible(not unit:visible()) visible = unit:visible() end
    end
    return visible
end

function MainLayerEditor:get_all_units_from_continent(continent)
    local units = {}
    for _, static in pairs(managers.worlddefinition._continent_definitions[continent].statics) do
        if static.unit_data and static.unit_data.unit_id then
            local unit = managers.worlddefinition:get_unit_on_load(static.unit_data.unit_id)
            if alive(unit) then
                table.insert(units, unit)
            end
        end
    end
    return units
end

function MainLayerEditor:clear_all_units_from_continent(continent, no_refresh, no_dialog)
    local function delete_all()
        local worlddef = managers.worlddefinition
        for _, static in pairs(self:get_all_units_from_continent(continent)) do
            worlddef:delete_unit(static)
            World:delete_unit(static)
        end
        worlddef._continent_definitions[continent].editor_groups = {}
        worlddef._continent_definitions[continent].statics = {}
        if no_refresh ~= true then
            managers.editor:load_continents(managers.worlddefinition._continent_definitions)
            self:build_menu()
        end
        worlddef:check_names()
    end
    if no_dialog == true then
        delete_all()
    else
        BLE.Utils:YesNoQuestion("This will delete all units in the continent!", delete_all)
    end
end

function MainLayerEditor:new_continent()
    local worlddef = managers.worlddefinition
    BLE.InputDialog:Show({title = "Continent name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Continent name cannot be empty!", callback = function()
                self:new_continent()
            end})
            return
        elseif name == "environments" or string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:new_continent()
            end})
            return
        elseif worlddef._continent_definitions[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Continent name already taken!", callback = function()
                self:new_continent()
            end})
            return
        end
        managers.mission._missions[name] = managers.mission._missions[name] or {}
        worlddef._continent_definitions[name] = managers.worlddefinition._continent_definitions[name] or {
            editor_groups = {},
            statics = {},
            values = {workviews = {}}
        }
        worlddef._continents[name] = {base_id = worlddef._start_id  * table.size(worlddef._continent_definitions), name = name}
        managers.editor:load_continents(worlddef._continent_definitions)
        self:build_menu()
    end})
end

function MainLayerEditor:add_new_mission_script(cname)
    local mission = managers.mission
    BLE.InputDialog:Show({title = "Mission script name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        elseif string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        elseif mission._scripts[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name already taken!", callback = function()
                self:add_new_mission_script(cname)
            end})
            return
        end

        if cname == "world" and name ~= "default" and not mission._missions[cname].default then
            BLE.Dialog:Show({
                title = "WARNING!", 
                message = "First mission script name for the world continent must always be named 'default'"
            })

            name = "default"
        end

        mission._missions[cname][name] = mission._missions[cname][name] or {
            activate_on_parsed = true,
            elements = {},
            instances = {}   
        }
        local data = clone(mission._missions[cname][name])
        data.name = name
        data.continent = cname
        if not mission._scripts[name] then
            mission:_add_script(data)
        end
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
    end})
end

function MainLayerEditor:remove_script(script, item)
    BLE.Utils:YesNoQuestion("This will delete the mission script including all elements inside it!", function()
        local mission = managers.mission
        self:_clear_all_elements_from_script(script, item.parent.continent, true, true)
        mission._missions[item.parent.continent][script] = nil
        mission._scripts[script] = nil
        self:build_menu()
    end)
end

function MainLayerEditor:rename_script(script, item)
    local mission = managers.mission
    BLE.InputDialog:Show({title = "Rename Mission script to", text = script, callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name cannot be empty!", callback = function()
                self:rename_script(script, item)
            end})
            return
        elseif string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_script(script, item)
            end})
            return
        elseif mission._scripts[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Mission script name already taken", callback = function()
                self:rename_script(script, item)
            end})
            return
        end
        mission._scripts[script]._name = name
        mission._scripts[name] = mission._scripts[script]
        mission._scripts[script] = nil
        mission._missions[item.parent.continent][name] = deep_clone(mission._missions[item.parent.continent][script])
        mission._missions[item.parent.continent][script] = nil
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
    end})
end

function MainLayerEditor:clear_all_elements_from_script(script, item)
    self:_clear_all_elements_from_script(script, item.parent.continent)
end

function MainLayerEditor:_clear_all_elements_from_script(script, continent, no_refresh, no_dialog)
    local function delete_all()
        local mission = managers.mission
        for _, element in pairs(mission._missions[continent][script].elements) do
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:mission_element() and unit:mission_element().element.id == element.id then
                    mission._scripts[script]:delete_element(element)
                    element = nil
                    World:delete_unit(unit)
                    break
                end
            end
        end
        mission._missions[continent][script].elements = {}
        if no_refresh ~= true then
            managers.editor:load_continents(managers.worlddefinition._continent_definitions)
        end
    end
    if no_dialog == true then
        delete_all()
    else
        BLE.Utils:YesNoQuestion("This will delete all elements in the mission script!", delete_all)
    end
end

function MainLayerEditor:select_all_units_from_continent(continent)
    local static = self:GetPart("static")
    local selected_units = {}
    local _selected_units = static._selected_units
    local pressed_ctrl = ctrl()

    for _, unit in pairs(self:get_all_units_from_continent(continent)) do
        table.insert(pressed_ctrl and _selected_units or selected_units, unit)
    end
    self:GetPart("mission"):remove_script()
    if not ctrl() then
        static._selected_units = selected_units
    end
    static:set_selected_unit()
end

function MainLayerEditor:select_all_units_from_script(script, item)
    local static = self:GetPart("static")
    local selected_units = {}
    local _selected_units = static._selected_units
    local pressed_ctrl = ctrl()
    for _, unit in pairs(self:GetPart("mission")._units) do
        if unit:mission_element() then
            local element = unit:mission_element().element
            if element.script == script then
                table.insert(pressed_ctrl and _selected_units or selected_units, unit)
            end
        end
    end
    self:GetPart("mission"):remove_script()
    if not pressed_ctrl then
        static._selected_units = selected_units
    end
    static:set_selected_unit()
end

function MainLayerEditor:CloseDialog()
    BLE.ListDialog:hide()
    BLE.MSLD:hide()
    self._opened = {}
end

function MainLayerEditor:CanOpenDialog(name)
    if self._opened[name] then
        self:CloseDialog()
        return false
    end
    self:CloseDialog()
    self._opened[name] = true
    return true
end

-- function MainLayerEditor:open_spawn_unit_dialog(params)
--     if not self:CanOpenDialog("SpawnUnit") then
--         return
--     end

-- 	params = params or {}
--     local pkgs = self._assets_manager and self._assets_manager:get_level_packages()
-- 	BLE.MSLD:Show({
-- 	    list = BLE.Utils:GetUnits({
-- 			not_loaded = params.not_loaded,
-- 			packages = pkgs,
-- 			slot = params.slot,
-- 			type = params.type,
-- 			not_types = {Idstring("being"), Idstring("brush"), Idstring("wpn"), Idstring("item")},
-- 			not_in_slot = "brushes"
-- 		}),
--         force = true,
--         no_callback = ClassClbk(self, "CloseDialog"),
--         callback = function(unit)
--             self:CloseDialog()
-- 	    	if type(params.on_click) == "function" then
-- 	    		params.on_click(unit)
-- 	    	else
--                 if not self._assets_manager or self._assets_manager:is_asset_loaded("unit", unit) or not params.not_loaded then
--                     if PackageManager:has(Idstring("unit"), unit:id()) then
--                         self:BeginSpawning(unit)
--                     else
--                         BLE.Utils:Notify("Error", "Cannot spawn the unit")
--                     end
--                 else
--                     BLE.Utils:QuickDialog({title = "Well that's annoying..", no = "No", message = "This unit is not loaded and if you want to spawn it you have to load a package for it, search packages for the unit?"}, {{"Yes", function()
--                         self._assets_manager:find_package(unit, "unit", true)
--                     end}})
--                 end
-- 			end
-- 	    end
-- 	})
-- end

function MainLayerEditor:open_load_dialog(params)
    local units = {}
	local ext = params.ext
    for unit in pairs(BLE.DBPaths[ext]) do
        if not unit:match("wpn_") and not unit:match("msk_") then
            table.insert(units, unit)
        end
    end
	BLE.ListDialog:Show({
	    list = units,
		force = true,
		not_loaded = true,
        callback = function(asset)
            if not ctrl() then
                self:CloseDialog()
            end
            if params.on_click then
                params.on_click(asset)
            else
                local assets = self:GetPart("assets")
                assets:find_package(asset, ext, true)
            end
	    end
	})
end

function MainLayerEditor:destroy()
    if self._continent_settings then
        self._continent_settings:Destroy()
        self._objectives_manager:Destroy()
    end
end