MapEditor = MapEditor or class()
core:import("CoreEditorWidgets")
local me = MapEditor
function me:init()
    managers.editor = self
    if not PackageManager:loaded("core/packages/editor") then
        PackageManager:load("core/packages/editor")
    end
    World:get_object(Idstring("ref")):set_visibility(false)
    self._current_continent = "world"
    self._grid_size = 1
    self._errors = {}
    self._current_pos = Vector3(0, 0, 0)
    self._snap_rotation = 90
    self._screen_borders = {x = 1280, y = 720}
	self._camera_object = World:create_camera()
    self._camera_object:set_near_range(20)
	self._camera_object:set_far_range(250000)
    self._camera_object:set_fov(75)
	self._camera_object:set_position(Vector3(0, 0, 220))
	self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()
    self._editor_all = World:make_slot_mask(1, 10, 11, 15, 19, 29, 34, 35, 36, 37, 38, 39)
	self._con = managers.menu._controller
    self._move_widget = CoreEditorWidgets.MoveWidget:new(self)
    self._rotate_widget = CoreEditorWidgets.RotationWidget:new(self)
    self:check_has_fix()
    self:_init_post_effects()
    self._idstrings = {
        ["@ID4f01cba97e94239b@"] = "x",
        ["@IDce15c901d9af3e30@"] = "y",
        ["@ID1a99fc522e3faad0@"] = "z",
        ["@IDc126f12c99c8804d@"] = "xy",
        ["@ID5dac81a18d09497c@"] = "xz",
        ["@ID0602a12dbeee9c14@"] = "yz",
    }
    Input:keyboard():add_trigger(Idstring("f10"), function()
        if not self._enabled then
            self._before_state = game_state_machine:current_state_name()
            game_state_machine:change_state_by_name("editor")
        elseif managers.platform._current_presence == "Playing" then
            game_state_machine:change_state_by_name(self._before_state or "ingame_waiting_for_players")
        else
            game_state_machine:change_state_by_name("ingame_waiting_for_players")
        end
    end)
    self._menu = MenuUI:new({
        text_color = Color.white,
        marker_color = Color.white:with_alpha(0),
        marker_highlight_color = BeardLibEditor.Options:GetValue("AccentColor"),
        mouse_press = callback(self, self, "mouse_pressed"),
        mouse_release = callback(self, self, "mouse_released"),
        create_items = callback(self, self, "post_init"),
    })
end

function me:post_init(menu)
    self.managers = {}    
    self.managers.menu = UpperMenu:new(self, menu)
    for k, v in pairs({mission = MissionEditor, static = StaticEditor, opt = GameOptions, spwsel = SpawnSelect, wdata = WorldDataEditor, console = EditorConsole, env = EnvEditor}) do
        self.managers[k] = v:new(self, menu)
    end
    self.managers.menu:build_tabs()
    self.managers.static:Switch()
    menu.mouse_move = callback(self.managers.static, self.managers.static, "mouse_moved")
    if self._has_fix then
        self.managers.menu:toggle_widget("move")
    end
end

--functions

function me:add_error(data)
    table.insert(self._errors, data)
    self.managers.spwsel:build_default_menu()
    self.managers.spwsel:Switch()
end

function me:check_has_fix()
    local unit = World:spawn_unit(Idstring("core/units/move_widget/move_widget"), Vector3())
    self._has_fix = World:raycast("ray", unit:position(), unit:position():with_z(100), "ray_type", "widget", "target_unit", unit) ~= nil
    unit:set_enabled(false)
    unit:set_slot(0)
    if not self._has_fix then 
        BeardLibEditor:log("Warning: PDMOD fix not found, Some editor features will not be available.")
    end
end

function me:update_grid_size(menu, item)
    self._grid_size = tonumber(item.value)
    for _, manager in pairs(self.managers) do
        if manager.update_grid_size then
            manager:update_grid_size()
        end
    end
end

function me:reset_widget_values()
    self._using_move_widget = false
    self._using_rotate_widget = false
    self._move_widget:reset_values()
    self._rotate_widget:reset_values()
