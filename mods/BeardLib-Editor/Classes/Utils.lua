getmetatable(Idstring()).s = function(s)
    local t = s:t()
    return managers.editor._idstrings[t] or t
end

BeardLibEditor.Utils = {}
--Sets the position of a unit/object correctly
function BeardLibEditor.Utils:SetPosition(unit, position, rotation, offset)
    if offset and unit:unit_data()._prev_pos and unit:unit_data()._prev_rot then
        local pos = mvector3.copy(unit:unit_data()._prev_pos)
        mvector3.add(pos, position)
        unit:set_position(pos)
        local prev_rot = unit:unit_data()._prev_rot
        local rot = Rotation(prev_rot:yaw(), prev_rot:pitch(), prev_rot:roll())
        rot:yaw_pitch_roll(rot:yaw() + rotation:yaw(), rot:pitch() + rotation:pitch(), rot:roll() + rotation:roll())
        unit:set_rotation(rot)
    else
    	unit:set_position(position)
    	unit:set_rotation(rotation)
    end
    if unit.get_objects_by_type then
        local objects = unit:get_objects_by_type(Idstring("model"))
        for _, object in pairs(objects) do
            object:set_visibility(not object:visibility())
            object:set_visibility(not object:visibility())
        end
        local num = unit:num_bodies()
        for i = 0, num - 1 do
            local unit_body = unit:body(i)
            unit_body:set_enabled(not unit_body:enabled())
            unit_body:set_enabled(not unit_body:enabled())
        end
        unit:unit_data().position = unit:position()
        unit:unit_data().rotation = unit:rotation()
        if unit:mission_element() then
            local element = unit:mission_element().element
            element.values.position = unit:position()
            element.values.rotation = unit:rotation()
        elseif unit:unit_data().name then
            managers.worlddefinition:set_unit(unit:unit_data().unit_id, unit, unit:unit_data().continent, unit:unit_data().continent)        
        end
    end
end

function BeardLibEditor.Utils:ParseXml(typ, path)
    local file = BeardLibEditor.ExtractDirectory .. "/" ..  path .. "." .. typ
    return SystemFS:exists(file) and SystemFS:parse_xml(file, "r")
end

