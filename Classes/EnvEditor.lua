core:import("CoreEnvironmentFeeder")
ShadowBlock = ShadowBlock or class()
function ShadowBlock:init() self._parameters = {} end
function ShadowBlock:map() return self._parameters end
function ShadowBlock:set(key, value) self._parameters[key] = value end
function ShadowBlock:get(key) return self._parameters[key] end

EnvEditor = EnvEditor or class(EditorPart)
function EnvEditor:init(parent, menu)
    self._posteffect = {}
    self._underlayeffect = {}
    self._sky = {}
    self._environment_effects = {}
    self._reported_data_path_map = {}
    self._shadow_blocks = {}
    self._shadow_params = {}
    self.super.init(self, parent, menu, "Environment", {items_size = 16, control_slice = 0.6, offset = 1, use_alpha = false})
end

function EnvEditor:load_included_environments()
    local included = self:GetItem("IncludedEnvironments")
    local level = BeardLib.current_level
    if included and level then
        included:ClearItems()
        for _, include in ipairs(level._config.include) do
            if type(include) == "table" and string.ends(include.file, "environment") then
                local file = Path:Combine(level._mod.ModPath, level._config.include.directory, include.file)
                if FileIO:Exists(file) then
                    local env = included:button(include.file, ClassClbk(self, "open_environment", file), {text = include.file})
                    env:tb_imgbtn("Uniclude", ClassClbk(self, "uninclude_environment_dialog"), nil, {184, 2, 48, 48}, {highlight_color = Color.red, offset = 0})
                end
            end
        end
        if #included._my_items == 0 then
            included:divider("Empty.. :(", {color = false})
        end
    end
end