end

function me:use_widgets()
    self._move_widget:set_use(self._use_move_widget and self:enabled() and alive(self:selected_unit()))
    self._move_widget:set_enabled(self._use_move_widget and self:enabled() and alive(self:selected_unit()))
    self._rotate_widget:set_use(self._use_rotation_widget and self:enabled() and alive(self:selected_unit()))
    self._rotate_widget:set_enabled(self._use_rotation_widget and self:enabled() and alive(self:selected_unit()))
end

function me:mouse_moved(x, y)
    self.managers.static:mouse_moved(x, y)
end

function me:mouse_released(button, x, y)
    self.managers.static:mouse_released(button, x, y)
    self._mouse_hold = false
    self:reset_widget_values()
end

function me:mouse_pressed(button, x, y)
    if self._menu:MouseInside() then
        return
    end
    if self.managers.spwsel:mouse_pressed(button, x, y) then
        return
    end
    self.managers.static:mouse_pressed(button, x, y)
end

function me:select_unit(unit, add)
    --self.managers.static:Switch()
    self.managers.static:set_selected_unit(unit, add)
end

function me:select_element(element)
    for _, unit in pairs(World:find_units_quick("all")) do
        if unit:mission_element() and unit:mission_element().element.id == element.id then
            self:select_unit(unit)
            break
        end
    end
    self.managers.mission:set_element(element)
    self.managers.static:Switch()
end

function me:DeleteUnit(unit)
    if alive(unit) then
        if unit:mission_element() then 
            managers.mission:delete_element(unit:mission_element().element.id) 
            if managers.editor then
                self.managers.mission:remove_element_unit(unit)
            end
        end
        local ud = unit:unit_data()
        if ud then
            if ud.occ_shape then
                ud.occ_shape:set_unit()
                ud.occ_shape:destroy()
            end
            if ud.environment_area then
                ud.environment_area:set_unit()
                managers.environment_area:remove_area(ud.environment_area)
            end
            if ud.current_effect then
                World:effect_manager():kill(ud.current_effect)
            end
            managers.worlddefinition:delete_unit(unit)
        end
        World:delete_unit(unit)
    end
end

function me:SpawnUnit(unit_path, old_unit, add)   
    local cam = managers.viewport:get_current_camera()
    if self.managers.wdata.managers.env:is_env_unit(unit_path) then
        local data = type(old_unit) == "userdata" and old_unit:unit_data() or old_unit
        data.position = data.position or cam:position() + cam:rotation():y()
        local unit = self.managers.wdata.managers.env:do_spawn_unit(unit_path, data)
        if alive(unit) then self:select_unit(unit, add) end
        return
    end
    local data = {}
    local t 
    if type(old_unit) == "userdata" then
        data = {
            unit_data = deep_clone(old_unit:unit_data()),
            wire_data = old_unit:wire_data() and deep_clone(old_unit:wire_data()),
            ai_editor_data = old_unit:ai_editor_data() and deep_clone(old_unit:ai_editor_data()),
        }
        t = old_unit:wire_data() and "wire" or old_unit:ai_editor_data() and "ai" or ""
        data.unit_data.name_id = nil
        data.unit_data.unit_id = managers.worlddefinition:GetNewUnitID(data.unit_data.continent or self._current_continent, t)
    else
        t = BeardLibEditor.Utils:GetUnitType(unit_path)
        local ud = old_unit and old_unit.unit_data
        local wd = old_unit and old_unit.wire_data 
        local ad = old_unit and old_unit.ai_editor_data
        data = {
            unit_data = {
                unit_id = managers.worlddefinition:GetNewUnitID(ud and ud.continent or self._current_continent, t),
                name = unit_path,
                mesh_variation = ud and ud.mesh_variation,
                position = ud and ud.position or self._spawn_position or cam:position() + cam:rotation():y(),
                rotation = ud and ud.rotation or Rotation(0,0,0),
                continent = ud and ud.continent or self._current_continent,
                material_variation = ud and ud.material_variation,
                disable_shadows = ud and ud.disable_shadows,
                disable_collision = ud and ud.disable_collision,
                hide_on_projection_light = ud and ud.hide_on_projection_light,
                disable_on_ai_graph = ud and ud.disable_on_ai_graph,
                lights = ud and ud.lights,
                projection_light = ud and ud.projection_light,
                projection_lights = ud and ud.projection_lights,
                projection_textures = ud and ud.projection_textures,
                triggers = ud and ud.triggers, 
                editable_gui = ud and ud.editable_gui,
                ladder = ud and ud.ladder, 
                zipline = ud and ud.zipline,
            }
        }
        if t == Idstring("wire") then
            data.wire_data = wd or {
                slack = 0,
                target_pos = data.unit_data.position,
                target_rot = Rotation() 
            }
        elseif t == Idstring("ai") then
            data.ai_editor_data = ad or {
                visibilty_exlude_filter = {},
                visibilty_include_filter = {},
                location_id = "location_unknown",
                suspicion_mul = 1,
                detection_mul = 1                
            }
        end
    end
    local unit = managers.worlddefinition:create_unit(data, t)
    if alive(unit) then
        self:select_unit(unit, add)
        if unit:name() == self.managers.static._nav_surface then
            table.insert(self.managers.static._nav_surfaces, unit)
        end
    else
        BeardLibEditor:log("Got a nil unit '%s' while attempting to spawn it", tostring(unit_path))
    end

    return unit
