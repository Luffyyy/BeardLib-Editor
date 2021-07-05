AiLayerEditor = AiLayerEditor or class(LayerEditor)
local AiEditor = AiLayerEditor

local EU = BLE.Utils
local tx = "textures/editor_icons_df"

function AiEditor:init(parent)
    AiEditor.super.init(self, parent, "AiLayerEditor")

    self._draw_helpers = {
        { name = "quads", needs_unit = true, dont_disable = true },
        { name = "doors" },
        { name = "blockers" },
        { name = "vis_graph", needs_unit = true },
        { name = "coarse_graph" },
        { name = "nav_links", needs_unit = true },
        { name = "covers" }
    }

    self._brush = Draw:brush()
    self._graph_types = { surface = "surface" }
    self._unit_graph_types = { surface = Idstring("core/units/nav_surface/nav_surface") }
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
    self._units = {}
    self._disabled_units = {}

    --self:_init_ai_settings()
    --self:_init_mop_settings()
    self._patrol_path_brush = Draw:brush()
    self._only_draw_selected_patrol_path = false
    self._default_values = { all_visible = true }
end

function AiEditor:is_my_unit(unit)
    return unit == self._patrol_point_unit:id() or unit == self._nav_surface_unit
end

function AiEditor:_current_patrol_units(path_name)
    local t = {}
    local path = managers.ai_data:patrol_path(path_name)

    for _, point in ipairs(path.points) do
        table.insert(t, point.unit)
    end

    return t
end

function AiEditor:loaded_continents()
    AiEditor.super.loaded_continents(self)

    local data = self:data()

    for name, value in pairs(data.ai_settings or {}) do
        self._ai_settings[name] = value
    end

    for _, unit in pairs(World:find_units_quick("all")) do
        if alive(unit) and (unit:name() == self._patrol_point_unit:id() or unit:name() == self._nav_surface_unit) then
            table.insert(self._units, unit)
        end
    end

    managers.ai_data:load_units(self._units or {})

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
    for k, unit in ipairs(clone(self._units)) do
        if not alive(unit) then
            table.remove(self._units, k)
        end
    end

    self:update_draw_data(nil)
    self:save()
end

function AiEditor:build_menu()
    self:save()
    self._holder:ClearItems()
    local graphs = self._holder:group("Graphs")
    local spawn = self:GetPart("spawn")
    graphs:button("SpawnNavSurface", ClassClbk(spawn, "begin_spawning", "core/units/nav_surface/nav_surface"))
    graphs:button("BuildNavigationData", ClassClbk(self, "build_nav_segments"), { enabled = self._parent._parent._has_fix })
    graphs:button("SaveNavigationData", ClassClbk(self:part("opt"), "save_nav_data", false), { enabled = self._parent._parent._has_fix })
    --[[
        graphs:button(
            "CalculateAll",
            ClassClbk(
                self,
                "_calc_graphs",
                {
                    vis_graph = true,
                    build_type = "all"
                }
            )
        )

        graphs:button(
            "CalculateSelected",
            ClassClbk(
                self,
                "_calc_graphs",
                {
                    vis_graph = true,
                    build_type = "selected"
                }
            )
        )
    ]]
    graphs:button("ClearAll", ClassClbk(self, "_clear_graphs"))
    graphs:button("ClearSelected", ClassClbk(self, "_clear_selected_nav_segment"))

    local navigation_debug = graphs:group("NavigationDebug", { text = "Navigation Debugging [Toggle what to draw]" })
    local group = navigation_debug:pan("Draw", {align_method = "grid"})

    self:_build_draw_data(group)

    local ai_settings = self._holder:group("AISettings", {text = "AI Settings"})
    ai_settings:combobox("GroupState",
        function(item)
            self:data().ai_settings.group_state = item:SelectedItem()
        end,
        self._group_states,
        table.get_key(self._group_states, self:data().ai_settings.group_state))

    local ai_data = self._holder:group("AIData", {text = "AI Data"})
    ai_data:tickbox("Draw", ClassClbk(self, "set_draw_patrol_paths"), self:Val("DrawPatrolPaths"))
    ai_data:GetToolbar():tb_imgbtn("CreateNew",
        ClassClbk(self, "_create_new_patrol_path"),
        tx, EU.EditorIcons["plus"], {help = "Create new patrol path"}
    )

    self:_build_ai_data(ai_data)

    local other = self._holder:group("Other")
    other:button("SpawnCoverPoint", ClassClbk(self:part("spawn"), "begin_spawning", "units/dev_tools/level_tools/ai_coverpoint"))
    other:button("SaveCoverData", ClassClbk(self:part("opt"), "save_cover_data", false))
