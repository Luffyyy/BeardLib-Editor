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
    local quick = self:DivGroup("SpawnSelectLoad", {text = "Spawn/Select/Load"})
    self:Button("Select Unit", callback(self, self, "OpenSelectUnitDialog", {}), {group = quick})
    self:Button("Select Element", callback(self, self, "OpenSelectElementDialog"), {group = quick})
    self:Button("Spawn Unit", callback(self, self, "OpenSpawnUnitDialog"), {group = quick})
    self:Button("Spawn Element", callback(self, self, "OpenSpawnElementDialog"), {group = quick})
    self:Button("Spawn Prefab", callback(self, self, "OpenSpawnPrefabDialog"), {group = quick})
    if FileIO:Exists(BeardLibEditor.ExtractDirectory) then
        self:Button("Spawn Unit from extract", callback(self, self, "OpenSpawnUnitDialog", {on_click = callback(self, self, "SpawnUnitFromExtract"), not_loaded = true}), {group = quick})
        self:Button("Load Unit from extract", callback(self, self, "OpenSpawnUnitDialog", {on_click = callback(self, self, "SpawnUnitFromExtractNoSpawn"), not_loaded = true}), {group = quick})
    end
    local numerr = table.size(self._parent._errors)
    local fixes = self:DivGroup("Fixes", {help = "Quick fixes for common issues"})
    self:Button("Remove brush(massunits) layer", callback(self, self, "remove_brush_layer"), {
        group = fixes,
        help = "Brushes/Mass units are small decals in the map such as garbage on floor and such, sadly the editor has no way of editing it, the best you can do is remove it."
    })
    self:Button("Fix mission elements' indexes", callback(self, self, "fix_elements_indexes"), {
        group = fixes,
        help = "This issue can happen after manually editing the mission scripts and will cause your mission to not work this simply reorders the elements so it works"
    })
    self:DivGroup("Errors", {text = tostring(numerr).." Errors", color = numerr > 0 and Color.red or quick.color})
    self:ShowErrors()
end

function SpawnSelect:ShowErrors()
    if not BeardLibEditor.managers.MapProject or not BeardLibEditor.managers.MapProject:current_mod() then
        return
    end
    local function fixed_errors(typ, val)
        for k, v in pairs(self._parent._errors) do
            if v.type == typ and v.value == val then
                self._parent._errors[k] = nil  
            end
        end
        self:build_default_menu()
        QuickMenuPlus:new("Error(s) Fixed!", "Please restart the level.")
    end
    for _, error in pairs(self._parent._errors) do
        local typ = error.type
        local val = error.value

        local errgroup = self:GetItem(typ) or self:DivGroup(typ, {text = string.pretty(typ), color = Color.red, group = self:GetItem("Errors")})
        local erritem = self:GetItem(typ.."/"..val)
        if erritem then
            erritem.count = erritem.count + 1
            erritem:SetText(val.."("..tostring(erritem.count)..")")
        else
            erritem = self:DivGroup(typ.."/"..val, {text = val, items_size = 14, color = Color.red, align_method = "grid", group = errgroup})
            erritem.count = 1
            if typ == "missing_unit" then
                self:Button("LoadUnitFromExtract", function()
                    self:SpawnUnitFromExtract(val, true, true) 
                    fixed_errors(typ, val)
                end, {group = erritem, size_by_text = true})
                self:Button("SearchPackage", function()
                    local package = BeardLibEditor.Utils:GetPackagesOfUnit(val, true)
                    local proj = BeardLibEditor.managers.MapProject
                    local map_mod = proj:current_mod()
                    local map_path = proj:current_path()
                    local mainxml_path = map_mod and map_mod:GetRealFilePath(BeardLib.Utils.Path:Combine(map_path, "main.xml"))
                    local data = mainxml_path and proj:get_clean_data(FileIO:ReadScriptDataFrom(mainxml_path, "custom_xml"))
                    local level = proj:current_level(data)
                    if level then
                        if not table.contains(level.packages, package) then
                            table.insert(level.packages, package)
                        end
                        FileIO:WriteScriptDataTo(mainxml_path, data, "custom_xml")
                        fixed_errors(typ, val)                  
                    else
                        BeardLibEditor:log("[ERROR] Something went wrong when trying to get current level in [SpawnSelect:ShowErrors:SearchPackage]")
                    end
                end, {group = erritem, size_by_text = true})
            end
        end
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
            self:Manager("menu"):Switch("static")
            self._do_switch = false
        end
    end
    return true
end

function SpawnSelect:update(t, dt)
    self.super.update(self, t, dt)
    if alive(self._dummy_spawn_unit) then
        self._dummy_spawn_unit:set_position(self._parent._spawn_position)
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
        level.add = level.add or {_meta = "add", directory = "Assets"}
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
	    callback = function(item)
	    	self:Manager("static"):SpawnPrefab(item.prefab)
	        BeardLibEditor.managers.ListDialog:hide()
	    end
	}) 
end

function SpawnSelect:OpenSpawnElementDialog()
	BeardLibEditor.managers.ListDialog:Show({
	    list = BeardLibEditor._config.MissionElements,
	    callback = function(item)
            self._parent:add_element(item)
	        BeardLibEditor.managers.ListDialog:hide()
	    end
	}) 
end

function SpawnSelect:OpenSelectUnitDialog(params)
	params = params or {}
	local units = {}
 	for k, unit in pairs(managers.worlddefinition._all_units) do            
        if alive(unit) then
    	    table.insert(units, table.merge({
    	   		name = tostring(unit:unit_data().name_id) .. " [" .. tostring(unit:unit_data().unit_id) .."]",
    	   		unit = unit,
    	   		color = params.choose_color and params.choose_color(unit),
    	   	}, params))
        end
    end
	BeardLibEditor.managers.ListDialog:Show({
	    list = units,
	    callback = function(item)
	    	if type(params.on_click) == "function" then
	    		params.on_click(item)
	    	else
	    		self._parent:select_unit(item.unit)	        
	    		BeardLibEditor.managers.ListDialog:hide()
	    	end
	    end
	}) 
end

function SpawnSelect:OpenSelectElementDialog(params)
    params = params or {}
	local elements = {}
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
	    callback = function(item)
            if type(params.on_click) == "function" then
                params.on_click(item)
            else
                self._parent:select_element(item.element)
                BeardLibEditor.managers.ListDialog:hide()
            end
	    end
	}) 
end

function SpawnSelect:OpenSpawnUnitDialog(params)
	params = params or {}
	BeardLibEditor.managers.ListDialog:Show({
	    list = BeardLibEditor.Utils:GetUnits({not_loaded = params.not_loaded, slot = params.slot, type = params.type}),
	    callback = function(unit)
            BeardLibEditor.managers.ListDialog:hide()
	    	if type(params.on_click) == "function" then
	    		params.on_click(unit)
	    	else
                self._currently_spawning = unit
                self:remove_dummy_unit()
                if self._parent._spawn_position then
                    self._dummy_spawn_unit = World:spawn_unit(Idstring(unit), self._parent._spawn_position)
                end
                self:Manager("menu"):set_tabs_enabled(false)
                self:SetTitle("Press: LMB to spawn, RMB to cancel")
			end
	    end
	}) 
end
 