function EnvEditor:build_default_menu()
    self.super.build_default_menu(self)
    if not managers.viewport:first_active_viewport() then
        return
    end
    local env_path = managers.viewport:first_active_viewport():get_environment_path() or "core/environments/default"
    if BeardLib.current_level then
        local included = self:divgroup("IncludedEnvironments")
        self:load_included_environments()
        included:GetToolbar():tb_btn("IncludeEnvironment", ClassClbk(self, "include_current_dialog"), {text = "Include current", offset = 0})
    end
		
    local quick = self:divgroup("Quick actions")
    quick:button("EffectEditor", ClassClbk(self, "open_effect_editor"))
    quick:button("Browse", ClassClbk(self, "open_environment_dialog"))
    quick:button("LoadGameDefault", ClassClbk(self, "database_load_env", "core/environments/default"))
    quick:button("LoadCurrentDefault", ClassClbk(self, "database_load_env", env_path))
    quick:button("Save", ClassClbk(self, "write_to_disk_dialog"))
    --SUN
    local sun = self:group("Sun")
    self:add_sky_param(sun:colorbox("sun_ray_color", nil, nil, {text = "Color", ret_vec = true}))
    self:add_sky_param(sun:slider("sun_ray_color_scale", nil, 1, {text = "Intensity", step = 0.1, min = 0, max = 10}))

    --FOG
	local fog = self:group("Fog")
	
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", fog:colorbox("fog_start_color", nil, nil, {text = "Start color", ret_vec = true}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", fog:colorbox("fog_far_low_color", nil, nil, {text = "Far low color", ret_vec = true}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", fog:slider("fog_min_range", nil, 1, {text = "Min range", min = 0, max = 5000, floats = 1}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", fog:slider("fog_max_range", nil, 1, {text = "Max range", min = 0, max = 500000, floats = 1}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", fog:slider("fog_max_density", nil, 1, {text = "Max density", min = 0, max = 1}))

    --SKY DOME LIGHT
    local skydome = self:group("Sky Dome Light")
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", skydome:colorbox("sky_top_color", nil, nil, {text = "Top color", ret_vec = true}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", skydome:slider("sky_top_color_scale", nil, 1, {text = "Top scale", step = 0.1, min = 0, max = 10}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", skydome:colorbox("sky_bottom_color", nil, nil, {text = "Bottom color", ret_vec = true}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", skydome:slider("sky_bottom_color_scale", nil, 1, {text = "Bottom scale", step = 0.1, min = 0, max = 10}))

    -- AMBIENT
    local ambient = self:group("Ambient")
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", ambient:colorbox("ambient_color", nil, nil, {text = "Color", ret_vec = true}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", ambient:slider("ambient_color_scale", nil, 1, {text = "Color scale", step = 0.1, min = 0, max = 10}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", ambient:slider("ambient_scale", nil, 1, {text = "Scale", step = 0.1, min = 0, max = 10}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", ambient:slider("ambient_falloff_scale", nil, 1, {text = "Falloff scale", step = 0.1, min = 0, max = 10}))
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", ambient:slider("effect_light_scale", nil, 1, {text = "Effect lighting scale", step = 0.1, min = 0, max = 10}))
    
    -- BLOOM
    local bloom = self:group("Bloom")
    self:add_post_processors_param("deferred", "deferred_lighting", "apply_ambient", bloom:slider("bloom_threshold", nil, 1, {text = "Threshold", min = 0, max = 1, floats = 2}))
    self:add_post_processors_param("bloom_combine_post_processor", "bloom_combine", "bloom_lense", bloom:slider("bloom_intensity", nil, 1, {text = "Intensity", min = 0, max = 10, floats = 2}))
    self:add_post_processors_param("bloom_combine_post_processor", "bloom_combine", "bloom_lense", bloom:slider("bloom_blur_size", nil, 1, {text = "Blur size", min = 1, max = 4, floats = 0}))
    self:add_post_processors_param("bloom_combine_post_processor", "bloom_combine", "bloom_lense", bloom:slider("lense_intensity", nil, 1, {text = "Lense intensity", min = 0, max = 1, floats = 2}))
    
    -- SKY
	local sky = self:group("Sky")
    self:add_underlay_param("sky", sky:colorbox("color0", nil, nil, {text = "Color top", ret_vec = true}))
    self:add_underlay_param("sky", sky:slider("color0_scale", nil, 1, {text = "Color top scale", step = 0.1, min = 0, max = 10}))
    self:add_underlay_param("sky", sky:colorbox("color2", nil, nil, {text = "Color low", ret_vec = true}))
    self:add_underlay_param("sky", sky:slider("color2_scale", nil, 1, {text = "Color low scale", step = 0.1, min = 0, max = 10}))

    -- TEXTURES
    local textures = self:group("Underlay / Textures", {control_slice = 0.5})
    self:add_sky_param(textures:pathbox("underlay", nil, "", "scene", {not_close = true, text = "Underlay", check = function(entry) 
        return not (entry:match("core/levels") or entry:match("levels/zone")) 
    end}))
    self:add_sky_param(textures:pathbox("sky_texture", nil, "", "texture", {not_close = true, text = "Sky Texture"}))
    self:add_sky_param(textures:pathbox("global_texture", nil, "", "texture", {not_close = true, text = "Cubemap"}))
    self:add_sky_param(textures:pathbox("global_world_overlay_texture", nil, "", "texture", {not_close = true, text = "World overlay texture"}))
    self:add_sky_param(textures:pathbox("global_world_overlay_mask_texture", nil, "", "texture", {not_close = true, text = "World overlay mask"}))

    -- SHADOWS
    local shadows = self:group("Shadows", {control_slice = 0.5})
    self._shadow_params.d0 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("d0", nil, 1, {text = "1st slice depth start", min = 0, floats = 0, max = 1000000}))
    self._shadow_params.d1 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("d1", nil, 1, {text = "2nd slice depth start", min = 0, floats = 0, max = 1000000}))
    self._shadow_params.o1 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("o1", nil, 1, {text = "Blend overlap(1st & 2nd)", min = 0, floats = 0, max = 1000000}))
    self._shadow_params.d2 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("d2", nil, 1, {text = "3rd slice depth start", min = 0, floats = 0, max = 1000000}))
    self._shadow_params.d3 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("d3", nil, 1, {text = "3rd slice depth end", min = 0, floats = 0, max = 1000000}))
    self._shadow_params.o2 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("o2", nil, 1, {text = "Blend overlap(2nd & 3rd)", min = 0, floats = 0,  max = 1000000}))
    self._shadow_params.o3 = self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", shadows:slider("o3", nil, 1, {text = "Blend overlap(3rd & 4th)", min = 0, floats = 0, max = 1000000}))

    -- DUMMY SHADOWS
    self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", DummyItem:new("slice0"))
    self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", DummyItem:new("slice1"))
    self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", DummyItem:new("slice2"))
    self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", DummyItem:new("slice3"))
    self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", DummyItem:new("shadow_slice_overlap"))
    self:add_post_processors_param("shadow_processor", "shadow_rendering", "shadow_modifier", DummyItem:new("shadow_slice_depths"))

    self:database_load_env(env_path)

    managers.viewport:first_active_viewport():set_environment_editor_callback(ClassClbk(self, "feed"))
    self._built = true