function BeardLibEditor.Utils:ReadUnitAndLoad(unit, load)
    local config = {}
    local path = BeardLib.Utils.Path:Combine(BeardLibEditor.ExtractDirectory, unit)
    log("Checking unit .. " .. tostring( unit ))
    if SystemFS:exists(path ..".unit") then
        table.insert(config, {_meta = "cooked_physics", path = unit, force = true, unload = true})
        table.insert(config, {_meta = "model", path = unit, force = true, unload = true})
        table.insert(config, {_meta = "unit", path = unit, force = true, unload = true})
        log("Adding cooked_physics, moodel and unit of " .. tostring(unit))
        local node = self:ParseXml("unit", unit)
        for child in node:children() do
            local name = child:name()
            if name == "object" then
                local object = child:parameter("file")
                table.insert(config, {_meta = "object", path = object, force = true, unload = true})
                local obj_node = BeardLibEditor.Utils:ParseXml("object", object)
                if obj_node then
                    for obj_child in obj_node:children() do
                        name = obj_child:name() 
                        if name == "diesel" and obj_child:has_parameter("materials") then
                            local material = obj_child:parameter("materials")
                            table.insert(config, {_meta = "material_config", path = material, force = true, unload = true})                             
                            local mat_node = BeardLibEditor.Utils:ParseXml("material_config", material)
                            for mat_child in mat_node:children() do
                                if mat_child:name() == "material" then
                                    for mat_child_child in mat_child:children() do
                                        if mat_child_child:has_parameter("file") then
                                            table.insert(config, {_meta = "texture", path = mat_child_child:parameter("file"), force = true, unload = true})   
                                            log("Adding texture " .. tostring(mat_child_child:parameter("file")))
                                        end
                                    end
                                end 
                            end
                        elseif name == "sequence_manager" then
                            table.insert(config, {_meta = "sequence_manager", path = obj_child:parameter("file"), force = true, unload = true})   
                            log("Adding sequence_manager " .. tostring(obj_child:parameter("file")))
                        elseif name == "effects" then
                            for efct in child:children() do
                                table.insert(config, {_meta = "effect", path = efct:parameter("effect"), force = true, unload = true})   
                                log("Adding effect " .. tostring(efct:parameter("effect")))
                            end
                        elseif name == "animation_def" then
                            local anim_def = obj_child:parameter("name") 
                            table.insert(config, {_meta = name, path = anim_def, force = true, unload = true})   
                            local anim_node = BeardLibEditor.Utils:ParseXml(name, anim_def)
                            for anim_child in anim_node:children() do    
                                if anim_child:name() == "animation_set" then
                                    for anim_set in anim_child:children() do
                                        local anim_subset = anim_set:parameter("file") 
                                        log("Adding animation_subset" .. tostring(anim_subset))
                                        table.insert(config, {_meta = "animation_subset", path = anim_subset, force = true, unload = true})   
                                        local anim_set_node = BeardLibEditor.Utils:ParseXml("animation_subset", anim_subset)
                                        for anim_set_child in anim_set_node:children() do       
                                            log("Adding animation " .. anim_set_child:parameter("file"))          
                                            table.insert(config, {_meta = "animation", path = anim_set_child:parameter("file"), force = true, unload = true}) 
                                        end                      
                                    end   
                                end
                            end                   
                        end
                    end
                end
            elseif name == "dependencies" then
                for dep_child in child:children() do
                    if dep_child:has_parameter("unit") then
                        local read_unit = self:ReadUnitAndLoad(dep_child:parameter("unit"), false)
                        if read_unit then
                            table.merge(config, read_unit)
                        else
                            return false
                        end
                    else
                        for ext, path in pairs(dep_child:parameters()) do
                            log("Adding dependency " .. tostring(ext) .. ", " .. tostring(path))
                            table.insert(config, {_meta = ext, path = path, force = true, unload = true})   
                        end
                    end
                end
            elseif name == "anim_state_machine" then
                local anim_state = child:parameter("name") 
                log("Adding animation state machine " .. tostring(anim_state))
                table.insert(config, {_meta = "animation_state_machine", path = anim_state, force = true, unload = true})   
                local anim_state_node = BeardLibEditor.Utils:ParseXml("animation_state_machine", anim_state)
                for anim_child in anim_state_node:children() do    
                    if anim_child:name() == "states" then
                        local anim_states = anim_child:parameter("file") 
                        log("Adding animation_states " .. tostring(anim_states))
                        table.insert(config, {_meta = "animation_states", path = anim_states, force = true, unload = true}) 
                    end
                end                 
            end
        end
    else
        BeardLibEditor:log("[WARNING] Unit %s is missing from extract, Unit will not spawn!", tostring(unit))
        return false
    end

    if load ~= false then
        local temp = deep_clone(config)
        config = {}
        for _, file in pairs(temp) do
            if not PackageManager:has(Idstring(file._meta):id(), Idstring(file.path):id()) then
                table.insert(config, file)
            end
        end
        CustomPackageManager:LoadPackageConfig("assets/extract", config)
    end
    return config
end

function BeardLibEditor.Utils:GetPackagesOfUnit(unit, first)
    local to_unload
    local found_packages = {}
    local done = {}
    local function pkgload(p)
        if not PackageManager:loaded(p) then
            if PackageManager:package_exists(p.."_init") then
                PackageManager:load(p.."_init") 
               table.insert(to_unload, p.."_init")
            end
            if PackageManager:package_exists(p) then
                PackageManager:load(p)
                table.insert(to_unload, p)
            end
        end
    end
    local function pkgunload()
        for _, p in pairs(to_unload) do
            if PackageManager:loaded(p) then
                DelayedCalls:Add("UnloadPKG"..tostring(p), 0.01, function()
                    log("Unloading temp package " .. tostring(p))
                    PackageManager:unload(p)
                end)
            end
        end
    end
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
    for id, level in pairs(tweak_data.levels) do
        if level.world_name and not done[level.world_name] then
            to_unload = {}
            local level_dir = "levels/"..level.world_name .. "/"
            pkgload(level_dir.."world")
            for c in pairs(PackageManager:script_data(Idstring("continents"), Idstring(level_dir.."continents"))) do
                local p = level_dir..c.."/"..c
                local p_init = p.."_init"
                if PackageManager:package_exists(p_init) then
                    PackageManager:load(p_init)
                end
                for _, static in pairs(PackageManager:script_data(Idstring("continent"), Idstring(p)).statics or {}) do
                    if static.unit_data and static.unit_data.name == unit then
                        table.insert(found_packages, p)
                        if first then
                            if PackageManager:loaded(p_init) then PackageManager:unload(p_init) end
                            pkgunload()
                            PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
                            return found_packages[1]
                        end
                    end
                end
                if PackageManager:loaded(p_init) then PackageManager:unload(p_init) end
            end
            done[level.world_name] = true
        end
    end
    PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
    return found_packages
end

function BeardLibEditor.Utils:HasEditableLights(unit)
    local lights = self:GetLights(unit)
    return lights and #lights > 0
end

