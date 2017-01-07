SpawnSelect = SpawnSelect or class(EditorPart)
function SpawnSelect:init(parent, menu)
    self.super.init(self, parent, menu, "SpawnSelect")    
end

function SpawnSelect:build_default_menu()
    self.super.build_default_menu(self)
    self:Button("Spawn Unit", callback(self, self, "OpenSpawnUnitDialog"))
    if BeardLib.current_map_mod and SystemFS:exists(BeardLibEditor.ExtractDirectory) then
    	self:Button("Spawn Unit(extract)", callback(self, self, "OpenSpawnUnitDialog", {
    		on_click = function(unit)
    			local config = BeardLibEditor.Utils:ReadUnitAndLoad(unit)
	    		self._parent:SpawnUnit(unit)	
	    		local map_mod = BeardLib.current_map_mod
	    		local main = map_mod:GetRealFilePath(BeardLib.Utils.Path:Combine(map_mod.ModPath, "main.xml"))
                local data = BeardLib.Utils:CleanCustomXmlTable(deep_clone(BeardLib.current_map_mod._clean_config))
                local level = BeardLib.Utils:GetNodeByMeta(data, "level")
                local add = BeardLib.Utils:GetNodeByMeta(level, "add")
                if not add then
                    add = {_meta = "add", directory = "Assets"}
                    table.insert(level, add)
                end
          
        		for k,v in pairs(config) do
        			local exists 
        			for _, tbl in pairs(add) do
        				if type(tbl) == "table" and tbl._meta == v._meta and tbl.path == v.path then
        					exists = true
                            break
        				end
        			end
        			if not exists then
        				table.insert(add, v)
        			end
        		end               
                BeardLibEditor.Utils:YesNoQuestion("This will copy the required files from your extract directory and add the files to your package proceed?", function()
                    local file = io.open(main, "w")
                    for _, asset in pairs(config) do
                        local path = asset.path .. "." .. asset._meta
                        local q = [["]]
                        os.execute("echo f | xcopy " .. q .. BeardLib.Utils.Path:Combine(BeardLibEditor.ExtractDirectory, path):gsub("/", "\\") .. q .. " " .. q .. BeardLib.Utils.Path:Combine(map_mod.ModPath, add.directory or "", path):gsub("/", "\\") .. q .. "/y")
                    end      
                    file:write(BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(data, "custom_xml"))
                    file:close()
                end)
	    	end,
	    	not_loaded = true,
    	}))
    end
    self:Button("Spawn Element", callback(self, self, "OpenSpawnElementDialog"))
    self:Button("Spawn Prefab", callback(self, self, "OpenSpawnPrefabDialog"))
    self:Button("Select Unit", callback(self, self, "OpenSelectUnitDialog", {}))
    self:Button("Select Element", callback(self, self, "OpenSelectElementDialog"))
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
    local SE = self:Manager("StaticEditor")
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
	    list = ElementEditor._mission_elements,
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
	    table.insert(units, table.merge(table.merge({
	   		name = tostring(unit:unit_data().name_id) .. " [" .. (unit:unit_data().unit_id or "") .."]",
	   		unit = unit,
	   		color = params.choose_color and params.choose_color(unit),
	   	}, params), params.merge_with_item and params.merge_with_item(unit) or {}))
    end
	managers.editor._listdia:Show({
	    list = units,
	    callback = function(item)
	    	if type(params.on_click) == "function" then
	    		params.on_click(item)
	    	else
	    		managers.editor:_select_unit(item.unit)	        
	    		managers.editor._listdia:hide()
	    	end
	    end
	}) 
end

function SpawnSelect:OpenSelectElementDialog()
	local elements = {}
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                	table.insert(elements, {
                		name = element.editor_name .. " [" .. element.id .."]",
                		element = element,
                	})
                end
            end
        end
    end
	self._parent._listdia:Show({
	    list = elements,
	    callback = function(item)
	    	self._parent:_select_element(item.element)
	        self._parent._listdia:hide()
	    end
	}) 
end

function SpawnSelect:OpenSpawnUnitDialog(params)
	params = params or {}
	self._parent._listdia:Show({
	    list = BeardLibEditor.Utils:GetUnits(params.not_loaded),
	    callback = function(unit)
	    	if type(params.on_click) == "function" then
	    		params.on_click(unit)
	    	else
				self._parent:SpawnUnit(unit)	
			end
			self._parent._listdia:hide()	    	 
	    end
	}) 
end
 