end

function me:set_camera(pos, rot)
    if pos then
        self._camera_object:set_position(pos)
        self._camera_pos = pos
    end
    if rot then
        self._camera_object:set_rotation(rot)
        self._camera_rot = rot
    end
end

function me:set_enabled(enabled)
    self._enabled = enabled
    if enabled then
        self._menu:enable()
        managers.hud:set_disabled()
    else
        self._menu:disable()
        managers.hud:set_enabled()
    end
    self._vp:set_active(enabled)
    if type(managers.enemy) == "table" then
        managers.enemy:set_gfx_lod_enabled(not enabled)
    end
    if managers.hud then
        managers.hud:set_enabled()
    end
    for _, manager in pairs(self.managers) do
        if enabled then
            if manager.enable then
                manager:enable()
            end        
        else
            if manager.disable then
                manager:disable()
            end
        end
    end
end

function me:set_unit_positions(pos)
    local reference = self:widget_unit()
    BeardLibEditor.Utils:SetPosition(reference, pos, reference:rotation())
    for _, unit in ipairs(self.managers.static._selected_units) do
        if unit ~= self:selected_unit() then
            self:set_unit_position(unit, pos)
        end
    end
end

function me:set_unit_rotations(rot)
    local reference = self:widget_unit()
    BeardLibEditor.Utils:SetPosition(reference, reference:position(), rot)
    for _, unit in ipairs(self.managers.static._selected_units) do
        if unit ~= self:selected_unit() then
            self:set_unit_position(unit, nil, rot * unit:unit_data().local_rot)
        end
    end
end

function me:load_continents(continents)
    self._continents = {}
    self._current_continent = continents[self._current_continent] and self._current_continent
    for continent, _ in pairs(continents) do
        self._current_continent = self._current_continent or continent
        table.insert(self._continents, continent)
    end
    for _, manager in pairs(self.managers) do
        if manager.loaded_continents then
            manager:loaded_continents(self._continents, self._current_continent)
        end
    end
end


function me:set_camera_fov(fov)
    if math.round(self:camera():fov()) ~= fov then
        self._vp:pop_ref_fov()
        self._vp:push_ref_fov(fov)
        self:camera():set_fov(fov)
    end
end

--Short functions
function me:set_unit_position(unit, pos, rot) BeardLibEditor.Utils:SetPosition(unit, pos and (pos + unit:unit_data().local_pos) or unit:position(), rot or unit:rotation()) end
function me:update_snap_rotation(menu, item) self._snap_rotation = tonumber(item.value) end
function me:destroy() self._vp:destroy() end
function me:add_element(element, menu, item) self.managers.mission:add_element(element) end
function me:Log(...) self.managers.console:Log(...) end
function me:Error(...) self.managers.console:Error(...) end

