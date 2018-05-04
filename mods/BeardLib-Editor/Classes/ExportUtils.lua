BLE.Utils.Export = BLE.Utils.Export or {}
local EditorUtils = BLE.Utils
local Utils = EditorUtils.Export
Utils.return_on_missing = true

function Utils:Add(config, ext, path, exclude, force_load)
	if exclude and exclude[ext] then
        return
    end
    table.insert(config, {_meta = ext, path = path, force = true, unload = true, load = force_load})
end

function Utils:Log(...)
	BLE:log(...)
end

function Utils:GetDependencies(ext, path, ignore_default, exclude)
	if not Utils.Reading[ext] then
		self:Log("Extension %s does not have a read function!", ext)
		return
	end

	local config = {}
    if not Utils.Reading[ext](self, path, config, exclude) then
        return false
	end
	
    local temp = deep_clone(config)
    config = {}
    for _, file in pairs(temp) do
        local file_path = Path:Combine(BLE.ExtractDirectory, file.path.."."..file._meta)
		local ext = file._meta
		if not ignore_default or not (Global.DefaultAssets[ext] and Global.DefaultAssets[ext][file.path] and managers.dyn_resource:has_resource(ext:id(), file.path:id(), managers.dyn_resource.DYN_RESOURCES_PACKAGE)) then
			if FileIO:Exists(file_path) then
				file.extract_real_path = file_path
                table.insert(config, file)
            else
                self:Log("[Unit Import %s] File %s doesn't exist, trying to use the path key instead", tostring(unit), file_path)
                local key_file_path = Path:Combine(BLE.ExtractDirectory, file.path:id():reversed_key().."."..ext)

                if FileIO:Exists(key_file_path) then
                    self:Log("[Unit Import %s] Found missing file %s!", tostring(unit), file_path)
                    file.extract_real_path = key_file_path
                    table.insert(config, file)
                else
                    self:Log("[Unit Import %s] File %s doesn't exist therefore unit cannot be loaded.", tostring(unit), file_path)
					return false
                end

			end
		end
    end
    return config
end

function Utils:ReadUnit(unit, config, exclude)
    self:Add(config, "unit", unit)

    self:Add(config, "cooked_physics", unit, exclude)
    self:Add(config, "model", unit, exclude)

    self:Log("Importing unit from extract to map assets " .. tostring(unit))
	local node = EditorUtils:ParseXml("unit", unit)
	local rom = self.return_on_missing
    if node then
        for child in node:children() do
            local name = child:name()
            if name == "object" then
				if not self:ReadObject(child:parameter("file"), config, exclude) and rom then
                    return false
                end
            elseif name == "dependencies" then
                for dep_child in child:children() do
                    if dep_child:has_parameter("unit") then
                        if not self:ReadUnit(dep_child:parameter("unit"), config, exclude) and rom then
                            return false
                        end
                    else
                        for ext, path in pairs(dep_child:parameters()) do
                            if not exclude or not exclude[ext] then
                                if Utils.Reading[ext] then
                                    if not Utils.Reading[ext](self, path, config, exclude) and rom then
                                        return false
                                    end
                                else
                                    self:Log("[Warning] Unknown file dependency %s.%s for unit %s, continuing...", tostring(path), tostring(ext), tostring(unit))
                                    self:Add(config, ext, path)
                                end
                            end
                        end
                    end
                end
            elseif name == "anim_state_machine" then
                if not self:ReadAnimationStateMachine(child:parameter("name"), config, exclude) and rom then
                    return false
                end
            elseif name == "network" and not exclude.network_unit then
                local remote_unit = child:parameter("remote_unit")
				if remote_unit and remote_unit ~= "" and remote_unit ~= unit then --unsure what to do with remote units that are an empty string.
                    if not self:ReadUnit(remote_unit, config, exclude) and rom then
                        return false
                    end
                end
            end
        end       
	end
	return node ~= nil
end

function Utils:ReadObject(path, config, exclude)
    self:Add(config, "object", path, exclude)
	local node = EditorUtils:ParseXml("object", path)
	local rom = self.return_on_missing
    if node then
        for obj_child in node:children() do
            local name = obj_child:name()
            if name == "diesel" and obj_child:has_parameter("materials") then
                if not self:ReadMaterialConfig(obj_child:parameter("materials"), config, exclude) and rom then
					return false
                end
            elseif name == "sequence_manager" then
                if not self:ReadSequenceManager(obj_child:parameter("file"), config, exclude) and rom then
					return false
                end
            elseif name == "effects" then
				for effect in obj_child:children() do
                    if not self:ReadEffect(effect:parameter("effect"), config, exclude) and rom then
						return false
					end
                end
            elseif name == "animation_def" then
                if not self:ReadAnimationDefintion(obj_child:parameter("name"), config, exclude) and rom then
                    return false
                end
			end
		end
    end
    return node ~= nil