end

function EnvEditor:load_shadow_data(block)
    for k, v in pairs(block:map()) do
        local param = self._shadow_params[k]
        if param then
            param:SetValue(v)
        end
    end
end

function EnvEditor:parse_shadow_data()
    local values = {}
    values.slice0 = managers.viewport:get_environment_value(self._env_path, CoreEnvironmentFeeder.PostShadowSlice0Feeder.DATA_PATH_KEY)
    values.slice1 = managers.viewport:get_environment_value(self._env_path, CoreEnvironmentFeeder.PostShadowSlice1Feeder.DATA_PATH_KEY)
    values.slice2 = managers.viewport:get_environment_value(self._env_path, CoreEnvironmentFeeder.PostShadowSlice2Feeder.DATA_PATH_KEY)
    values.slice3 = managers.viewport:get_environment_value(self._env_path, CoreEnvironmentFeeder.PostShadowSlice3Feeder.DATA_PATH_KEY)
    values.shadow_slice_overlap = managers.viewport:get_environment_value(self._env_path, CoreEnvironmentFeeder.PostShadowSliceOverlapFeeder.DATA_PATH_KEY)
    values.shadow_slice_depths = managers.viewport:get_environment_value(self._env_path, CoreEnvironmentFeeder.PostShadowSliceDepthsFeeder.DATA_PATH_KEY)
    local block = self:convert_to_block(values)
    self._shadow_blocks[self._env_path] = block
    self:load_shadow_data(block)
end

function EnvEditor:convert_to_block(values)
    local block = ShadowBlock:new()
    block:set("d0", values.shadow_slice_depths.x)
    block:set("d1", values.shadow_slice_depths.y)
    block:set("d2", values.shadow_slice_depths.z)
    block:set("d3", values.slice3.y)
    block:set("o1", values.shadow_slice_overlap.x)
    block:set("o2", values.shadow_slice_overlap.y)
    block:set("o3", values.shadow_slice_overlap.z)
    return block
end

local env_ids = Idstring("environment")
function EnvEditor:database_load_env(env_path)
    if self._last_custom then
        managers.viewport._env_manager._env_data_map[self._last_custom] = nil
        self._last_custom = nil
    end
    self._env_path = env_path
    self:load_env(PackageManager:has(env_ids, env_path:id()) and PackageManager:script_data(env_ids, env_path:id()))
end

function EnvEditor:load_env(env)
    if env then
        for k,v in pairs(env.data) do
            if k == "others" then
                self:database_load_sky(v)
            elseif k == "post_effect" then
                self:database_load_posteffect(v)
            elseif k == "underlay_effect" then
                self:database_load_underlay(v)
            elseif k == "environment_effects" then
                self:database_load_environment_effects(v)
            end    
        end
        self:parse_shadow_data()
        self:set_effect_data(self._environment_effects)
    end
end

