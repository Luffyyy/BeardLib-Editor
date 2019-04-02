AiLayerEditor = AiLayerEditor or class(LayerEditor)
local AiEditor = AiLayerEditor

function AiEditor:init(parent)
    self:init_basic(parent, "AiLayerEditor")
    self._parent = parent
    self._menu = parent._holder
    MenuUtils:new(self)

    self._brush = Draw:brush()
    self._graph_types = {surface = "surface"}
    self._unit_graph_types = {surface = Idstring("core/units/nav_surface/nav_surface")}
    self._nav_surface_unit = Idstring("core/units/nav_surface/nav_surface")
    self._patrol_point_unit = "core/units/patrol_point/patrol_point"
    self._group_states = {
        "empty",
        "airport",
        "besiege",
        "street",
        "zombie_apocalypse"
    }

    self._ai_settings = {}
    self._created_units = {}

    --self:_init_ai_settings()
    --self:_init_mop_settings()
    self._patrol_path_brush = Draw:brush()
    self._only_draw_selected_patrol_path = false
    self._default_values = {all_visible = true}
end

function AiEditor:is_my_unit(unit)
    if unit == self._patrol_point_unit:id() then
        return true
    end
    return false
end

function AiEditor:loaded_continents()
    AiEditor.super.loaded_continents(self)

    local data = self:data()

    for name, value in pairs(data.ai_settings or {}) do
        self._ai_settings[name] = value
    end

    for _, unit in pairs(World:find_units_quick("all")) do
        if alive(unit) and unit:name() == self._patrol_point_unit:id() then
            table.insert(self._created_units, unit)
        end
    end

    managers.ai_data:load_units(self._created_units or {})

    --self:_update_patrol_paths_list()
    --self:_update_motion_paths_list()
    --self:_update_settings()
end

function AiEditor:save()
    self._parent:data().ai_settings = {
        ai_settings = self._ai_settings,
        ai_data = managers.ai_data:save_data()
    }
end

function AiEditor:reset_selected_units()
    for k, unit in ipairs(clone(self._created_units)) do
        if not alive(unit) then
            table.remove(self._created_units, k)
        end
    end
    self:save()
end

function AiEditor:build_menu()
    self:save()
    self:ClearItems()

    local graphs = self:Group("Graphs")
    self:Button(
        "CalculateAll",
        ClassClbk(
            self,
            "_calc_graphs",
            {
                vis_graph = true,
                build_type = "all"
            }
        ),
        {group = graphs}
    )

    self:Button(
        "CalculateSelected",
        ClassClbk(
            self,
            "_calc_graphs",
            {
                vis_graph = true,
                build_type = "selected"
            }
        ),
        {group = graphs}
    )

    self:Button("ClearAll", ClassClbk(self, "_clear_graphs"), {group = graphs, offset = {6, 6}})
    self:Button("ClearSelected", ClassClbk(self, "_clear_selected_nav_segment"), {group = graphs, offset = {6, 6}})

    local navigation_debug =
        self:Group("NavigationDebug", {group = graphs, text = "Navigation Debug [Toggle what to draw]"})
    local group = self:Menu("Draw", {align_method = "grid", group = navigation_debug})

    self._draw_options = {}
    local w = group.w / 2
    for _, opt in pairs({"quads", "doors", "blockers", "vis_graph", "coarse_graph", "nav_links", "covers"}) do
        self._draw_options[opt] =
            self:Toggle(
            opt,
            ClassClbk(self, "_draw_nav_segments"),
            false,
            {w = w, items_size = 15, offset = 0, group = group}
        )
    end

    local ai_settings = self:Group("AiSettings")
    self:ComboBox(
        "GroupState",
        function(item)
            self:data().ai_settings.group_state = item:SelectedItem()
        end,
        self._group_states,
        table.get_key(self._group_states, self:data().ai_settings.group_state),
        {group = ai_settings}
    )

    self:_build_ai_data()
end

