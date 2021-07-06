BLE.Utils.Export = BLE.Utils.Export or class()
local EditorUtils = BLE.Utils
local Utils = EditorUtils.Export
Utils.return_on_missing = true
Utils.check_path_before_insert = false
Utils.pack_extra_info = false
Utils.pack_extract_path = true
Utils.assets_dir = nil
Utils.optional_assets = {cooked_physics = true, bnk = true}
function Utils:init(config)
    config = config or {}
    if config.return_on_missing ~= nil then
        self.return_on_missing = config.return_on_missing
    end
    if config.check_path_before_insert ~= nil then
        self.check_path_before_insert = config.check_path_before_insert
    end
    if config.pack_extra_info ~= nil then
        self.pack_extra_info = config.pack_extra_info
    end
    if config.pack_extract_path ~= nil then
        self.pack_extract_path = config.pack_extract_path
    end
    if config.assets_dir ~= nil then
        self.assets_dir = config.assets_dir
    end
    if config.fallback_to_db_assets then
        self._fallback_to_db_assets = true
    end
end

function Utils:Add(config, ext, path, exclude, extra_info)
	if exclude and exclude[ext] then
        return
    end
    table.insert(config, {_meta = ext, path = path, unload = true, extra_info = self.pack_extra_info and extra_info or nil})
end

function Utils:AddForceLoaded(config, ext, path, exclude, extra_info)
	if exclude and exclude[ext] then
        return
    end
    table.insert(config, {_meta = ext, path = path, unload = true, load = true, extra_info = self.pack_extra_info and extra_info or nil})
end


function Utils:Log(...)
	BLE:log(...)
end

--At the moment only used to confirm all dependencies are loaded
function Utils:CheckFile(ext, path)
	local config = {}
    if Utils.Reading[ext] and not Utils.Reading[ext](self, path, config, {}) then
        return false
    end
    local errors = {}
    for _, file in pairs(config) do
        if not DB:has(file._meta:id(), file.path:id()) then
            table.insert(errors, file)
        end
    end
    return errors
end

local FROM_ASSETS_DIR = 1
local FROM_DB = 2

function Utils:AssetExists(ext, path, lang)
    if self.assets_dir then
        if FileIO:Exists(Path:Combine(self.assets_dir or '', path..(lang and "."..lang or "").."."..ext)) then
            return true, FROM_ASSETS_DIR
        elseif not self._fallback_to_db_assets then
            return false
        end
    end

    return blt.asset_db.has_file(path, ext, {language = lang}), FROM_DB
end

function Utils:ParseXml(ext, path, scriptdata)
    if self.assets_dir then
        local data = EditorUtils:ParseXmlFromAssets(ext, path, scriptdata, self.assets_dir)
        if data then
            return data
        elseif not self._fallback_to_db_assets then
            return nil
        end
    end

    return EditorUtils:ParseXml(ext, path, scriptdata)
end

function Utils:GetDependencies(ext, path, ignore_default, exclude)
    exclude = exclude or {texture = true, model = true, cooked_physics = true, animation = true}
	local config = {}

	if Utils.Reading[ext] and not Utils.Reading[ext](self, path, config, exclude) then
        return false
	end

    local dyn = managers.dyn_resource
    local temp = deep_clone(config)
    config = {}

    local function add_to_config(file, file_path, from)
        if self.pack_extract_path and from == FROM_ASSETS_DIR then
            file.extract_real_path = file_path
        end
        if self._fallback_to_db_assets and from == FROM_DB then
            file.from_db = true
        end
        if not self.check_path_before_insert or FileIO:Exists(file_path) then
            table.insert(config, file)
        end
    end

    for _, file in pairs(temp) do
        local ext = file._meta
        local file_id, ext_id = file.path:id(), ext:id()
        if not ignore_default or not (Global.DefaultAssets[ext] and Global.DefaultAssets[ext][file.path] and dyn:has_resource(ext_id, file_id, dyn.DYN_RESOURCES_PACKAGE)) then
            local is_bnk = ext == "bnk"
            local success
            if is_bnk then
                local possible_bnk_dir = Path:Combine(file.path..".english.bnk")
                if self.assets_dir then
                    possible_bnk_dir = Path:Combine(self.assets_dir, possible_bnk_dir)
                end
                local exists, from = self:AssetExists(ext, file.path, "english")
                if exists then
                    add_to_config(file, possible_bnk_dir, from)
                    success = true
                end
            end
            local file_path = file.path.."."..file._meta
            if self.assets_dir then
                file_path = Path:Combine(self.assets_dir, file_path)
            end
            if not success then
                local exists, from = self:AssetExists(ext, file.path)
                if exists then
                    add_to_config(file, file_path, from)
                elseif not self.optional_assets[ext] then
                    if self.assets_dir then
                        self:Log("[Unit Import %s] File %s doesn't exist", tostring(path), file_path)
                        return false
                    else
                        self:Log("[Unit Import %s] File %s doesn't exist in the database, therefore, unit cannot be loaded.", tostring(path), file_path)
                        return false
                    end
                end
            end
        end
    end
    return config