function EnvEditor:set_effect_data(active_effects)
   local all_effects = managers.environment_effects:effects_names()
   table.sort(all_effects)
   table.remove_condition(all_effects, function(effect)
       return table.contains(active_effects, effect)
   end)
end

function EnvEditor:database_load_underlay(underlay_effect_node)
    for _, material in pairs(underlay_effect_node) do
        if type(material) == "table" then
            local mat = self._underlayeffect.materials[material._meta]
            if not mat then
                self._underlayeffect.materials[material._meta] = {}
                mat = self._underlayeffect.materials[material._meta]
                mat.params = {}
            end
            for _, param in pairs(material) do
                if type(material) == "table" and param._meta == "param" and param.key and param.key ~= "" and param.value and param.value ~= "" then
                    local k = param.key
                    local l = string.len(k)
                    local parameter = mat.params[k]
                    local remove_param = false
                    if not parameter then
                        local data_path = "underlay_effect/" .. material._meta .. "/" .. k
                        remove_param = not managers.viewport:has_data_path_key(Idstring(data_path):key())
                        if not remove_param then
                            log("Editor doesn't handle value but should: " .. data_path)
                            mat.params[k] = DummyItem:new()
                            parameter = mat.params[k]
                        elseif managers.viewport:is_deprecated_data_path(data_path) then
                        --    log("Deprecated value will be removed next time you save: " .. data_path)
                        else
                            log("Invalid value: " .. data_path)
                        end
                    end
                    if not remove_param and parameter then
                        parameter:SetValue(param.value)
                    end
                end
            end
        end
    end
end

function EnvEditor:database_load_environment_effects(effect_node)
    for _, param in pairs(effect_node) do
        if type(param) == "table" and param._meta == "param" and param.key and param.key ~= "" and param.value and param.value ~= "" then
            self._environment_effects = string.split(param.value, ";")
            table.sort(self._environment_effects)
        end
    end
end

function EnvEditor:database_load_sky(sky_node)
    for _, param in pairs(sky_node) do
        if type(param) == "table" and param._meta == "param" and param.key and param.key ~= "" and param.value and param.value ~= "" then
            local k = param.key
            local l = string.len(k)
            local parameter = self._sky.params[k]
            local remove_param = false
            if not self._sky.params[k] then
                local data_path = "others/" .. k
                remove_param = not managers.viewport:has_data_path_key(Idstring(data_path):key())
                if not remove_param then
                    log("Editor doesn't handle value but should: " .. data_path)
                    self._sky.params[k] = DummyItem:new()
                elseif managers.viewport:is_deprecated_data_path(data_path) then
                --    log("Deprecated value will be removed next time you save: " .. data_path)
                else
                    log("Invalid value: " .. data_path)
                end
            end
            if not remove_param then
                self._sky.params[k]:SetValue(param.value)
            end
        end
    end
end

function EnvEditor:database_load_posteffect(post_effect_node)
    for _, post_processor in pairs(post_effect_node) do
        if type(post_processor) == "table" then
            local post_pro = self._posteffect.post_processors[post_processor._meta]
            if not post_pro then
                self._posteffect.post_processors[post_processor._meta] = {}
                post_pro = self._posteffect.post_processors[post_processor._meta]
                post_pro.effects = {}
            end
            for _, effect in pairs(post_processor) do
                if type(effect) == "table" then
                    local eff = post_pro.effects[effect._meta]
                    if not eff then
                        post_pro.effects[effect._meta] = {}
                        eff = post_pro.effects[effect._meta]
                        eff.modifiers = {}
                    end
                    for _, modifier in pairs(effect) do
                        if type(modifier) == "table" then
                            local mod = eff.modifiers[modifier._meta]
                            if not mod then
                                eff.modifiers[modifier._meta] = {}
                                mod = eff.modifiers[modifier._meta]
                                mod.params = {}
                            end
                            for _, param in pairs(modifier) do
                                if type(param) == "table" and param._meta == "param" and param.key and param.key ~= "" and param.value and param.value ~= "" then
                                    local k = param.key
                                    local l = string.len(k)
                                    local parameter = mod.params[k]
                                    local remove_param = false
                                    if not parameter then
                                        local data_path = "post_effect/" .. post_processor._meta .. "/" .. effect._meta .. "/" .. modifier._meta .. "/" .. k
                                        remove_param = not managers.viewport:has_data_path_key(Idstring(data_path):key())
                                        if not remove_param then
                                            log("Editor doesn't handle value but should: " .. data_path)
                                            mod.params[k] = DummyItem:new()
                                            parameter = mod.params[k]
                                        elseif managers.viewport:is_deprecated_data_path(data_path) then
                                        --    log("Deprecated value will be removed next time you save: " .. data_path)
                                        else
                                            log("Invalid value: " .. data_path)
                                        end
                                    end
                                    if not remove_param and parameter then
                                        parameter:SetValue(param.value)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function EnvEditor:add_sky_param(gui)
    self._sky.params = self._sky.params or {}
    self._sky.params[gui.name] = gui
    return gui
