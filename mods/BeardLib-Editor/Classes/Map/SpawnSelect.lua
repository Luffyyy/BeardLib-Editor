SpawnSelect = SpawnSelect or class(EditorPart)
function SpawnSelect:init(parent, menu)
    self.super.init(self, parent, menu, "Utilities")    
end

function SpawnSelect:build_default_menu()
    self.super.build_default_menu(self)
    if not BeardLib.current_level then
        local s = "You're running the level on preview mode!"
        s = s .. "\nOnce you save the level it will only save the content of the level, this will not create the level."
        s = s .. "\nIf you wish to create the level please use the 'Clone Existing Heist' feature in projects menu."
        self:Divider(s, {color = Color.yellow, border_lock_height = false})
    end
    if Global.editor_safe_mode then
        local s = "You're running the level on safe mode!"
        s = s .. "\nYou can only access the assets manager, quick fixes, environment editor and the options."
        self:Divider(s, {color = Color.yellow, border_lock_height = false})
    end
    local spawn = self:DivGroup("Spawn", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    self:Button("Unit", callback(self, self, "OpenSpawnUnitDialog"), {group = spawn, size_by_text = true})
    self:Button("Element", callback(self, self, "OpenSpawnElementDialog"), {group = spawn, size_by_text = true})
    self:Button("Instance", callback(self, self, "OpenSpawnInstanceDialog"), {group = spawn, size_by_text = true})
    self:Button("Prefab", callback(self, self, "OpenSpawnPrefabDialog"), {group = spawn, size_by_text = true})

    local select = self:DivGroup("Select", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    self:Button("Unit", callback(self, self, "OpenSelectUnitDialog", {}), {group = select, size_by_text = true})
    self:Button("Element", callback(self, self, "OpenSelectElementDialog"), {group = select, size_by_text = true})
    self:Button("Instance", callback(self, self, "OpenSelectInstanceDialog", {}), {group = select, size_by_text = true})

    local load = self:DivGroup("Load", {enabled = not Global.editor_safe_mode, align_method = "grid"})
    if BeardLib.current_level then
        self:Button("Units", callback(self, self, "OpenLoadUnitDialog"), {group = load, size_by_text = true})
        if FileIO:Exists(BeardLibEditor.ExtractDirectory) then
            self:Button("UnitsExtract", callback(self, self, "OpenSpawnUnitDialog", {on_click = callback(self, self, "SpawnUnitFromExtract"), not_loaded = true}), {
                group = load, size_by_text = true, text = "Unit(From Extract)", help = [[Load a unit from extract, 
the editor will read the unit file and determine what assets it needs(except the ones that are loaded already)
afterwards it will copy them from your extract directory to the map's assets and add them to AddFiles module
this load method should be used only if you know what you're doing(ex: unit is missing from the packages)]]
            })
        end
    end
    local fixes = self:DivGroup("Fixes", {help = "Quick fixes for common issues"})
    self:Button("Remove brush(massunits) layer", callback(self, self, "remove_brush_layer"), {
        group = fixes,
        help = "Brushes/Mass units are small decals in the map such as garbage on floor and such, sadly the editor has no way of editing it, the best you can do is remove it."
    })
    self:Button("Fix mission elements' indexes", callback(self, self, "fix_elements_indexes"), {
        group = fixes,
        help = "This issue can happen after manually editing the mission scripts and will cause your mission to not work this simply reorders the elements so it works"
    })
    if BeardLib.current_level then
        local managers = self:DivGroup("Managers")
        self._assets_manager = AssetsManagerDialog:new(BeardLibEditor._dialogs_opt)
        self._objectives_manager = ObjectivesManagerDialog:new(BeardLibEditor._dialogs_opt)
        self:Button("Manage Assets", callback(self._assets_manager, self._assets_manager, "Show"), {group = managers})
        self:Button("Manage Objectives", callback(self._objectives_manager, self._objectives_manager, "Show"), {group = managers})
    end
end

function SpawnSelect:remove_dummy_unit()
    local unit = self._dummy_spawn_unit
    if alive(unit) then
        unit:set_enabled(false)
        unit:set_slot(0)
        World:delete_unit(unit)
    end
end

function SpawnSelect:fix_elements_indexes()
    for _, mission in pairs(managers.mission._missions) do
        for _, script in pairs(mission) do
            if type(script) == "table" and script.elements then
                local temp = deep_clone(script.elements)
                script.elements = {}
                for _, element in pairs(temp) do
                    table.insert(script.elements, element)
                end
            end
        end
    end
    self:Manager("opt"):save()
end

function SpawnSelect:remove_brush_layer()
    BeardLibEditor.Utils:YesNoQuestion("This will remove the brush layer from your level, this cannot be undone from the editor.", function()
        self:Manager("wdata"):data().brush = nil
        MassUnitManager:delete_all_units()
        self:Manager("wdata"):save()
        self:Manager("opt"):save()
    end)
end

function SpawnSelect:mouse_pressed(button, x, y)
    if not self._currently_spawning then
        return false
    end
    if button == Idstring("0") then
        self._do_switch = true
        self._parent:SpawnUnit(self._currently_spawning)
    elseif button == Idstring("1") then
        self:remove_dummy_unit()
        self._currently_spawning = nil
        self:SetTitle()
        self:Manager("menu"):set_tabs_enabled(true)
        if self._do_switch then
            self:Manager("static"):Switch()
            self._do_switch = false
        end
    end
    return true
end

function SpawnSelect:update(t, dt)
    self.super.update(self, t, dt)
    if alive(self._dummy_spawn_unit) then
        self._dummy_spawn_unit:set_position(self._parent._spawn_position)
        Application:draw_line(self._parent._spawn_position - Vector3(0, 0, 2000), self._parent._spawn_position + Vector3(0, 0, 2000), 0, 1, 0)
        Application:draw_sphere(self._parent._spawn_position, 30, 0, 1, 0)
    end
end

function SpawnSelect:SpawnUnitFromExtractNoSpawn(unit, dontask)
    self:SpawnUnitFromExtract(unit, dontask, true)
end

function SpawnSelect:SpawnUnitFromExtract(unit, dontask, dontspawn)
    local config = BeardLibEditor.Utils:ReadUnitAndLoad(unit)
    if not config then
        BeardLibEditor:log("[ERROR] Something went wrong when trying to load the unit!")
        return
    end
    if not dontspawn then
        self._parent:SpawnUnit(unit)
    end
    local proj = BeardLibEditor.managers.MapProject
    local map_mod = proj:current_mod()
    local map_path = proj:current_path()
    local mainxml_path =  map_mod and map_mod:GetRealFilePath(BeardLib.Utils.Path:Combine(map_path, "main.xml"))
    local data = mainxml_path and proj:get_clean_data(FileIO:ReadScriptDataFrom(mainxml_path, "custom_xml"))
    local level = data and proj:current_level(data)
    local to_copy = {}
    if map_mod then
        level.add = level.add or {_meta = "add", directory = "assets", units = {}}
        for k,v in pairs(config) do
            local exists 
            for _, tbl in pairs(level.add) do
                if type(tbl) == "table" and tbl._meta == v._meta and tbl.path == v.path then
                    exists = true
                    break
                end
            end

            if not exists then
                table.insert(level.add, v)
                table.insert(to_copy, v)
            end
        end      
        
        function save()
            FileIO:WriteScriptDataTo(mainxml_path, data, "custom_xml")
            for _, asset in pairs(to_copy) do
                if type(asset) == "table" then
                    local path = asset.path .. "." .. asset._meta
                    FileIO:CopyFileTo(BeardLib.Utils.Path:Combine(BeardLibEditor.ExtractDirectory, path), BeardLib.Utils.Path:Combine(map_path, level.add.directory or "", path))
                end
            end
        end
        if not dontask then
            BeardLibEditor.Utils:YesNoQuestion("This will copy the required files from your extract directory and add the files to your package proceed?", save, function()
                if not dontspawn then
                    self:Manager("static"):delete_selected()
                end
                CustomPackageManager:UnloadPackageConfig(config)
            end)
        else
            save()
        end
    end
end

function SpawnSelect:OpenSpawnPrefabDialog()
    local prefabs = {}
    for name, prefab in pairs(BeardLibEditor.Prefabs) do
        table.insert(prefabs, {name = name, prefab = prefab})
    end
    BeardLibEditor.managers.ListDialog:Show({
        list = prefabs,
        force = true,
        callback = function(item)
            self:Manager("static"):SpawnPrefab(item.prefab)
            BeardLibEditor.managers.ListDialog:hide()
        end
    }) 
end

function SpawnSelect:OpenSpawnInstanceDialog()
    local instances = {}
    for _, path in pairs(BeardLibEditor.Utils:GetEntries({type = "world"})) do
        if path:match("levels/instances") then
            table.insert(instances, path)
        end
    end
    BeardLibEditor.managers.ListDialog:Show({
        list = instances,
        force = true,
        callback = function(item)
            local continent = managers.worlddefinition._continent_definitions[self._parent._current_continent]
            if continent then
                continent.instances = continent.instances or {}
                local instance_name = Path:GetFileName(Path:GetDirectory(item)).."_"
                local instances = managers.world_instance:instance_names()
                local i = 1
                while(table.contains(instances, instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i)) do
                    i = i + 1
                end
                instance_name = instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i
                local instance = {
                    continent = self._parent._current_continent,
                    name = instance_name,
                    folder = item,
                    position = self._parent:cam_spawn_pos(),
                    rotation = Rotation(),
                    script = self._parent._current_script,
                    index_size = 1000,
                    start_index = managers.world_instance:get_safe_start_index(1000, self._parent._current_continent)
                }
                table.insert(continent.instances, instance)
                for _, mission in pairs(managers.mission._missions) do
                    if mission[instance.script] then
                        table.insert(mission[instance.script].instances, instance_name)
                        break
                    end
                end
                managers.world_instance:add_instance_data(instance)
                managers.worlddefinition:prepare_for_spawn_instance(instance)
                local instance_data = managers.world_instance:get_instance_data_by_name(instance_name)
                local prepare_mission_data = managers.world_instance:prepare_mission_data_by_name(instance_name)
                local script = managers.mission._scripts[instance.script]
                if not instance_data.mission_placed then
                    script:create_instance_elements(prepare_mission_data)
                else
                    script:_preload_instance_class_elements(prepare_mission_data)
                end
            end
            BeardLibEditor.managers.ListDialog:hide()
        end
    })
end

function SpawnSelect:OpenSpawnElementDialog()
    local held_ctrl
	BeardLibEditor.managers.ListDialog:Show({
	    list = BeardLibEditor._config.MissionElements,
        force = true,
	    callback = function(item)
            self._parent:add_element(item, held_ctrl)
            held_ctrl = ctrl()
            if not held_ctrl then
	           BeardLibEditor.managers.ListDialog:hide()
            end
	    end
	}) 
end

function SpawnSelect:OpenSelectUnitDialog(params)
    params = params or {}
    local units = {}
    for k, unit in pairs(World:find_units_quick("all")) do
        local ud = unit:unit_data()
        if ud and ud.name and not ud.instance then
            table.insert(units, table.merge({
                name = tostring(unit:unit_data().name_id) .. " [" .. (ud.environment_unit and "env" or tostring(ud.unit_id)) .."]",
                unit = unit,
                color = params.choose_color and params.choose_color(unit),
            }, params))
        end
    end
    BeardLibEditor.managers.ListDialog:Show({
        list = units,
        force = true,
        callback = params.on_click or function(item)
            self._parent:select_unit(item.unit)         
            BeardLibEditor.managers.ListDialog:hide()
        end
    })
end

function SpawnSelect:OpenSelectInstanceDialog(params)
	params = params or {}
	BeardLibEditor.managers.ListDialog:Show({
	    list = managers.world_instance:instance_names(),
        force = true,
	    callback = params.on_click or function(name)
	    	self._parent:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(name)))	        
	    	BeardLibEditor.managers.ListDialog:hide()
	    end
	})
end

function SpawnSelect:OpenSelectElementDialog(params)
    params = params or {}
	local elements = {}
    local held_ctrl
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                	table.insert(elements, {
                        create_group = string.pretty2(element.class:gsub("Element", "")),
                		name = tostring(element.editor_name) .. " [" .. tostring(element.id) .."]",
                		element = element,
                	})
                end
            end
        end
    end
	BeardLibEditor.managers.ListDialog:Show({
	    list = elements,
        force = true,
	    callback = params.on_click or function(item)
            self._parent:select_element(item.element, held_ctrl)
            held_ctrl = ctrl()
            if not held_ctrl then
                BeardLibEditor.managers.ListDialog:hide()
            end
	    end
	}) 
end

function SpawnSelect:BeginSpawning(unit)
    self:Switch()
    self._currently_spawning = unit
    self:remove_dummy_unit()
    if self._parent._spawn_position then
        self._dummy_spawn_unit = World:spawn_unit(Idstring(unit), self._parent._spawn_position)
    end
    self:Manager("menu"):set_tabs_enabled(false)
    self:SetTitle("Press: LMB to spawn, RMB to cancel")
end

function SpawnSelect:OpenSpawnUnitDialog(params)
	params = params or {}
    local pkgs = self._assets_manager:get_level_packages()
	BeardLibEditor.managers.ListDialog:Show({
	    list = BeardLibEditor.Utils:GetUnits({not_loaded = params.not_loaded, packages = pkgs, slot = params.slot, type = params.type, not_type = "being"}),
        force = true,
	    callback = function(unit)
            BeardLibEditor.managers.ListDialog:hide()
	    	if type(params.on_click) == "function" then
	    		params.on_click(unit)
	    	else
                if self._assets_manager:is_asset_loaded(unit, "unit") or not params.not_loaded then
                    if PackageManager:has(Idstring("unit"), unit:id()) then
                        self:BeginSpawning(unit)
                    else
                        BeardLibEditor.Utils:Notify("Error", "Cannot spawn the unit")
                    end
                else
                    BeardLibEditor.Utils:QuickDialog({title = "Well that's annoying..", no = "No", message = "This unit is not loaded and if you want to spawn it you have to load a package for it, search packages for the unit?"}, {{"Yes", function()
                        self._assets_manager:find_package(unit, true)
                    end}})
                end
			end
	    end
	}) 
end

function SpawnSelect:OpenLoadUnitDialog(params)
	BeardLibEditor.managers.ListDialog:Show({
	    list = BeardLibEditor.Utils:GetUnits({not_loaded = true, packages = self._assets_manager:get_level_packages(), check = function(unit)
            return not self._assets_manager:is_asset_loaded(unit, "unit") and not unit:match("wpn_") and not unit:match("msk_")
        end}),
        force = true,
	    callback = function(unit)
            BeardLibEditor.managers.ListDialog:hide()
            self._assets_manager:find_package(unit)
	    end
	}) 
end