function AiEditor:_build_ai_data()
    local ai_data = self:Group("AiData")
    ai_data:GetToolbar():SqButton(
        "CreateNew",
        ClassClbk(self, "_create_new_patrol_path"),
        {text = "+", help = "Create new patrol path"}
    )

    local patrol_paths = managers.ai_data:all_patrol_paths()
    for name, points in pairs(patrol_paths) do
        local patrol_path = self:Group(name, {group = ai_data, closed = true})
        patrol_path:GetToolbar():SqButton(
            "CreateNewPoint",
            -- send it the name instead of the points tbl to be super safe
            function()
                self._parent:BeginSpawning(self._patrol_point_unit)
                self._selected_path = name
            end,
            {text = "+", help = "Create new patrol point"}
        )

        for i, v in ipairs(points.points) do
            local patrol_point =
                self:Button(
                name .. "_" .. i,
                ClassClbk(self, "_select_patrol_point", v.unit),
                {
                    group = patrol_path,
                    text = string.format("[%d] Unit ID: %d", i, v.unit_id)
                }
            )
        end
    end
end

function AiEditor:build_unit_menu()
    local S = self:GetPart("static")
    S._built_multi = false
    S.super.build_default_menu(S)

    local unit = self:selected_unit()
    if alive(unit) then
        S:build_positions_items(true)
        S:update_positions()
        S:Button("CreatePrefab", ClassClbk(S, "add_selection_to_prefabs"), {group = S:GetItem("QuickButtons")})
        S:SetTitle("Patrol Point Selection")
    end
end

function AiEditor:update_positions()
    self:set_unit_pos()
end

function AiEditor:set_unit_pos(item)
    log('setting unit pos')
    local unit = self:selected_unit()
    local S = self:GetPart("static")
    if unit then
        unit:set_position(S:AxisControlsPosition())
        unit:set_rotation(S:AxisControlsRotation())
        unit:unit_data().position = unit:position()
        unit:unit_data().rotation = unit:rotation()
    end
    S:set_unit_data()
    self:save()
end

function AiEditor:unit_spawned(unit)
    self:_add_patrol_point(unit)
end

function AiEditor:unit_deleted(unit)
    for _, u in ipairs(self._created_units) do
        if u:name() == self._nav_surface_unit and u ~= unit then
            u:ai_editor_data().visibilty_exlude_filter[unit:unit_data().unit_id] = nil
            u:ai_editor_data().visibilty_include_filter[unit:unit_data().unit_id] = nil
        end
    end

    if unit:name() == self._nav_surface_unit then
        managers.navigation:delete_nav_segment(unit:unit_data().unit_id)
    elseif unit:name() == self._patrol_point_unit:id() then
        managers.ai_data:delete_point_by_unit(unit)
    end

    table.delete(self._created_units, unit)
end

function AiEditor:update(t, dt)
    self:_draw(t, dt)
end

function AiEditor:_draw(t, dt)
    for _, unit in ipairs(self._created_units) do
        local selected = unit == self._selected_unit

        if unit:name() == self._nav_surface_unit then
            local a = selected and 0.75 or 0.5
            local r = selected and 0 or 1
            local g = selected and 1 or 1
            local b = selected and 0 or 1

            self._brush:set_color(Color(a, r, g, b))
            self:_draw_surface(unit, t, dt, a, r, g, b)

            if selected then
                for id, _ in pairs(unit:ai_editor_data().visibilty_exlude_filter) do
                    for _, to_unit in ipairs(self._created_units) do
                        if to_unit:unit_data().unit_id == id then
                            Application:draw_link(
                                {
                                    g = 0,
                                    b = 0,
                                    r = 1,
                                    from_unit = unit,
                                    to_unit = to_unit
                                }
                            )
                        end
                    end
                end

                for id, _ in pairs(unit:ai_editor_data().visibilty_include_filter) do
                    for _, to_unit in ipairs(self._created_units) do
                        if to_unit:unit_data().unit_id == id then
                            Application:draw_link(
                                {
                                    g = 1,
                                    b = 0,
                                    r = 0,
                                    from_unit = unit,
                                    to_unit = to_unit
                                }
                            )
                        end
                    end
                end
            end
        elseif unit:name() == self._patrol_point_unit then
        -- Nothing
        end
    end

    self:_draw_patrol_paths(t, dt)
end

function AiEditor:_draw_surface(unit, t, dt, a, r, g, b)
    local rot1 = Rotation(math.sin(t * 10) * 180, 0, 0)
    local rot2 = rot1 * Rotation(90, 0, 0)
    local pos1 = unit:position() - rot1:y() * 100
    local pos2 = unit:position() - rot2:y() * 100

    Application:draw_line(pos1, pos1 + rot1:y() * 200, r, g, b)
    Application:draw_line(pos2, pos2 + rot2:y() * 200, r, g, b)
    self._brush:quad(pos1, pos2, pos1 + rot1:y() * 200, pos2 + rot2:y() * 200)