end

function EnvEditor:add_post_processors_param(pro, effect, mod, gui)
    self._posteffect.post_processors = self._posteffect.post_processors or {}
    self._posteffect.post_processors[pro] = self._posteffect.post_processors[pro] or {}
    self._posteffect.post_processors[pro].effects = self._posteffect.post_processors[pro].effects or {}
    self._posteffect.post_processors[pro].effects[effect] = self._posteffect.post_processors[pro].effects[effect] or {}
    self._posteffect.post_processors[pro].effects[effect].modifiers = self._posteffect.post_processors[pro].effects[effect].modifiers or {}
    self._posteffect.post_processors[pro].effects[effect].modifiers[mod] = self._posteffect.post_processors[pro].effects[effect].modifiers[mod] or {}
    self._posteffect.post_processors[pro].effects[effect].modifiers[mod].params = self._posteffect.post_processors[pro].effects[effect].modifiers[mod].params or {}
    self._posteffect.post_processors[pro].effects[effect].modifiers[mod].params[gui.name] = gui
 
    local processor = managers.viewport:first_active_viewport():vp():get_post_processor_effect("World", Idstring(pro))
    if processor then
        local key = Idstring("post_effect/" .. pro .. "/" .. effect .. "/" .. mod .. "/" .. gui.name):key()
        local value = managers.viewport:first_active_viewport():get_environment_default_value(key)
        if value then
            gui:SetValue(value)
        else
            local modifier = processor:modifier(Idstring(mod))
            if modifier and modifier:material():variable_exists(Idstring(gui.name)) then
                local value = modifier:material():get_variable(Idstring(gui.name))
                if value then
                    gui:SetValue(value)
                end
            end
        end
    end
    return gui
end

function EnvEditor:add_underlay_param(mat, gui)
    self._underlayeffect.materials = self._underlayeffect.materials or {}
    self._underlayeffect.materials[mat] = self._underlayeffect.materials[mat] or {}
    self._underlayeffect.materials[mat].params = self._underlayeffect.materials[mat].params or {}
    self._underlayeffect.materials[mat].params[gui.name] = gui

    local material = Underlay:material(Idstring(mat))
    if material and material:variable_exists(Idstring(gui.name)) then
        local value = material:get_variable(Idstring(gui.name))
        if value then
            gui:SetValue(value)
        end
    end
    return gui
end

function EnvEditor:set_data_path(data_path, handler, value)
    local data_path_key = Idstring(data_path):key()
    if value and not self._reported_data_path_map[data_path_key] and not handler:editor_set_value(data_path_key, value) then
        self._reported_data_path_map[data_path_key] = true
        log("Data path is not supported: " .. tostring(data_path))
    end
end

