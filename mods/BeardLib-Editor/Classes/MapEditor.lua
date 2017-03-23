MapEditor = MapEditor or class()
core:import("CoreEditorWidgets")
local me = MapEditor
function me:init()
    managers.editor = self
    if not PackageManager:loaded("core/packages/editor") then
        PackageManager:load("core/packages/editor")
    end
    self._fbd = FileBrowserDialog:new()
    self._listdia = ListDialog:new()
    self._select_list = SelectListDialog:new()
    self._current_continent = "world"
    self._grid_size = 1
    self._current_pos = Vector3(0, 0, 0)
    self._snap_rotation = 90
    self._screen_borders = {x = 1280, y = 720}
	self._camera_object = World:create_camera()
	self._camera_object:set_far_range(250000)
	self._camera_object:set_fov(75)
	self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()
    self._editor_all = World:make_slot_mask(1, 10, 11, 15, 19, 29, 34, 35, 36, 37, 38, 39)
	self._con = managers.menu._controller
    self._move_widget = CoreEditorWidgets.MoveWidget:new(self)
    self._rotate_widget = CoreEditorWidgets.RotationWidget:new(self)
    self:check_has_fix()
    self._use_move_widget = self._has_fix
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
    for k, v in pairs({mission = MissionEditor, static = StaticEditor, opt = GameOptions, spwsel = SpawnSelect, wdata = WorldDataEditor, console = EditorConsole}) do
        self.managers[k] = v:new(self, menu)
    end
    self.managers.menu = UpperMenu:new(self, menu)
    self.managers.static:Switch()
    menu.mouse_move = callback(self.managers.static, self.managers.static, "mouse_moved")
end

--functions

function me:check_has_fix()
    local unit = World:spawn_unit(Idstring("core/units/move_widget/move_widget"), Vector3())
    self._has_fix = World:raycast("ray", unit:position(), unit:position():with_z(100), "ray_type", "widget", "target_unit", unit)
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
        if unit:unit_data() and unit:unit_data().contiennt then
            managers.worlddefinition:delete_unit(unit)
        end
        World:delete_unit(unit)
    end
end

function me:SpawnUnit(unit_path, old_unit, add)
    local cam = managers.viewport:get_current_camera()
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
        self._con:enable()
        self._menu:enable()
        managers.hud:set_disabled()
    else
        self._con:disable()
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
            self:set_unit_position(unit, reference:position())
            BeardLibEditor.Utils:SetPosition(unit, unit:position(), rot * unit:unit_data().local_rot)
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
    for _, unit in pairs(managers.worlddefinition._all_units) do
        if unit:name() == self.managers.static._nav_surface then
            table.insert(self.managers.static._nav_surfaces, unit)
        end
    end
    for _, manager in pairs(self.managers) do
        if manager.loaded_continents then
            manager:loaded_continents(self._continents, self._current_continent)
        end
    end
end

--Short functions
function me:set_unit_position(unit, pos) BeardLibEditor.Utils:SetPosition(unit, pos + unit:unit_data().local_pos, unit:rotation()) end
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
function MapEditor:snap_rotation() return ctrl() and 1 or self._snap_rotation end
function me:get_cursor_look_point(dist) return self._camera_object:screen_to_world(self:cursor_pos() + Vector3(0, 0, dist)) end
function me:world_to_screen(pos) return self._camera_object:world_to_screen(pos) end
function me:screen_to_world(pos, dist) return self._camera_object:screen_to_world(pos + Vector3(0, 0, dist)) end

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
                    self.managers.static:update_positions()
                    self.managers.wdata:update_menu()
                end
            end
            if self._using_rotate_widget then
                if self._rotate_widget:enabled() then
                    local result_rot = self._rotate_widget:calculate(self:widget_unit(), widget_rot, widget_pos, widget_screen_pos)
                    self:set_unit_rotations(result_rot)
                    self.managers.static:update_positions()
                    self.managers.wdata:update_menu()
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
    local rot_new
    if Input:keyboard():down(Idstring("left shift")) then
        rot_new = Rotation(yaw_new, pitch_new, 0)
        managers.mouse_pointer._mouse:hide()
        managers.mouse_pointer:set_mouse_world_position(self._mouse_pos_x, self._mouse_pos_y)
    end
    if not CoreApp.arg_supplied("-vpslave") then
        self:set_camera(pos_new, rot_new)
    end
end

--Empty/Unused functions
function me:register_message()end
function me:set_value_info_pos() end
function me:set_value_info() end