end

function AiEditor:_draw_patrol_paths(t, dt)
    if self._only_draw_selected_patrol_path and self._current_patrol_path then
        self:_draw_patrol_path(
            self._current_patrol_path,
            managers.ai_data:all_patrol_paths()[self._current_patrol_path],
            t,
            dt
        )
    else
        for name, path in pairs(managers.ai_data:all_patrol_paths()) do
            self:_draw_patrol_path(name, path, t, dt)
        end
    end
end

function AiEditor:_draw_patrol_path(name, path, t, dt)
    local selected_path = name == self._current_patrol_path

    if #path.points > 0 then
        for i, point in ipairs(path.points) do
            local to_unit = nil
            to_unit = i == #path.points and path.points[1].unit or path.points[i + 1].unit

            self._patrol_path_brush:set_color(Color.white:with_alpha(selected_path and 1 or 0.25))

            Application:draw_link(
                {
                    g = 1,
                    thick = true,
                    b = 1,
                    r = 1,
                    height_offset = 0,
                    from_unit = point.unit,
                    to_unit = to_unit,
                    circle_multiplier = selected_path and 0.5 or 0.25
                }
            )
            self:_draw_patrol_point(point.unit, i == 1, i == #path.points, selected_path, t, dt)

            if point.unit == self._selected_unit then
                local dir = to_unit:position() - point.unit:position()
                self._mid_pos = point.unit:position() + dir / 2

                Application:draw_sphere(self._mid_pos, 10, 0, 0, 1)
            end
        end
    end
end

function AiEditor:_draw_patrol_point(unit, first, last, selected_path, t, dt)
    local selected = unit == self._selected_unit
    local r = selected and 0 or first and 0.5 or last and 1 or 0.65
    local g = selected and 1 or first and 1 or last and 0.5 or 0.65
    local b = selected and 0 or first and 0.5 or last and 0.5 or 0.65

    self._patrol_path_brush:set_color(Color(r, g, b):with_alpha(selected_path and 1 or 0.25))
    self._patrol_path_brush:sphere(unit:position(), selected_path and (first and 20 or 20) or first and 10 or 10)
end

function AiEditor:draw_patrol_path_externaly(name)
    self:_draw_patrol_path(name, managers.ai_data:patrol_path(name))
end

function AiEditor:_calc_graphs(params)
    -- TODO
end

function AiEditor:_clear_graphs()
    -- TODO
end

function AiEditor:_clear_selected_nav_segment()
    -- TODO
end

function AiEditor:_draw_nav_segments(item)
    if managers.navigation then
        managers.navigation:set_debug_draw_state(self._draw_options)
    end
end

function AiEditor:_create_new_patrol_path()
    BLE.InputDialog:Show(
        {
            title = "Patrol Path Name",
            text = "none",
            callback = function(name)
                if not name or name == "" then
                    return
                end

                if not managers.ai_data:add_patrol_path(name) then
                    self:_create_new_patrol_path()
                else
                    self:build_menu()
                end
            end
        }
    )
end

function AiEditor:_select_patrol_point(unit)
    managers.editor:select_unit(unit)
end

--[[function AiEditor:do_spawn_unit(unit_path, ud)
    local unit = World:spawn_unit(unit_path:id(), ud.position or Vector3(), ud.rotation or Rotation())
    table.merge(unit:unit_data(), ud)
    ud = unit:unit_data()
    ud.name = unit_path
    ud.unit_id = managers.worlddefinition:GetNewUnitID(managers.editor._current_continent, "ai")
    ud.position = unit:position()
    ud.rotation = unit:rotation()

    if alive(unit) and unit:name() == self._patrol_point_unit:id() then
        managers.ai_data:add_patrol_point(self._selected_path, unit)
    end

    table.insert(self._created_units, unit)

    self:build_menu()
end]]

function AiEditor:_add_patrol_point(unit)
    if alive(unit) and unit:name() == self._patrol_point_unit:id() then
        managers.ai_data:add_patrol_point(self._selected_path, unit)
    end

    -- don't care if it is alive i guess
    table.insert(self._created_units, unit)

    self:build_menu()
end

function AiEditor:data()
    return self._parent:data().ai_settings
end