local scene_ids = Idstring("scene")
function EnvEditor:feed(handler, viewport, scene)

    for postprocessor_name, post_processor in pairs(self._posteffect.post_processors) do
        if postprocessor_name == "shadow_processor" then
            local shadow_param_map = {}
            self:shadow_feed_params(shadow_param_map)
            for kpar, vpar in pairs(shadow_param_map) do
                self:set_data_path("post_effect/" .. postprocessor_name .. "/shadow_rendering/shadow_modifier/" .. kpar, handler, vpar)
            end
        else
            for effect_name, effect in pairs(post_processor.effects) do
                for modifier_name, modifier in pairs(effect.modifiers) do
                    for param_name, param in pairs(modifier.params) do
                        self:set_data_path("post_effect/" .. postprocessor_name .. "/" .. effect_name .. "/" .. modifier_name .. "/" .. param_name, handler, param:Value())
                    end
                end
            end
        end
	end
	
    for kmat, vmat in pairs(self._underlayeffect.materials) do
        for kpar, vpar in pairs(vmat.params) do
            self:set_data_path("underlay_effect/" .. kmat .. "/" .. kpar, handler, vpar:Value())
        end
	end

	for kpar, vpar in pairs(self._sky.params) do
		if kpar ~= "underlay" or PackageManager:has(scene_ids, Idstring(vpar:Value())) then
			self:set_data_path("others/" .. kpar, handler, vpar:Value())
		end
    end
end

function EnvEditor:shadow_feed_params(feed_params)
    local interface_params = self._posteffect.post_processors.shadow_processor.effects.shadow_rendering.modifiers.shadow_modifier.params
    local fov_ratio = managers.environment_controller:fov_ratio()
    local d0 = interface_params.d0:Value() * fov_ratio
    local d1 = interface_params.d1:Value() * fov_ratio
    local d2 = interface_params.d2:Value() * fov_ratio
    local d3 = interface_params.d3:Value() * fov_ratio
    local o1 = interface_params.o1:Value() * fov_ratio
    local o2 = interface_params.o2:Value() * fov_ratio
    local o3 = interface_params.o3:Value() * fov_ratio
    local s0 = Vector3(0, d0, 0)
    local s1 = Vector3(d0 - o1, d1, 0)
    local s2 = Vector3(d1 - o2, d2, 0)
    local s3 = Vector3(d2 - o3, d3, 0)
    local shadow_slice_depths = Vector3(d0, d1, d2)
    local shadow_slice_overlaps = Vector3(o1, o2, o3)
    feed_params.slice0 = s0
    feed_params.slice1 = s1
    feed_params.slice2 = s2
    feed_params.slice3 = s3
    feed_params.shadow_slice_depths = shadow_slice_depths
    feed_params.shadow_slice_overlap = shadow_slice_overlaps
    return feed_params
end

function EnvEditor:update(t, dt)
    if not self._built and managers.viewport:first_active_viewport() then
        self:build_default_menu()
    end
end

function EnvEditor:open_default_custom_environment()
    local data = self:GetPart("world"):data()
    local environment = data.environment.environment_values.environment
    local level = BeardLib.current_level
    local map_dbpath = Path:Combine("levels/mods/", level._config.id)
    if string.begins(environment, map_dbpath) then
        local file_path = string.gsub(environment, map_dbpath, Path:Combine(level._mod.ModPath, level._config.include.directory)) .. ".environment"
        if FileIO:Exists(file_path) then
            self:open_environment(file_path)
        else
            BLE.Utils:Notify("ERROR!", "This is not a valid environment file!! "..file_path)
        end
    end
end

function EnvEditor:uninclude_environment_dialog(item)
    BLE.Utils:YesNoQuestion("This will uninclude the environment from your level and will delete the file itself", function()
        local level = BeardLib.current_level
        local pname = item.parent.name
        FileIO:Delete(Path:Combine(level._mod.ModPath, level._config.include.directory, pname))
        self:GetPart("opt"):save_main_xml()
        local env = pname:gsub(".environment", "")
        Global.DBPaths.environment[Path:Combine("levels/mods/", level.id, env)] = nil
        BLE:LoadCustomAssets()
        self:load_included_environments()
    end)