end

function AiEditor:set_draw_patrol_paths(item)
    self:set_value("DrawPatrolPaths", item:Value())
end

function AiEditor:_build_draw_data(group)
    self._draw_options = {}
    local w = group.w / 2

    local unit = self:selected_unit()
    for _, data in pairs(self._draw_helpers) do
        local needs_unit_text = ""
        local should_enable = true
        if data.needs_unit then
            if alive(unit) and unit:name() == self._nav_surface_unit then
                needs_unit_text = ("(seg id: %i)"):format(unit:unit_data().unit_id)
                should_enable = true
            else
                needs_unit_text = "(no seg)"
                should_enable = false or (data.dont_disable and true or false)
            end
        end

        self._draw_options[data.name] = group:tickbox(
            data.name .. (needs_unit_text),
            ClassClbk(self, "_draw_nav_segments"),
            false,
            { w = w, items_size = 15, offset = 0, enabled = should_enable }
        )
    end
end

function AiEditor:_build_ai_data(ai_data)
    local patrol_paths = managers.ai_data:all_patrol_paths()
    local has_items = false
    for name, points in pairs(patrol_paths) do
        has_items = true
        local patrol_path = ai_data:group(name, {label = "patrol_path"})
        patrol_path:GetToolbar():tb_imgbtn("DeletePath", ClassClbk(self, "_delete_patrol_path", name),
            tx, EU.EditorIcons["cross"], { highlight_color = Color.red }
        )

        patrol_path:GetToolbar():tb_imgbtn("CreateNewPoint", function()
            self._parent:BeginSpawning(self._patrol_point_unit)
            self._selected_path = name
        end, tx, EU.EditorIcons["plus"], {help = "Create new patrol point"})

        for i, v in ipairs(points.points) do
            local patrol_point = patrol_path:button(name .. "_" .. i, ClassClbk(self, "_select_patrol_point", v.unit), {
                text = string.format("[%d] Unit ID: %d", i, v.unit_id)
            })
            patrol_point:tb_imgbtn("DeletePoint", ClassClbk(self, "_delete_patrol_point", v.unit),
                tx, EU.EditorIcons["cross"], { highlight_color = Color.red }
            )
        end
    end
    if not has_items then
        ai_data:lbl("No paths exist", {label = "patrol_path"})
    end
end

function AiEditor:build_unit_menu()
    local S = self:GetPart("static")
    S._built_multi = false
    S:clear_menu()

    local unit = self:selected_unit()
    if alive(unit) then
        local name = unit:unit_data().name
        local main = S:group("Main", { align_method = "grid", visible = name ~= nil })

        main:GetToolbar():lbl("ID", {
            text = "ID " .. unit:unit_data().unit_id,
            size_by_text = true,
        })
        main:textbox("Name", ClassClbk(self, "set_unit_data"), unit:unit_data().name_id, {
            help = "the name of the unit",
            control_slice = 0.8 }
        )

        S:build_positions_items(true)
        S:update_positions()

        if unit:name() == self._patrol_point_unit:id() then
            S:SetTitle("Patrol Point Selection")
        elseif unit:name() == self._nav_surface_unit then
            S:SetTitle("Navigation Segment Selection")

            local ai = S:group("AIEditorData")
            ai:textbox("LocationId", ClassClbk(self, "set_unit_data"),
                unit:ai_editor_data().location_id or "location_unknown", {
                    help = "Select a location id to be associated with this navigation point"
                }
            )
            ai:divider("LocOfLocation", {
                text = "Text: " .. managers.localization:text(self:selected_unit():ai_editor_data().location_id or "location_unknown")
            })
            ai:numberbox("SuspicionMultiplier", ClassClbk(self, "set_unit_data"),
                unit:ai_editor_data().suspicion_multiplier, {
                    min = 1,
                    floats = 1,
                    help = "multiplier applied to suspicion buildup rate"
                }
            )
            ai:numberbox("DetectionMultiplier", ClassClbk(self, "set_unit_data"),
                unit:ai_editor_data().detection_multiplier, {
                    min = 0.01,
                    help = "multiplier applied to AI detection speed. min is 0.01"
                }
            )
            S:build_links(unit:unit_data().unit_id)
        end
    end