--Return functions
function me:local_rot() return true end
function me:enabled() return self._enabled end
function me:selected_unit() return self:selected_units()[1] end
function me:selected_units() return self.managers.static._selected_units end
function me:widget_unit() return self.managers.static:widget_unit() or self.managers.wdata:widget_unit() or self:selected_unit() end
function me:widget_rot() return self:widget_unit():rotation() end
function me:grid_size() return ctrl() and 1 or self._grid_size end
function me:snap_rotation() return ctrl() and 1 or self._snap_rotation end
function me:get_cursor_look_point(dist) return self._camera_object:screen_to_world(self:cursor_pos() + Vector3(0, 0, dist)) end
function me:world_to_screen(pos) return self._camera_object:world_to_screen(pos) end
function me:screen_to_world(pos, dist) return self._camera_object:screen_to_world(pos + Vector3(0, 0, dist)) end
function me:camera() return self._camera_object end
function me:camera_fov() return self:camera():fov() end
function me:set_camera_far_range(range) return self:camera():set_far_range(range) end

function me:_should_draw_body(body)
    if not body:enabled() then
        return false
    end
    if body:has_ray_type(Idstring("editor")) and not body:has_ray_type(Idstring("walk")) and not body:has_ray_type(Idstring("mover")) then
        return false
    end
    if body:has_ray_type(Idstring("widget")) then
        return false
    end
    return true
end

function me:cursor_pos()
    local x, y = managers.mouse_pointer._mouse:position()
    return Vector3(x / self._screen_borders.x * 2 - 1, y / self._screen_borders.y * 2 - 1, 0)
end

function me:select_unit_by_raycast(slot, clbk)
    local rays = World:raycast_all("ray", self:get_cursor_look_point(0), self:get_cursor_look_point(200000), "ray_type", "body editor walk", "slot_mask", slot)
    if #rays > 0 then
        for _, r in pairs(rays) do
            if clbk(r.unit) then 
                return r
            end
        end
    else
        return false
    end
end

--Update functions
function me:paused_update(t, dt) self:update(t, dt) end
function me:update(t, dt)
    if self:enabled() then
        for _, manager in pairs(self.managers) do
            if manager.update then
                manager:update(t, dt)
            end
        end
        self._current_pos = managers.editor:current_position() or self._current_pos
        self:update_camera(t, dt)
        self:update_widgets(t, dt)
        self:draw_marker(t, dt)
        self:_tick_generate_dome_occlusion(t, dt)
    end
end

function me:current_position()
    local current_pos, current_rot
    local p1 = self:get_cursor_look_point(0)
    if true then
        local p2 = self:get_cursor_look_point(100)
        if p1.z - p2.z ~= 0 then
            local t = (p1.z - 0) / (p1.z - p2.z)
            local p = p1 + (p2 - p1) * t
            if t < 1000 and t > -1000 then
                local x = math.round(p.x / self:grid_size()) * self:grid_size()
                local y = math.round(p.y / self:grid_size()) * self:grid_size()
                local z = math.round(p.z / self:grid_size()) * self:grid_size()
                current_pos = Vector3(x, y, z)
            end
        end
    end
    self._current_pos = current_pos or self._current_pos
    return current_pos, current_rot
end

function MapEditor:draw_marker(t, dt)
    local spawn_pos
    local rays = World:raycast_all(self:get_cursor_look_point(0), self:get_cursor_look_point(10000), nil, self._editor_all)
    for _, ray in pairs(rays) do
        if ray and ray.unit ~= self.managers.spwsel._dummy_spawn_unit then
            spawn_pos = ray.position
            break
        end
    end
    self._spawn_position = spawn_pos or self._current_pos
end

function me:update_positions()
    for _, manager in pairs(self.managers) do
        if manager.update_positions then
            manager:update_positions()
        end
    end