end

function EnvEditor:include_current_dialog(name)
    local level = BeardLib.current_level
    local env_dir = Path:Combine(level._mod.ModPath, level._config.include.directory, "environments")
    BLE.InputDialog:Show({
        title = "Environment name:",
        text = type(name) == "string" and name or self._last_custom and Path:GetFileNameWithoutExtension(self._last_custom) or "",
        check_value = function(name)
            if FileIO:Exists(Path:Combine(env_dir, name..".environment")) then
                BLE.Utils:Notify("Error", string.format("Envrionment with the name %s already exists! Please use a unique name", name))
                return false
            elseif name == "" then
                BLE.Utils:Notify("Error", string.format("Name cannot be empty!", name))
                return false
            elseif string.begins(name, " ") then
                BLE.Utils:Notify("Error", "Invalid ID!")
                return false
            end
            return true
        end,
        callback = function(name)
            self:write_to_disk(Path:Combine(env_dir, name..".environment"))
            self:GetPart("opt"):save_main_xml({{_meta = "file", file = Path:Combine("environments", name..".environment"), type = "custom_xml"}})
            BLE.MapProject:reload_mod(level._mod.Name)
            BLE:LoadCustomAssets()
            self:load_included_environments()
        end
    })
end

function EnvEditor:open_environment(file)
    if not file then
        return
    end
    local read = FileIO:ReadFrom(file, "rb")
    local data
	if read then
        data = read:sub(0, 2):find("<%w") and FileIO:ConvertScriptData(read, "custom_xml") or FileIO:ConvertScriptData(read, "binary")
    end
    local valid = data and data.data and data.data.others and type(data.data.others) == "table"
    local underlay
    if valid then
        for _, param in pairs(data.data.others) do
            if param._meta == "param" and param.key == "underlay" then
                underlay = param.value
                break
            end
        end
    end
    if underlay then
        if PackageManager:has(Idstring("scene"), underlay:id()) then
            BLE.FBD:hide()
            local env_mangaer = managers.viewport._env_manager
            env_mangaer._env_data_map[file] = {}
            env_mangaer:_load_env_data(nil, env_mangaer._env_data_map[file], data.data)
            self._env_path = file
            self._last_custom = file
            self:load_env(data)
            BLE.Utils:Notify("Success!", "Environment is loaded "..file)
        else
            BLE.FBD:hide()
            BLE.Utils:Notify("ERROR!", "Could not loaded environment because underlay scene is unloaded "..file)
        end
    else
        BLE.FBD:hide()
        BLE.Utils:Notify("ERROR!", "This is not a valid environment file!! "..file)
    end
end

function EnvEditor:open_environment_dialog()
    BLE.FBD:Show({where = string.gsub(Application:base_path(), "\\", "/"), extensions = {"environment", "xml"}, file_click = ClassClbk(self, "open_environment")})
end

function EnvEditor:write_to_disk(filepath)
    self._last_custom = filepath
    FileIO:MakeDir(Path:GetDirectory(filepath))
    local file = FileIO:Open(filepath, "w")
    if file then
        file:print("<environment>\n")
        file:print("\t<metadata>\n")
        file:print("\t</metadata>\n")
        file:print("\t<data>\n")
        self:write_sky_orientation(file)
        self:write_sky(file)
        self:write_posteffect(file)
        self:write_underlayeffect(file)
        self:write_environment_effects(file)
        file:print("\t</data>\n")
        file:print("</environment>\n")
        file:close()
        BLE.Utils:Notify("Success!", "Saved environment "..filepath)
    end
end

function EnvEditor:open_effect_editor()
    self._parent._particle_editor_active = true
    self._parent:set_enabled()
end

function EnvEditor:write_to_disk_dialog()
    BLE.InputDialog:Show({title = "Environment file save path:", text = self._last_custom or "new_environment.environment", callback = function(filepath)
        if filepath == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Environment file path cannot be empty!", callback = function()
                self:write_to_disk_dialog()
            end})
            return
        end
        self:write_to_disk(filepath)
    end})