end

function Utils:ReadUnit(unit, config, exclude, extra_info)
    self:Add(config, "unit", unit, extra_info)

    local file_ext = unit..".unit"
    if not self.assets_dir then
        self:Log("Importing unit from database to map assets " .. tostring(unit))
    end

	local node = self:ParseXml("unit", unit)
	local rom = self.return_on_missing

    if node then
        for child in node:children() do
            local name = child:name()
            if name == "object" then
				if not self:ReadObject(child:parameter("file"), config, exclude, {file = file_ext, where = "object node"}) and rom then
                    return false
                end
            elseif name == "dependencies" then
                for dep_child in child:children() do
                    if dep_child:has_parameter("unit") then
                        if not self:ReadUnit(dep_child:parameter("unit"), config, exclude, {file = file_ext, where = "dependencies node"}) and rom then
                            return false
                        end
                    else
                        for ext, path in pairs(dep_child:parameters()) do
                            if not exclude or not exclude[ext] then
                                if Utils.Reading[ext] then
                                    if not Utils.Reading[ext](self, path, config, exclude, {file = file_ext, where = "dependencies node"}) and rom then
                                        return false
                                    end
                                else
                                    self:Add(config, ext, path, exclude, {file = file_ext, where = "dependencies node"})
                                end
                            end
                        end
                    end
                end
            elseif name == "anim_state_machine" then
                if not self:ReadAnimationStateMachine(child:parameter("name"), config, exclude, {file = file_ext..".unit", where = "anim_state_machine node"}) and rom then
                    return false
                end
            elseif name == "network" and not exclude.network_unit then
                local remote_unit = child:parameter("remote_unit")
				if remote_unit and remote_unit ~= "" and remote_unit ~= unit then --unsure what to do with remote units that are an empty string.
                    if not self:ReadUnit(remote_unit, config, exclude, {file = file_ext, where = "network node/remote_unit value"}) and rom then
                        return false
                    end
                end
            end
        end       
	end
	return node ~= nil
end

function Utils:ReadObject(path, config, exclude, extra_info)
    self:Add(config, "object", path, exclude, extra_info)

    local file_ext = path..".object"


	local node = self:ParseXml("object", path)
	local rom = self.return_on_missing

    if node then
        self:Add(config, "cooked_physics", path, exclude, {file = file_ext, where = "expected dependencies"})
        self:Add(config, "model", path, exclude, {file = file_ext, where = "expected dependencies"})

        for obj_child in node:children() do
            local name = obj_child:name()
            if name == "diesel" and obj_child:has_parameter("materials") then
                if not self:ReadMaterialConfig(obj_child:parameter("materials"), config, exclude, {file = file_ext, where = "diesel node/materials value"}) and rom then
					return false
                end
            elseif name == "sequence_manager" then
                if not self:ReadSequenceManager(obj_child:parameter("file"), config, exclude, {file = file_ext, where = "sequence_manager node"}) and rom then
					return false
                end
            elseif name == "effects" then
				for effect in obj_child:children() do
                    if not self:ReadEffect(effect:parameter("effect"), config, exclude, {file = file_ext, where = "effects node"}) and rom then
						return false
					end
                end
            elseif name == "animation_def" then
                if not self:ReadAnimationDefintion(obj_child:parameter("name"), config, exclude, {file = file_ext, where = "animation_def node"}) and rom then
                    return false
                end
			end
		end
    end
    return node ~= nil
end

function Utils:ReadAnimationStateMachine(path, config, exclude, extra_info)
    self:Add(config, "animation_state_machine", path, exclude, extra_info)
	local node = self:ParseXml("animation_state_machine", path)
    if node then
        for anim_child in node:children() do    
            if anim_child:name() == "states" then
                self:ReadAnimationStates(anim_child:parameter("file"), config, exclude, {file = path..".animation_state_machine", where = "states node"})
            end
		end
	end

    return node ~= nil
end

function Utils:ReadAnimationStates(path, config, exclude, extra_info)
    self:Add(config, "animation_states", path, exclude, extra_info)
    return true
end

function Utils:ReadAnimationDefintion(path, config, exclude, extra_info)
    self:Add(config, "animation_def", path, exclude, extra_info)
    local node = self:ParseXml("animation_def", path)
    if node then
        for anim_child in node:children() do
            if anim_child:name() == "animation_set" then
                for anim_set in anim_child:children() do
                    self:ReadAnimationSubset(anim_set:parameter("file"), config, exclude, {file = path..".animation_def", where = "animation_set node"})
                end
            end
        end
    end
    return node ~= nil
end