end

function me:update_widgets(t, dt)
    if not self._closed and alive(self:widget_unit()) then
        local widget_pos  = self:world_to_screen(self:widget_unit():position())
        if widget_pos.z > 50 then
            widget_pos = widget_pos:with_z(0)
            local widget_screen_pos = widget_pos
            widget_pos = self:screen_to_world(widget_pos, 1000)
            local widget_rot = self:widget_rot()
            if self._using_move_widget then
                if self._move_widget:enabled() then
                    local result_pos = self._move_widget:calculate(self:widget_unit(), widget_rot, widget_pos, widget_screen_pos)
                    self:set_unit_positions(result_pos)
                    self:update_positions()
                end
            end
            if self._using_rotate_widget then
                if self._rotate_widget:enabled() then
                    local result_rot = self._rotate_widget:calculate(self:widget_unit(), widget_rot, widget_pos, widget_screen_pos)
                    self:set_unit_rotations(result_rot)
                    self:update_positions()
                end
            end
            if self._move_widget:enabled() then
                BeardLibEditor.Utils:SetPosition(self._move_widget._widget, widget_pos, widget_rot)
                self._move_widget:update(t, dt)
            end
            if self._rotate_widget:enabled() then
                BeardLibEditor.Utils:SetPosition(self._rotate_widget._widget, widget_pos, widget_rot)
                self._rotate_widget:update(t, dt)
            end
        end
    end
end

function me:update_camera(t, dt)
    if self._menu:Focused() or not shift() then
        managers.mouse_pointer._mouse:show()
        self._mouse_pos_x, self._mouse_pos_y = managers.mouse_pointer._mouse:world_position()
        return
    end
    local move_speed, turn_speed, pitch_min, pitch_max = 1000, 1, -80, 80
    local axis_move = self._con:get_input_axis("freeflight_axis_move")
    local axis_look = self._con:get_input_axis("freeflight_axis_look")
    local btn_move_up = self._con:get_input_float("freeflight_move_up")
    local btn_move_down = self._con:get_input_float("freeflight_move_down")
    local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
    move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
    local move_delta = move_dir * BeardLibEditor.Options:GetValue("Map/CameraSpeed") * move_speed * dt
    local pos_new = self._camera_pos + move_delta
    local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * 5 * turn_speed
    local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * 5 * turn_speed, pitch_min, pitch_max)
    local rot_new = Rotation(yaw_new, pitch_new, 0)
    managers.mouse_pointer._mouse:hide()
    managers.mouse_pointer:set_mouse_world_position(self._mouse_pos_x, self._mouse_pos_y)
    self:set_camera(pos_new, rot_new)
end

--Empty/Unused functions
function me:register_message()end
function me:set_value_info_pos() end
function me:set_value_info() end



--Dome occlusion stuff(Currently generates incorrectly)--
function me:_init_post_effects()
    self._post_effects = {
        POSTFX_bloom = {
            on = function()
                self._vp:vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), Idstring("default"))
                self._vp:vp():set_post_processor_effect("World", Idstring("bloom_combine_post_processor"), Idstring("bloom_combine"))
                self._vp:force_apply_feeders()
            end,
            off = function()
                self._vp:vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), Idstring("empty"))
                self._vp:vp():set_post_processor_effect("World", Idstring("bloom_combine_post_processor"), Idstring("bloom_combine_empty"))
            end,
            enable = false
        },
        POSTFX_ssao = {
            on = function()
                managers.environment_controller:set_ao_setting("ssao_low", self._vp:vp())
            end,
            off = function()
                managers.environment_controller:set_ao_setting("off", self._vp:vp())
            end,
            enable = false
        },
        POSTFX_aa = {
            on = function()
                managers.environment_controller:set_aa_setting("smaa_x1", self._vp:vp())
            end,
            off = function()
                managers.environment_controller:set_aa_setting("off", self._vp:vp())
            end,
            enable = false
        }
    }
    self:disable_all_post_effects()