end

function EnvEditor:write_sky_orientation(file)
    file:print("\t\t<sky_orientation>\n")
    file:print("\t\t\t<param key=\"rotation\" value=\"0\" />\n")
    file:print("\t\t</sky_orientation>\n")
end

function EnvEditor:write_posteffect(file)
    file:print("\t\t<post_effect>\n")
    for post_processor_name, post_processor in pairs(self._posteffect.post_processors) do
        if next(post_processor.effects) then
            file:print("\t\t\t<" .. post_processor_name .. ">\n")
            if post_processor_name == "shadow_processor" then
                self:write_shadow_params(file)
            else
                for effect_name, effect in pairs(post_processor.effects) do
                    if next(effect.modifiers) then
                        file:print("\t\t\t\t<" .. effect_name .. ">\n")
                        for modifier_name, mod in pairs(effect.modifiers) do
                            if next(mod.params) then
                                file:print("\t\t\t\t\t<" .. modifier_name .. ">\n")
                                for param_name, param in pairs(mod.params) do
                                    local v = param:Value()
                                    if getmetatable(v) == _G.Vector3 then
                                        v = "" .. param:Value().x .. " " .. param:Value().y .. " " .. param:Value().z
                                    else
                                        v = tostring(param:Value())
                                    end
                                    file:print("\t\t\t\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
                                end
                                file:print("\t\t\t\t\t</" .. modifier_name .. ">\n")
                            end
                        end
                        file:print("\t\t\t\t</" .. effect_name .. ">\n")
                    end
                end
            end
            file:print("\t\t\t</" .. post_processor_name .. ">\n")
        end
    end
    file:print("\t\t</post_effect>\n")
end

function EnvEditor:write_environment_effects(file)
    file:print("\t\t<environment_effects>\n")
    local effects = ""
    for i, effect in ipairs(self._environment_effects) do
        if i > 1 then
            effects = effects .. ";"
        end
        effects = effects .. effect
    end
    file:print("\t\t\t<param key=\"effects\" value=\"" .. effects .. "\"/>\n")
    file:print("\t\t</environment_effects>\n")
end

function EnvEditor:write_shadow_params(file)
    local params = self:shadow_feed_params({})
    file:print("\t\t\t\t<shadow_rendering>\n")
    file:print("\t\t\t\t\t<shadow_modifier>\n")
    for param_name, param in pairs(params) do
        local v = param
        if getmetatable(v) == _G.Vector3 then
            v = "" .. param.x .. " " .. param.y .. " " .. param.z
        else
            v = tostring(param)
        end
        file:print("\t\t\t\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
    end
    file:print("\t\t\t\t\t</shadow_modifier>\n")
    file:print("\t\t\t\t</shadow_rendering>\n")
end

function EnvEditor:write_underlayeffect(file)
    file:print("\t\t<underlay_effect>\n")
    for underlay_name, material in pairs(self._underlayeffect.materials) do
        if next(material.params) then
            file:print("\t\t\t<" .. underlay_name .. ">\n")
            for param_name, param in pairs(material.params) do
                local v = param:Value()
                if getmetatable(v) == _G.Vector3 then
                    v = "" .. param:Value().x .. " " .. param:Value().y .. " " .. param:Value().z
                else
                    v = tostring(param:Value())
                end
                file:print("\t\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
            end
            file:print("\t\t\t</" .. underlay_name .. ">\n")
        end
    end
    file:print("\t\t</underlay_effect>\n")
end

function EnvEditor:write_sky(file)
    file:print("\t\t<others>\n")
    for param_name, param in pairs(self._sky.params) do
        local v = param:Value()
        if getmetatable(v) == _G.Vector3 then
            v = "" .. param:Value().x .. " " .. param:Value().y .. " " .. param:Value().z
        else
            v = tostring(param:Value())
        end
        file:print("\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
    end
    file:print("\t\t</others>\n")
end