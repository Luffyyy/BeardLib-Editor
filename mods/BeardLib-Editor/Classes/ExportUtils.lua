BLE.Utils.Export = BLE.Utils.Export or {}
local EditorUtils = BLE.Utils
local Utils = EditorUtils.Export
Utils.Ignore = {
    ["model"] = true,
    ["texture"] = true,
    ["cooked_physics"] = true
}
--TODO: stop in middle of reading if some file doesn't exist.
--My current theory is that anything binary loads by itself except scriptdatas.
function Utils:GetUnitDependencies(unit, read_all)
    local config = self:ReadUnit(unit, {}, read_all)
    if not config then
        return false
    end
    local temp = deep_clone(config)
    config = {}
    for _, file in pairs(temp) do
        local file_path = Path:Combine(BLE.ExtractDirectory, file.path.."."..file._meta)
        if not read_all and (not Global.DefaultAssets[file._meta] or not Global.DefaultAssets[file._meta][file.path]) then
            if FileIO:Exists(file_path) then
                file.extract_real_path = file_path
                table.insert(config, file)
            else
                BLE:log("[Unit Import %s] File %s doesn't exist, trying to use the path key instead", tostring(unit), file_path)
                local key_file_path = Path:Combine(BLE.ExtractDirectory, file.path:key().."."..file._meta)

                if FileIO:Exists(key_file_path) then
                    BLE:log("[Unit Import %s] Found missing file %s!", tostring(unit), file_path)
                    file.extract_real_path = key_file_path
                    table.insert(config, file)
                else
                    BLE:log("[Unit Import %s] File %s doesn't exist therefore unit cannot be loaded.", tostring(unit), file_path)
                end

                return false
            end
        end
    end
    return config
end

function Utils:ReadUnit(unit, config, read_all)
    local path = Path:Combine(BLE.ExtractDirectory, unit)
    if FileIO:Exists(path ..".unit") then
        table.insert(config, {_meta = "unit", path = unit, force = true, unload = true})
        if read_all then
            table.insert(config, {_meta = "cooked_physics", path = unit, force = true, unload = true})
            table.insert(config, {_meta = "model", path = unit, force = true, unload = true})
        end
        log("Importing unit from extract to map assets" .. tostring(unit))
        local node = EditorUtils:ParseXml("unit", unit)
        for child in node:children() do 
            local name = child:name()
            if name == "object" then
                self:ReadObject(child:parameter("file"), config, read_all)
            elseif name == "dependencies" then
                for dep_child in child:children() do
                    if dep_child:has_parameter("unit") then
                        if not self:ReadUnit(dep_child:parameter("unit"), config, read_all) then
                            return false
                        end
                    else
                        for ext, path in pairs(dep_child:parameters()) do
                            if Utils.Reading[ext] then
                                Utils.Reading[ext](self, path, config, read_all)
                            elseif not Utils.Ignore[ext] then
                                BLE:log("[Warning] Unknown file dependency %s.%s for unit %s, continuing...", tostring(path), tostring(ext), tostring(unit))
                                table.insert(config, {_meta = ext, path = path, force = true, unload = true})
                            end
                        end
                    end
                end
            elseif name == "anim_state_machine" then
                self:ReadAnimationStateMachine(child:parameter("name"), config, read_all)
            end
        end
    else
        BLE:log("[WARNING] Unit %s is missing from extract. Unit will not spawn!", tostring(unit))
        return false
    end
    return config
end

function Utils:ReadObject(object, config, read_all)
    table.insert(config, {_meta = "object", path = object, force = true, unload = true})
    local obj_node = EditorUtils:ParseXml("object", object)
    if obj_node then
        for obj_child in obj_node:children() do
            local name = obj_child:name()
            if name == "diesel" and obj_child:has_parameter("materials") then
                self:ReadMaterialConfig(obj_child:parameter("materials"), config, read_all)
            elseif name == "sequence_manager" then
                self:ReadSequenceManager(obj_child:parameter("file"), config, read_all)
            elseif name == "effects" then
                for effect in obj_child:children() do
                    self:ReadEffect(effect:parameter("effect"), config, read_all)
                end
            elseif name == "animation_def" then
                self:ReadAnimationDefintion(obj_child:parameter("name"), config, read_all)             
            end
        end
    end