function BeardLibEditor.Utils:GetLights(unit)
    local has_lights = #unit:get_objects_by_type(Idstring("light")) > 0
    if not has_lights then
        return nil
    end
    local lights = {}
    local node = self:ParseXml("object", unit:unit_data().name)
    if node then
        for child in node:children() do
            if child:name() == "lights" then
                for light in child:children() do
                    if light:has_parameter("editable") and light:parameter("editable") == "true" then
                        table.insert(lights, {name = light:parameter("name"), object = unit:get_object(Idstring(light:parameter("name")))})
                    end
                end
            end
        end
    end
    return lights
end

local t = {}
for _, intensity in ipairs(LightIntensityDB:list()) do
    table.insert(t, LightIntensityDB:lookup(intensity))
end
table.sort(t)
BeardLibEditor.Utils.IntensityValues = t

function BeardLibEditor.Utils:GetIntensityPreset(multiplier)
    local intensity = LightIntensityDB:reverse_lookup(multiplier)
    if intensity ~= Idstring("undefined") then
        return intensity
    end
    local values = self.IntensityValues
    for i = 1, #values do
        local next = values[i + 1]
        local this = values[i]
        if not next then
            return LightIntensityDB:reverse_lookup(this)
        end
        if multiplier > this and multiplier < next then
            if multiplier - this < next - multiplier then
                return LightIntensityDB:reverse_lookup(this)
            else
                return LightIntensityDB:reverse_lookup(next)
            end
        elseif multiplier < this then
            return LightIntensityDB:reverse_lookup(this)
        end
    end
end

function BeardLibEditor.Utils:LightData(unit)
    local lights = self:GetLights(unit)
    if not lights then
        return nil
    end
    local t = {}
    for _, light in ipairs(lights) do
        local obj = light.object
        local data = {
            name = light.name,
            enabled = obj:enable(),
            far_range = obj:far_range(),
            near_range = obj:near_range(),
            color = obj:color(),
            spot_angle_start = obj:spot_angle_start(),
            spot_angle_end = obj:spot_angle_end(),
            multiplier = self:GetIntensityPreset(obj:multiplier()):s(),
            falloff_exponent = obj:falloff_exponent(),
            clipping_values = obj:clipping_values()
        }
        table.insert(t, data)
    end
    return #t > 0 and t or nil
end

function BeardLibEditor.Utils:HasAnyProjectionLight(unit)
    local has_lights = #unit:get_objects_by_type(Idstring("light")) > 0
    if not has_lights then
        return nil
    end
    return BeardLibEditor.Utils:HasProjectionLight(unit, "shadow_projection") or BeardLibEditor.Utils:HasProjectionLight(unit, "projection")
end

function BeardLibEditor.Utils:HasProjectionLight(unit, type)
    type = type or "projection"
    local node = self:ParseXml("object", unit:unit_data().name)
    if node then
        for child in node:children() do
            if child:name() == "lights" then
                for light in child:children() do
                    if light:has_parameter(type) and light:parameter(type) == "true" then
                        return light:parameter("name")
                    end
                end
            end
        end
    end
    return nil
end

function BeardLibEditor.Utils:IsProjectionLight(unit)
    type = type or "projection"
    local node = self:ParseXml("object", unit:unit_data().name)
    if node then
        for child in node:children() do
            if child:name() == "lights" then
                for light_node in child:children() do
                    if light_node:has_parameter(type) and light_node:parameter(type) == "true" and light:name() == Idstring(light_node:parameter("name")) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function BeardLibEditor.Utils:TriggersData(unit)
    local triggers = managers.sequence:get_trigger_list(unit:name())
    if #triggers == 0 then
        return nil
    end
    local t = {}
    if #triggers > 0 and unit:damage() then
        local trigger_name_list = unit:damage():get_trigger_name_list()
        if trigger_name_list then
            for _, trigger_name in ipairs(trigger_name_list) do
                local trigger_data = unit:damage():get_trigger_data_list(trigger_name)
                if trigger_data and #trigger_data > 0 then
                    for _, data in ipairs(trigger_data) do
                        if alive(data.notify_unit) then
                            table.insert(t, {
                                name = data.trigger_name,
                                id = data.id,
                                notify_unit_id = data.notify_unit:unit_data().unit_id,
                                time = data.time,
                                notify_unit_sequence = data.notify_unit_sequence
                            })
                        end
                    end
                end
            end
        end
    end
    return #t > 0 and t or nil
end