end

function AiEditor:update_positions() self:set_unit_pos() end

function AiEditor:set_selected_unit()
    if self:active() then
        self:update_draw_data(self:selected_unit())
    end
end

function AiEditor:set_unit_pos()
    local S = self:GetPart("static")
    local unit = self:selected_unit()
    if unit then
        unit:set_position(S:GetItemValue("Position"))
        unit:set_rotation(S:GetItemValue("Rotation"))
        unit:unit_data().position = unit:position()
        unit:unit_data().rotation = unit:rotation()
    end

    self:save()
end

function AiEditor:set_unit_data()
    local S = self:GetPart("static")
    local unit = self:selected_unit()

    if alive(unit) then
        S:GetItem("ID"):SetText("ID " .. unit:unit_data().unit_id)
        managers.worlddefinition:set_name_id(unit, S:GetItemValue("Name"))

        if unit:name() == self._nav_surface_unit then
            unit:ai_editor_data().location_id = S:GetItemValue("LocationId")

            S:GetItem("LocOfLocation"):SetText("Text = " .. managers.localization:text(
                self:selected_unit():ai_editor_data().location_id or "location_unknown"
            ))
            managers.navigation:set_location_ID(
                unit:unit_data().unit_id,
                S:GetItemValue("LocationId")
            )

            unit:ai_editor_data().suspicion_multiplier = S:GetItemValue("SuspicionMultiplier")
            managers.navigation:set_suspicion_multiplier(
                unit:unit_data().unit_id,
                S:GetItemValue("SuspicionMultiplier")
            )

            unit:ai_editor_data().detection_multiplier = S:GetItemValue("DetectionMultiplier")
            managers.navigation:set_detection_multiplier(
                unit:unit_data().unit_id,
                S:GetItemValue("DetectionMultiplier")
            )
        end

    end

    S:set_unit_data()
    self:save()
end

function AiEditor:unit_spawned(unit)
    if unit:name() == self._patrol_point_unit:id() then
        self:_add_patrol_point(unit)
    end
end

function AiEditor:unit_deleted(unit)
    for _, u in ipairs(self._units) do
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

    table.delete(self._units, unit)
    self:save()
end

function AiEditor:update_draw_data(unit)
    if not alive(unit) or unit:name() == self._nav_surface_unit then
        managers.navigation:set_selected_segment(unit)
        managers.navigation:set_debug_draw_state(self._draw_options)
    end

    if not self._draw_options then
        return
    end

    for _, data in pairs(self._draw_helpers) do
        local needs_unit_text = ""
        local should_enable = data.dont_disable
        if data.needs_unit then
            if alive(unit) and unit:name() == self._nav_surface_unit then
                needs_unit_text = ("(seg id: %i)"):format(unit:unit_data().unit_id)
                should_enable = true
            else
                needs_unit_text = "(no seg)"
            end

            local text = data.name .. needs_unit_text
            local opt = self._draw_options[data.name]
            if text ~= opt:Text() then
                opt:SetText(text)
            end
            opt:SetEnabled(should_enable)
        end
    end
end

function AiEditor:update_ai_data()
    local ai_data = self._holder:GetItem("AIData")
    ai_data:ClearItems("patrol_path")

    self:_build_ai_data(ai_data)
end

function AiEditor:update(t, dt)
    if self:Val("DrawPatrolPaths") then
        self:_draw(t, dt)
    end
end