end

function Utils:ReadAnimationStateMachine(anim_state_machine, config, read_all)
    table.insert(config, {_meta = "animation_state_machine", path = anim_state_machine, force = true, unload = true})   
    local anim_state_node = EditorUtils:ParseXml("animation_state_machine", anim_state_machine)
    for anim_child in anim_state_node:children() do    
        if anim_child:name() == "states" then
            self:ReadAnimationStates(anim_child:parameter("file") , config, read_all)
        end
    end
end

function Utils:ReadAnimationStates(anim_states, config, read_all)
    table.insert(config, {_meta = "animation_states", path = anim_states, force = true, unload = true}) 
end

function Utils:ReadAnimationDefintion(anim_def, config, read_all)
    table.insert(config, {_meta = "animation_def", path = anim_def, force = true, unload = true})   
    local anim_node = EditorUtils:ParseXml("animation_def", anim_def)
    for anim_child in anim_node:children() do    
        if anim_child:name() == "animation_set" then
            for anim_set in anim_child:children() do
                self:ReadAnimationSubset(anim_set:parameter("file"), config, read_all)
            end
        end
    end
end

function Utils:ReadAnimationSubset(anim_subset, config, read_all)
    table.insert(config, {_meta = "animation_subset", path = anim_subset, force = true, unload = true})   
    local anim_set_node = EditorUtils:ParseXml("animation_subset", anim_subset)
    if anim_set_node then
        for anim_set_child in anim_set_node:children() do
            table.insert(config, {_meta = "animation", path = anim_set_child:parameter("file"), force = true, unload = true}) 
        end
    end
end

function Utils:ReadSequenceManager(sequence, config, read_all)
    table.insert(config, {_meta = "sequence_manager", path = sequence, force = true, unload = true})
end

function Utils:ReadMaterialConfig(material, config, read_all)
    table.insert(config, {_meta = "material_config", path = material, force = true, unload = true})
    if read_all then        
        local mat_node = EditorUtils:ParseXml("material_config", material)
        for mat_child in mat_node:children() do
            if mat_child:name() == "material" then
                for mat_child_x2 in mat_child:children() do
                    if mat_child_x2:has_parameter("file") then
                        table.insert(config, {_meta = "texture", path = mat_child_x2:parameter("file"), force = true, unload = true})   
                    end
                end
            end
        end
    end
end

function Utils:ReadEffect(effect, config, read_all)
    table.insert(config, {_meta = "effect", path = effect, force = true, unload = true})
    local eff_node = EditorUtils:ParseXml("effect", effect)
    for eff_child in eff_node:children() do
        local name = eff_child:name()
        if name == "atom" then
            for eff_child_x2 in eff_child:children() do
                local name = eff_child_x2:name()
                if name == "visualizerstack" then
                    for eff_child_x3 in eff_child_x2:children() do
                        if read_all and eff_child_x3:has_parameter("texture") then
                            table.insert(config, {_meta = "texture", path = eff_child_x3:parameter("texture"), force = true, unload = true})   
                        end
                        if eff_child_x3:has_parameter("material_config") then
                            self:ReadMaterialConfig(eff_child_x3:parameter("material_config"), config, read_all)
                        end
                    end
                elseif name == "effect_spawn" then
                    self:ReadEffect(eff_child_x2:parameter("effect"), config, read_all)
                end
            end
        elseif name == "use" then
            self:ReadEffect(eff_child:parameter("name"), config, read_all)
        end 
    end
end

Utils.Reading = {
    unit = Utils.ReadUnit,
    object = Utils.ReadObject,
    effect = Utils.ReadEffect,
    material_config = Utils.ReadMaterialConfig,
    sequence_manager = Utils.ReadSequenceManager,
    animation_def = Utils.ReadAnimationDefintion,
    animation_subset = Utils.ReadAnimationSubset,
    animation_states = Utils.ReadAnimationStates,
    animation_state_machine = Utils.ReadAnimationStateMachine
}