function Utils:ReadAnimationSubset(path, config, exclude, extra_info)
    self:Add(config, "animation_subset", path, exclude, extra_info)
    local node = self:ParseXml("animation_subset", path)
    if node and not exclude.animation then
        for anim_set_child in node:children() do
            self:Add(config, "animation", anim_set_child:parameter("file"), exclude, {file = path.."animation_subset", where = "animation node"})
        end
    end
    return node ~= nil
end

function Utils:ReadSequenceManager(path, config, exclude, extra_info)
    self:Add(config, "sequence_manager", path, exclude, extra_info)
	local tbl = self:ParseXml("sequence_manager", path, true) -- scriptdata.
	if tbl and tbl.unit then
		for _, sequence in ipairs(tbl.unit) do
			if type(sequence) == "table" and sequence._meta == "sequence" and sequence.spawn_unit then
                local unit = sequence.spawn_unit.name:gsub("'", "")
                if unit:begins(" ") then
                    unit = unit:sub(2)
                end
                if unit:ends(" ") then
                    unit = unit:sub(1, unit:len()-1)
                end
				self:ReadUnit(unit, config, exclude, {file = path..".sequence_manager", where = "unit node/sequence node/spawn unit value"})
			end
		end
	end
	return tbl ~= nil
end

function Utils:ReadMaterialConfig(path, config, exclude, extra_info)
    self:Add(config, "material_config", path, exclude, extra_info)
	local node = self:ParseXml("material_config", path)
	if node and not exclude.texture then
		for mat_child in node:children() do
			if mat_child:name() == "material" then
				for mat_child_x2 in mat_child:children() do
                    if mat_child_x2:has_parameter("file") then
                        self:Add(config, "texture", mat_child_x2:parameter("file"), exclude, {file = path..".material_config", where = "material node"})
					end
				end
			end
		end
	end
	return node ~= nil
end

function Utils:ReadEffect(path, config, exclude, extra_info)
    self:AddForceLoaded(config, "effect", path, exclude, extra_info)
	local node = self:ParseXml("effect", path)
	local rom = self.return_on_missing

    local file_ext = path..".effect"

    if node then
        for eff_child in node:children() do
            local name = eff_child:name()
            if name == "atom" then
                for eff_child_x2 in eff_child:children() do
                    local name = eff_child_x2:name()
                    if name == "visualizerstack" then
                        for eff_child_x3 in eff_child_x2:children() do
                            if not exclude.texture and eff_child_x3:has_parameter("texture") then
                                self:Add(config, "texture", eff_child_x3:parameter("texture"), {file = file_ext, where = "visualizerstack node"})
                            end
                            if eff_child_x3:has_parameter("material_config") then
                                if not self:ReadMaterialConfig(eff_child_x3:parameter("material_config"), config, exclude, {
                                    file = file_ext, where = "visualizerstack node/material_config value"
                                }) and rom then
                                    return false
                                end
                            end
                        end
                    elseif name == "effect_spawn" then
                        if not self:ReadEffect(eff_child_x2:parameter("effect"), config, exclude, {file = file_ext, where = "effect spawn node/effect value"}) and rom then
                            return false
                        end
                    end
                end
            elseif name == "use" then
                if not self:ReadEffect(eff_child:parameter("name"), config, exclude, {file = file_ext, where = "use node"}) and rom then
                    return false
                end
            end 
        end
    end
    return node ~= nil
end

function Utils:ReadScene(path, config, exclude, extra_info)
    self:Add(config, "scene", path, exclude, extra_info)
    local node = self:ParseXml("scene", path)
    if node and not exclude.scene then
		for child in node:children() do
			if child:name() == "load_scene" and child:has_parameter("materials") then
				self:ReadMaterialConfig(child:parameter("materials"), config, exclude, {file = path..".scene", where = "load_scene node/materials value"})
			end
        end
    end
    return node ~= nil
end

function Utils:ReadEnvironment(path, config, exclude, extra_info)
	self:Add(config, "environment", path, exclude, extra_info)
	local tbl = self:ParseXml("environment", path, true)
	if tbl and tbl.data and tbl.data.others then
        for _, param in pairs(tbl.data.others) do
            if param.key == "underlay" then
                self:ReadScene(param.value, config, exclude, {file = path..".environment", where = "others node/underlay value"})
            end
        end
	end
	return tbl ~= nil
end

Utils.Reading = {
    unit = Utils.ReadUnit,
	scene = Utils.ReadScene,
	environment = Utils.ReadEnvironment,
    object = Utils.ReadObject,
    effect = Utils.ReadEffect,
    material_config = Utils.ReadMaterialConfig,
    sequence_manager = Utils.ReadSequenceManager,
    animation_def = Utils.ReadAnimationDefintion,
    animation_subset = Utils.ReadAnimationSubset,
	animation_states = Utils.ReadAnimationStates,
    animation_state_machine = Utils.ReadAnimationStateMachine
}