function AiEditor:_draw(t, dt)
    for _, unit in ipairs(self._units) do
        if alive(unit) then
            local selected = unit == self._selected_unit

            if unit:name() == self._nav_surface_unit then
                Application:draw(unit, 0, 0.8, 1)

                local a = selected and 0.75 or 0.5
                local r = selected and 0 or 1
                local g = selected and 1 or 1
                local b = selected and 0 or 1

                self._brush:set_color(Color(a, r, g, b))
                self:_draw_surface(unit, t, dt, a, r, g, b)

                if selected then
                    for id, _ in pairs(unit:ai_editor_data().visibilty_exlude_filter) do
                        for _, to_unit in ipairs(self._units) do
                            if to_unit:unit_data().unit_id == id then
                                Application:draw_link({
                                    g = 0,
                                    b = 0,
                                    r = 1,
                                    from_unit = unit,
                                    to_unit = to_unit
                                })
                            end
                        end
                    end

                    for id, _ in pairs(unit:ai_editor_data().visibilty_include_filter) do
                        for _, to_unit in ipairs(self._units) do
                            if to_unit:unit_data().unit_id == id then
                                Application:draw_link({
                                    g = 1,
                                    b = 0,
                                    r = 0,
                                    from_unit = unit,
                                    to_unit = to_unit
                                })
                            end
                        end
                    end
                end
            elseif unit:name() == self._patrol_point_unit then
                -- Nothing
            end
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
        self:_draw_patrol_path(self._current_patrol_path,
            managers.ai_data:all_patrol_paths()[self._current_patrol_path],
            t,
            dt)
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

            Application:draw_link({
                g = 1,
                thick = true,
                b = 1,
                r = 1,
                height_offset = 0,
                from_unit = point.unit,
                to_unit = to_unit,
                circle_multiplier = selected_path and 0.5 or 0.25
            })
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
    for _, unit in pairs(World:find_units_quick("all")) do
        if unit:name() == self._nav_surface_unit then
            managers.editor:DeleteUnit(unit)
        end
    end
    self:GetPart("select"):reload_menu("unit")
end

function AiEditor:_clear_selected_nav_segment()
    for _, unit in pairs(self:selected_units()) do
        if unit:name() == self._nav_surface_unit then
            managers.editor:DeleteUnit(unit)
        end
    end
    self:GetPart("select"):reload_menu("unit")
end

function AiEditor:_draw_nav_segments(item)
    if managers.navigation then
        managers.navigation:set_debug_draw_state(self._draw_options)
    end
end

function AiEditor:_create_new_patrol_path()
    BLE.InputDialog:Show({
        title = "Patrol Path Name",
        text = "none",
        callback = function(name)
            if not name or name == "" then
                return
            end

            if not managers.ai_data:add_patrol_path(name) then
                self:_create_new_patrol_path()
            else
                self:update_ai_data()
            end
        end
    })
end

function AiEditor:_delete_patrol_path(path_name)
    EU:YesNoQuestion("Do you want to delete this patrol path?", function()
        local to_delete = self:_current_patrol_units(path_name)
        for _, unit in ipairs(to_delete) do
            managers.editor:DeleteUnit(unit)
        end
        self:GetPart("select"):reload_menu("unit")

        managers.ai_data:remove_patrol_path(path_name)
        self:update_ai_data()

        self._current_patrol_path = nil

        self:save()
    end)
end

function AiEditor:_delete_patrol_point(unit)
    EU:YesNoQuestion("Do you want to delete this patrol point?", function()
        managers.editor:DeleteUnit(unit, false, true)

        self:update_ai_data()
    end)
end

function AiEditor:_select_patrol_point(unit)
    managers.editor:select_unit(unit)
end

function AiEditor:do_spawn_unit(unit_path, ud)
    local new_unit_id = managers.worlddefinition:GetNewUnitID(ud.continent or managers.editor._current_continent, "ai")

    local shared_data = {
        unit_data = {
            unit_id = ud.unit_id or new_unit_id,
            name = unit_path,
            position = ud.position,
            rotation = ud.rotation or Rotation(0, 0, 0),
            continent = ud.continent or managers.editor._current_continent,
        }
    }

    if Idstring(unit_path) == self._nav_surface_unit then
        shared_data.ai_editor_data = ud.ai_editor_data or {
            visibilty_exlude_filter = {},
            visibilty_include_filter = {},
            location_id = "location_unknown",
            suspicion_mul = 1,
            detection_mul = 1
        }
    end

    local unit = managers.worlddefinition:create_unit(shared_data, Idstring("ai"))

    if alive(unit) and unit:name() == self._patrol_point_unit:id() then
        managers.ai_data:add_patrol_point(self._selected_path, unit)
    end

    table.insert(self._units, unit)

    self:build_menu()

    return unit