function BeardLibEditor.Utils:EditableGuiData(unit)
    local t
    if unit:editable_gui() then
        t = {
            text = unit:editable_gui():text(),
            font_color = unit:editable_gui():font_color(),
            font_size = unit:editable_gui():font_size(),
            font = unit:editable_gui():font(),
            align = unit:editable_gui():align(),
            vertical = unit:editable_gui():vertical(),
            blend_mode = unit:editable_gui():blend_mode(),
            render_template = unit:editable_gui():render_template(),
            wrap = unit:editable_gui():wrap(),
            word_wrap = unit:editable_gui():word_wrap(),
            alpha = unit:editable_gui():alpha(),
            shape = unit:editable_gui():shape()
        }
    end
    return t
end

function BeardLibEditor.Utils:LadderData(unit)
    local t
    if unit:ladder() then
        t = {
            width = unit:ladder():width(),
            height = unit:ladder():height()
        }
    end
    return t
end

function BeardLibEditor.Utils:ZiplineData(unit)
    local t
    if unit:zipline() then
        t = {
            end_pos = unit:zipline():end_pos(),
            speed = unit:zipline():speed(),
            slack = unit:zipline():slack(),
            usage_type = unit:zipline():usage_type(),
            ai_ignores_bag = unit:zipline():ai_ignores_bag()
        }
    end
    return t
end

function BeardLibEditor.Utils:InSlot(unit, slot)
    local ud = PackageManager:unit_data(Idstring(unit):id())
    if ud then
        local unit_slot = ud:slot()
        for slot in string.gmatch(tostring(slot), "%d+") do
            if tonumber(slot) == unit_slot then
                return true
            end
        end
    end        
    return false
end

function BeardLibEditor.Utils:GetEntries(type, loaded, filterout)
    local entries = {}
    for _, entry in pairs(BeardLibEditor.DBPaths[type]) do
        local pass = true
        if filterout then
            for _, v in pairs(filterout) do
                if entry:match(v) then
                    pass = false
                    break
                end
            end
        end
        if pass and (not loaded or PackageManager:has(Idstring(type), Idstring(entry))) then
            table.insert(entries, entry)
        end
    end
    return entries
end

function BeardLibEditor.Utils:GetUnits(params)
    local units = {}
    for _, unit in pairs(BeardLibEditor.DBPaths.unit) do
        if (params.not_loaded or self:InSlot(unit, params.slot or managers.editor._editor_all)) and (not params.type or self:GetUnitType(unit) == Idstring(params.type)) then
            table.insert(units, unit)
        end
    end
    return units
end

function BeardLibEditor.Utils:GetUnitType(unit)
    if not unit then
        log(debug.traceback())
    end
    local ud = PackageManager:unit_data(Idstring(unit):id())
    return ud and ud:type() 
end

function BeardLibEditor.Utils:Unhash(ids, type)
    for _, path in pairs(BeardLibEditor.DBPaths[type or "other"]) do
        if Idstring(path) == ids then
            return path
        end
    end
    return ids
end

function BeardLibEditor.Utils:FromHashlist(params)
    local d = {}
    local f = {}
    local dir_split = string.split(params.path, "/")
    local dir = BeardLibEditor.DBEntries
    for _, part in pairs(dir_split) do
        dir = dir[part]
    end          
    for key, data in pairs(dir) do
        if tonumber(key) ~= nil then
            if params.files ~= false then
                if not params.type or (data.file_type == params.type and (not params.loaded or PackageManager:has(Idstring(params.type), Idstring(data.path)))) then 
                    table.insert(f, params.full_path and {name = data.name, path = data.path} or data.name)
                end
            end
        elseif params.folders then
            table.insert(d, key)
        end
    end     
    return not check and f, d or false
end

function BeardLibEditor.Utils:YesNoQuestion(title, clbk, no_clbk)
    QuickMenuPlus:new("Are you sure you want to continue?", title, {{text = "Yes", callback = clbk}, {text = "No", callback = no_clbk}}, {no_background = true, position_func = function(panel, wsPanel)
        panel:set_rightbottom(wsPanel:rightbottom())
    end})
end

FakeObject = FakeObject or class()
function FakeObject:init(o)
    self._o = o
end
function FakeObject:rotation()
    return self:alive() and type(self._o.rotation) == "function" and self._o:rotation() or self._o.rotation
end
function FakeObject:position()
    return self:alive() and type(self._o.position) == "function" and self._o:position() or self._o.position
end
function FakeObject:set_position(pos)
    if self:alive() then
        if type(self._o.position) == "function" then
            self._o:set_position(pos)
        else
            self._o.position = pos
        end
    end
end
function FakeObject:set_rotation(rot)
    if self:alive() then
        if type(self._o.rotation) == "function" then
            self._o:set_rotation(rot)
        else
            self._o.rotation = rot
        end
    end
end
function FakeObject:alive()
    return self._o and not self._o.alive and true or self._o:alive()
end