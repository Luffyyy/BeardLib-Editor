SpawnSelect = SpawnSelect or class(EditorPart)
function SpawnSelect:init(parent, menu)
    self.super.init(self, parent, menu, "Spawn Or Select")    
end

function SpawnSelect:build_default_menu()
    self.super.build_default_menu(self)
    self:Button("Spawn Unit", callback(self, self, "OpenSpawnUnitDialog"))
    if FileIO:Exists(BeardLibEditor.ExtractDirectory) then
    	self:Button("Spawn Unit(extract)", callback(self, self, "OpenSpawnUnitDialog", {on_click = callback(self, self, "SpawnUnitFromExtract"), not_loaded = true}))
    end
    self:Button("Spawn Element", callback(self, self, "OpenSpawnElementDialog"))
    self:Button("Spawn Prefab", callback(self, self, "OpenSpawnPrefabDialog"))
    self:Button("Select Unit", callback(self, self, "OpenSelectUnitDialog", {}))
    self:Button("Select Element", callback(self, self, "OpenSelectElementDialog"))
end

function SpawnSelect:remove_dummy_unit()
    local unit = self._dummy_spawn_unit
    if alive(unit) then
        unit:set_enabled(false)
        unit:set_slot(0)
        World:delete_unit(unit)
    end
end

function SpawnSelect:mouse_pressed(button, x, y)
    if not self._currently_spawning then
        return false
    end
    if button == Idstring("0") then
        self._parent:SpawnUnit(self._currently_spawning)
    elseif button == Idstring("1") then
        self:remove_dummy_unit()
        self._currently_spawning = nil
        self:SetTitle()
        self:Manager("menu"):set_tabs_enabled(true)
        if self:selected_unit() then
            self:Manager("static"):Switch()
        end
    end
    return true
end

function SpawnSelect:update(t, dt)
    if alive(self._dummy_spawn_unit) then
        self._dummy_spawn_unit:set_position(self._parent._spawn_position)
    end
end

function SpawnSelect:SpawnUnitFromExtract(unit, dontask)
    local config = BeardLibEditor.Utils:ReadUnitAndLoad(unit)
    if not config then
        BeardLibEditor:log("[ERROR] Something went wrong when trying to load the unit!")
        return
    end
    self._parent:SpawnUnit(unit)    
    local map_mod = BeardLibEditor.managers.MapProject:current_mod()         
    local data = map_mod and BeardLib.Utils:CleanCustomXmlTable(deep_clone(map_mod._clean_config))
    local level
    if data then
        level = BeardLib.Utils:GetNodeByMeta(data, "level")
        add = BeardLib.Utils:GetNodeByMeta(level, "add")
        if not add then
            add = {_meta = "add", directory = "Assets"}
            table.insert(level, add)
        end
    end
    if map_mod then
        for k,v in pairs(config) do
            local exists 
            for _, tbl in pairs(add) do
                if type(tbl) == "table" and tbl._meta == v._meta and tbl.path == v.path then
                    exists = true
                    break
                end
            end

            if not exists and not PackageManager:has(Idstring(v._meta):id(), Idstring(v.path):id()) then
                log(tostring( v._meta ) .. " = " .. tostring( v.path ))
                table.insert(add, v)
            end
        end      
        local map_path = BeardLibEditor.managers.MapProject:current_path()
        BeardLibEditor.Utils:YesNoQuestion("This will copy the required files from your extract directory and add the files to your package proceed?", function()
            FileIO:WriteScriptDataTo(map_mod:GetRealFilePath(BeardLib.Utils.Path:Combine(map_path, "main.xml")), data, "custom_xml")
            for _, asset in pairs(config) do
                local path = asset.path .. "." .. asset._meta
                FileIO:CopyFileTo(BeardLib.Utils.Path:Combine(BeardLibEditor.ExtractDirectory, path):gsub("/", "\\"), BeardLib.Utils.Path:Combine(map_path, add.directory or "", path):gsub("/", "\\"))
            end
        end, function()
            self:Manager("static"):delete_selected()
            CustomPackageManager:UnloadPackageConfig(config)
        end)
    end
end

function SpawnSelect:OpenSpawnPrefabDialog()
	local prefabs = {}
    for _, prefab in pairs(BeardLibEditor.Options._storage.Prefabs) do
        if type(prefab) == "table" and type(prefab.value) == "table" then
        	table.insert(prefabs, {
        		name = prefab.value.name,
        		prefab = prefab,
        	})
        end
    end
	self._parent._listdia:Show({
	    list = prefabs,
	    callback = function(item)
	    	self:SpawnPrefab(item.prefab.value.units)
	        self._parent._listdia:hide()
	    end
	}) 
end

function SpawnSelect:SpawnPrefab(prefab)
    local SE = self:Manager("static")
    SE._selected_units = {}
    for _, unit in pairs(prefab) do
        self._parent:SpawnUnit(unit.name, nil, true)
    end
    local reference = SE._selected_units[1]
    for k, unit in pairs(SE._selected_units) do
        if unit ~= reference then
            unit:unit_data().position = prefab[k].position
            local pos = prefab[1].position
            local rot = prefab[1].rotation
            unit:unit_data().local_pos = prefab[k].position - pos 
            unit:unit_data().local_rot = rot:inverse() * unit:rotation()
        end
    end
    self._parent:set_unit_positions(reference:position())     
end

function SpawnSelect:OpenSpawnElementDialog()
	self._parent._listdia:Show({
	    list = BeardLibEditor._config.MissionElements,
	    callback = function(item)
	    	self._parent:add_element(item)
	        self._parent._listdia:hide()
	    end
	}) 
end

function SpawnSelect:OpenSelectUnitDialog(params)
	params = params or {}
	local units = {}
 	for k, unit in pairs(managers.worlddefinition._all_units) do            
        if alive(unit) then
    	    table.insert(units, table.merge(table.merge({
    	   		name = tostring(unit:unit_data().name_id) .. " [" .. tostring(unit:unit_data().unit_id) .."]",
    	   		unit = unit,
    	   		color = params.choose_color and params.choose_color(unit),
    	   	}, params), params.merge_with_item and params.merge_with_item(unit) or {}))
        end
    end
	self._parent._listdia:Show({
	    list = units,
	    callback = function(item)
	    	if type(params.on_click) == "function" then
	    		params.on_click(item)
	    	else
	    		self._parent:select_unit(item.unit)	        
	    		self._parent._listdia:hide()
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
	self._parent._listdia:Show({
	    list = elements,
	    callback = function(item)
            if type(params.on_click) == "function" then
                params.on_click(item)
            else
                self._parent:select_element(item.element)
                self._parent._listdia:hide()
            end
	    end
	}) 
end

function SpawnSelect:OpenSpawnUnitDialog(params)
	params = params or {}
	self._parent._listdia:Show({
	    list = BeardLibEditor.Utils:GetUnits({not_loaded = params.not_loaded, slot = params.slot, type = params.type}),
	    callback = function(unit)
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
			self._parent._listdia:hide()
	    end
	}) 
end
 