end

function AiEditor:_add_patrol_point(unit)
    if alive(unit) and unit:name() == self._patrol_point_unit:id() then
        managers.ai_data:add_patrol_point(self._selected_path, unit)
    end

    -- don't care if it is alive i guess
    table.insert(self._units, unit)
    self:update_ai_data()
end

function AiEditor:data()
    return self._parent:data().ai_settings
end

function AiEditor:build_nav_segments()
    -- Add later the options to the menu
    BLE.Utils:YesNoQuestion("This will save the map, disable the player and AI, build the nav data and reload the game. Proceed?", function()
        self:part("opt"):save()
        local settings = {}
        local nav_surfaces = {}

        local persons = managers.slot:get_mask("persons")

        --first disable the units so the raycast will know.
        for _, unit in pairs(World:find_units_quick("all")) do
            local is_person = unit:in_slot(persons)
            local ud = unit:unit_data()
            if is_person or (ud and ud.disable_on_ai_graph) then
                unit:set_enabled(false)
                table.insert(self._disabled_units, unit)

                if is_person then
                    --Why are they active even though the main unit is disabled? Good question.
                    if unit:brain() then
                        unit:brain()._current_logic.update = nil
                    end

                    for _, extension in pairs(unit:extensions()) do
                        unit:set_extension_update_enabled(extension:id(), false)
                    end
                end
            elseif unit:name() == self._nav_surface_unit then
                table.insert(nav_surfaces, unit)
            end
        end

        local editor_ids = {}
        local duplicate_id_unit
        for _, unit in pairs(nav_surfaces) do
            local ray = World:raycast(unit:position() + Vector3(0, 0, 50), unit:position() - Vector3(0, 0, 150), nil, managers.slot:get_mask("all"))
            if ray and ray.position then
                local editor_id = unit:editor_id()
                if table.contains(editor_ids, editor_id) then
                    duplicate_id_unit = unit
                    break
                end

                table.insert(editor_ids, editor_id)

                table.insert(settings, {
                    position = unit:position(),
                    id = unit:editor_id(),
                    color = Color(),
                    location_id = unit:ai_editor_data().location_id
                })
            end
        end

        if #settings < 1 then
            if #nav_surfaces > 0 then
                BLE.Utils:Notify("Error!", "At least one nav surface has to touch a surface(that is also enabled while generating) for navigation to be built.")
            else
                BLE.Utils:Notify("Error!", "There are no nav surfaces in the map to begin building the navigation data, please spawn one")
                local W = self:part("world")
                W:Switch()
                if W._current_layer ~= "ai" then
                    W:build_menu("ai")
                end
            end

            self:reenable_disabled_units()
            return
        end

        if duplicate_id_unit then
            local unit_id = duplicate_id_unit:unit_data().name_id
            local editor_id = duplicate_id_unit:editor_id()

            local unit_full_name = unit_id .. " [" .. editor_id .. "]"
            BLE.Utils:Notify("Error!", "Found a nav surface unit with a duplicate ID: " .. tostring(unit_full_name) .. "\nPlease delete it before proceeding")
            
            self:reenable_disabled_units()
            return
        end

        managers.navigation:clear()
        managers.navigation:build_nav_segments(settings, ClassClbk(self, "build_visibility_graph"))

    end)
end

function AiEditor:reenable_disabled_units()
    for _, unit in pairs(self._disabled_units) do
        if alive(unit) then
            unit:set_enabled(true)
            if unit:in_slot(managers.slot:get_mask("persons")) then
                for _, extension in pairs(unit:extensions()) do
                    unit:set_extension_update_enabled(extension:id(), true)
                end
            end
        end
    end
    self._disabled_units = {}
end

function AiEditor:build_visibility_graph()
    local all_visible = true
    local exclude, include
    if not all_visible then
        exclude = {}
        include = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                exclude[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_exlude_filter
                include[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_include_filter
            end
        end
    end
    local ray_lenght = 150
    managers.navigation:build_visibility_graph(function()
        managers.groupai:set_state("none")
    end, all_visible, exclude, include, ray_lenght)

    self:part("opt"):save_nav_data()
end

function AiEditor:can_unit_be_selected()
    return self:Val("DrawPatrolPaths")
end