end

function me:disable_all_post_effects(no_keep_state)
    for id, pe in pairs(self._post_effects) do
        pe.off()
        if not no_keep_state then
            pe.enable = false
        end
    end
end

function me:enable_all_post_effects()
    for id, pe in pairs(self._post_effects) do
        pe.on()
        pe.enable = true
    end
end

function me:update_post_effects()
    for id, pe in pairs(self._post_effects) do
        if pe.enable then
            pe.on()
        else
            pe.off()
        end
        if self._post_processor_effects_menu then
            self._post_processor_effects_menu:set_checked(id, pe.enable)
        end
    end
end

function me:init_create_dome_occlusion(shape, res)
    print("CoreEditor:init_create_dome_occlusion()")
    managers.editor:disable_all_post_effects(true)
    self._vp:vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("render_dome_occ"))
    self._aa_setting = managers.environment_controller:get_aa_setting()
    managers.environment_controller:set_aa_setting("AA_off")
    local saved_environment = managers.viewport:default_environment()
    local params = {
        res = res, 
        shape = shape,
        saved_environment = saved_environment
    }
    self:_create_dome_occlusion(params)
end

local leveltools_ids = Idstring("leveltools")
function me:on_hide_helper_units(data)
    local cache = {}
    for _, unit in ipairs(World:find_units_quick("all")) do
        if unit:unit_data() then
            local u_key = unit:name():key()
            if cache[u_key] then
                if not cache[u_key].skip then
                    unit:set_visible(cache[u_key].vis_state)
                end
            else
                local vis_state, affected
                if unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor or unit:has_material_assigned(leveltools_ids) then
                    vis_state = data.vis or data.skip_lights or BeardLibEditor.Utils:HasEditableLights(unit)
                    affected = true
                    unit:set_visible(vis_state)
                end
                cache[u_key] = {
                    vis_state = vis_state,
                    skip = not affected
                }
            end
        end
    end
    cache = nil
end

function me:_create_dome_occlusion(params)
    self._dome_occlusion_params = params
    assert(self._vp:push_ref_fov(500))
    self._vp:set_width_mul_enabled(false)
    self._old_res = RenderSettings.resolution
    self._was_fullscreen = managers.viewport:is_fullscreen()
    local res = Vector3(self._dome_occlusion_params.res, self._dome_occlusion_params.res, 30)
    managers.viewport:set_fullscreen(false)
    managers.viewport:set_resolution(res)
    managers.viewport:set_aspect_ratio(res.x / res.y)
    self._saved_camera = {}
    self._saved_camera.aspect_ratio = self:camera():aspect_ratio()
    self._saved_camera.pos = self:camera():position()
    self._saved_camera.rot = self:camera():rotation()
    self._saved_camera.fov = self:camera_fov()
    self._saved_camera.near_range = self:camera():near_range()
    self._saved_camera.far_range = self:camera():far_range()
    self:camera():set_aspect_ratio(1)
    self:camera():set_width_multiplier(1)
    self._menu:disable()
    self._saved_show_center = self._show_center
    self._show_center = false
    self._saved_hidden_object = {}
    self._saved_hidden_units = {}
    self:on_hide_helper_units({vis = false})
    for _, unit in ipairs(World:find_units_quick("all")) do
        if unit:has_material_assigned(Idstring("leveltools")) then
            unit:set_visible(true)
            for _, obj in ipairs(unit:get_objects("*")) do
            --    local match = string.find(obj:name(), "s_", 1, true)
             --   if not match or match ~= 1 then
             --       obj:set_visibility(false)
               --     table.insert(self._saved_hidden_object, obj)
           --     end
            end
        elseif unit:unit_data() and unit:unit_data().hide_on_projection_light then
            unit:set_visible(false)
            table.insert(self._saved_hidden_units, unit)
        end
    end
    local shape = self._dome_occlusion_params.shape
    local corner = shape:position()
    local w = shape:depth()
    local d = shape:width()
    local h = shape:height()
    local x = corner.x + w / 2
    local y = corner.y - d / 2
    local fov = 4
    local far_range = math.max(w, d) / 2 / math.tan(fov / 2)
    local z = corner.z + far_range
    self:set_camera_far_range(far_range + 10000)
    self:set_camera(Vector3(x, y, z), Rotation(0, -90, 0))
    self:set_camera_fov(fov)
    local deferred_processor = self._vp:vp():get_post_processor_effect("World", Idstring("depth_projection"))
    if not deferred_processor then
        self:dome_occlusion_done()
        return
    end
    local post_dome_occ = deferred_processor:modifier(Idstring("post_dome_occ"))
    self._dome_occ_corner = corner
    self._dome_occ_size = Vector3(w, d, h)
    local dome_occ_feed = post_dome_occ:material()
    if dome_occ_feed then
        dome_occ_feed:set_variable(Idstring("dome_occ_pos"), self._dome_occ_corner)
        dome_occ_feed:set_variable(Idstring("dome_occ_size"), self._dome_occ_size)
    end
    self._lastdir = self.managers.opt:map_world_path()
    if not self._lastdir then
        self:dome_occlusion_done()
        return
    end
    self._dome_occlusion_params.file_name = "dome_occlusion"
    self._dome_occlusion_params.output_path = path
    self._dome_occlusion_params.step = 0