end

function Utils:ReadAnimationStateMachine(path, config, exclude)
    self:Add(config, "animation_state_machine", path, exclude)
	local node = EditorUtils:ParseXml("animation_state_machine", path)
    if node then
        for anim_child in node:children() do    
            if anim_child:name() == "states" then
                self:ReadAnimationStates(anim_child:parameter("file"), config, exclude)
            end
		end
	end
	
    return node ~= nil
end

function Utils:ReadAnimationStates(path, config, exclude)
    self:Add(config, "animation_states", path, exclude)
    return true
end

function Utils:ReadAnimationDefintion(path, config, exclude)
    self:Add(config, "animation_def", path, exclude)
    local node = EditorUtils:ParseXml("animation_def", path)
    if node then
        for anim_child in node:children() do
            if anim_child:name() == "animation_set" then
                for anim_set in anim_child:children() do
                    self:ReadAnimationSubset(anim_set:parameter("file"), config, exclude)
                end
            end
        end
    end
    return node ~= nil
end

function Utils:ReadAnimationSubset(path, config, exclude)
    self:Add(config, "animation_subset", path, exclude)
    local node = EditorUtils:ParseXml("animation_subset", path)
    if node and not exclude.animation then
        for anim_set_child in node:children() do
            self:Add(config, "animation", anim_set_child:parameter("file"))
        end
    end
    return node ~= nil
end

function Utils:ReadSequenceManager(path, config, exclude)
    self:Add(config, "sequence_manager", path, exclude)
	local tbl = EditorUtils:ParseXml("sequence_manager", path, true) -- scriptdata.
	if tbl and tbl.unit then
		for _, sequence in ipairs(tbl.unit) do
			if type(sequence) == "table" and sequence._meta == "sequence" and sequence.spawn_unit then
				self:ReadUnit(sequence.spawn_unit.name:gsub("'", ""), config, exclude)
			end
		end
	end
	return tbl ~= nil
end

function Utils:ReadMaterialConfig(path, config, exclude)
    self:Add(config, "material_config", path, exclude)
	local node = EditorUtils:ParseXml("material_config", path)
	if not exclude.texture then
		for mat_child in node:children() do
			if mat_child:name() == "material" then
				for mat_child_x2 in mat_child:children() do
					if mat_child_x2:has_parameter("file") then
						table.insert(config, {_meta = "texture", path = mat_child_x2:parameter("file"), force = true, unload = true})   
					end
				end
			end
		end
	end
	return node ~= nil
end

function Utils:ReadEffect(path, config, exclude)
    self:Add(config, "effect", path, exclude, true)
	local node = EditorUtils:ParseXml("effect", path)
	local rom = self.return_on_missing
    if node then
        for eff_child in node:children() do
            local name = eff_child:name()
            if name == "atom" then
                for eff_child_x2 in eff_child:children() do
                    local name = eff_child_x2:name()
                    if name == "visualizerstack" then
                        for eff_child_x3 in eff_child_x2:children() do
                            if not exclude.texture and eff_child_x3:has_parameter("texture") then
                                self:Add(config, "texture", eff_child_x3:parameter("texture"))
                            end
                            if eff_child_x3:has_parameter("material_config") then
                                if not self:ReadMaterialConfig(eff_child_x3:parameter("material_config"), config, exclude) and rom then
                                    return false
                                end
                            end
                        end
                    elseif name == "effect_spawn" then
                        if not self:ReadEffect(eff_child_x2:parameter("effect"), config, exclude) and rom then
                            return false
                        end
                    end
                end
            elseif name == "use" then
                if not self:ReadEffect(eff_child:parameter("name"), config, exclude) and rom then
                    return false
                end
            end 
        end
    end
    return node ~= nil
end

function Utils:ReadScene(path, config, exclude)
    self:Add(config, "scene", path, exclude, true)
    local node = EditorUtils:ParseXml("scene", path)
    if node and not exclude.scene then
		for child in node:children() do
			if child:name() == "load_scene" and child:has_parameter("materials") then
				self:ReadMaterialConfig(child:parameter("materials"), config, exclude)
			end
        end
    end
    return node ~= nil
end

function Utils:ReadEnvironment(path, config, exclude)
	self:Add(config, "environment", path, exclude)
	local tbl = EditorUtils:ParseXml("environment", path, true)
	if tbl and tbl.data and tbl.data.others and tbl.data.others.underlay then
		self:ReadScene(tbl.data.others.underlay)
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