end


function me:_tick_generate_dome_occlusion(t, dt)
    if self._dome_occlusion_params and self._dome_occlusion_params.step then
        self._dome_occlusion_params.step = self._dome_occlusion_params.step + 1
        if self._dome_occlusion_params.step == 100 then
            self:generate_dome_occlusion(self._lastdir)
        elseif self._dome_occlusion_params.step == 200 then
            self:dome_occlusion_done()
        end
    end
end

function me:generate_dome_occlusion(path)
    path = path .. "/cube_lights/"
    FileIO:MakeDir(path)
    local res = Application:screen_resolution()
    local diff = res.x - res.y
    local x1 = diff / 2
    local y1 = 0
    local x2 = res.x - diff / 2
    local y2 = res.y
    Application:screenshot(path .. "dome_occlusion.tga", x1, y1, x2, y2)
end
 
function me:dome_occlusion_done()
    if not self._dome_occlusion_params then
        Application:error("CoreEditor:dome_occlusion_done. Generate has not been started")
        return
    end
    if self._dome_occlusion_params.saved_environment then
        managers.viewport:set_default_environment(self._dome_occlusion_params.saved_environment, nil, nil)
    end
    managers.editor:update_post_effects()
    self._vp:vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("deferred_lighting"))
    self._vp:vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project_empty"))
   -- managers.environment_controller:set_dome_occ_params(self._dome_occ_corner, self._dome_occ_size, managers.database:entry_path(self._dome_occlusion_params.output_path_file))
    --self:set_show_camera_info(true)
   -- self._layers[self._mission_layer_name]:set_enabled(true)
    self._show_center = self._saved_show_center
    self:on_hide_helper_units({vis = true})
    for _, obj in ipairs(self._saved_hidden_object) do
        obj:set_visibility(true)
    end
    for _, unit in ipairs(self._saved_hidden_units) do
        unit:set_visible(true)
    end
    self._menu:enable()
    if self._saved_camera then
        self:set_camera(self._saved_camera.pos, self._saved_camera.rot)
        self:set_camera_fov(self._saved_camera.fov)
        self:camera():set_aspect_ratio(self._saved_camera.aspect_ratio)
        self:camera():set_near_range(self._saved_camera.near_range)
        self:camera():set_far_range(self._saved_camera.far_range)
        self._saved_camera = nil
    end
    managers.viewport:set_resolution(self._old_res)
    managers.viewport:set_aspect_ratio(self._old_res.x / self._old_res.y)
    managers.viewport:set_fullscreen(self._was_fullscreen)
    self._vp:set_width_mul_enabled(true)
    assert(self._vp:pop_ref_fov())
    self._dome_occlusion_params = nil
end
