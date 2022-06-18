DebugToolEditor = DebugToolEditor or class(ToolEditor)
local DebugTool = DebugToolEditor
function DebugTool:init(parent)
	DebugTool.super.init(self, parent, "DebugToolEditor")
end

function DebugTool:build_menu()
    self._holder:ClearItems()
    local groups_opt = {align_method = "grid", control_slice = 0.5}
    local icons = BLE.Utils.EditorIcons

    local ai = self._holder:group("AI")
    ai:tickbox("AIEnabled", ClassClbk(self, "set_ai_enabled"), true, {help = "Sets whenever AI can be present. Removes every spawned AI if disabled."})
    --ai:button("Select AI", function() self._selecting = true end, {text = "Select AI for debugging"})
    ai:button("SpawnPhalanx", ClassClbk(self, "spawn_phalanx"), {text = "Force Spawn Phalanx"})

    local draw = self._holder:group("Drawing", groups_opt)
    draw:tickbox("Tasks", ClassClbk(self, "draw_group_ai"), false, {text = "Group AI Tasks", size_by_text = true})
    draw:tickbox("Drama", ClassClbk(self, "draw_drama"), false, {size_by_text = true})
    draw:tickbox("Triggers", ClassClbk(self, "set_draw_triggers"), false, {size_by_text = true})
    draw:tickbox("AssaultInfo", ClassClbk(self, "set_combat_debug"), false, {size_by_text = true})
    draw:tickbox("Raycasts", ClassClbk(self, "show_raycast"), Global.show_raycast, {size_by_text = true})
    draw:combobox("ElementExecutions", ClassClbk(self, "set_script_debug"), {"Disabled", "Every element", "Elements with debug flag"}, 1)

    self._duality = self._holder:group("UnitDuality", groups_opt)
    self._duality:tickbox("CompareContinents", nil, false, {help = "Should units from different continents be compared to each other"})
    self._duality:button("CheckForCollisions", ClassClbk(self, "check_duality"), {help = "Goes through all units and checks if any of the same share position and rotation"})
    self._duality:group("Collisions", {full_bg_color = false, visible = false, size = self._holder.size * 0.8, inherit_values = {size = self._holder.size * 0.8}})
    --self._duality:group("Positions", {text = "Collisions with only position", visible = false, closed = true, size = self._holder.size * 0.8, inherit_values = {size = self._holder.size * 0.8}})

    self._loops = self._holder:group("ElementLoops", groups_opt)
    self._loops:button("CheckForLoops", ClassClbk(self, "check_loops"), {help = "Goes through all elements and checks if any of them execute each other endlessly"})

    local list = {}
    local continents = managers.worlddefinition._continents
    for _, continent in ipairs(managers.editor._continents) do
        if continents[continent] and continents[continent].editor_only then
            table.insert(list, continent)
        end
    end
    self._sorter = self._holder:group("EditorUnitSorter", groups_opt)
    self._sorter:combobox("TargetContinent", nil, list, 1)
    self._sorter:tickbox("Coverpoints", nil, true, {size_by_text = true})
    self._sorter:tickbox("NavBlockers", nil, true, {size_by_text = true})
    self._sorter:tickbox("NavSplitters", nil, true, {size_by_text = true})
    self._sorter:button("SortEditorUnits", ClassClbk(self, "sort_units"), {help = "Goes through all the checked editor units and moves them into the target editor only continent."})

    self._built = true
end

function DebugTool:mouse_busy(b, x, y)
    return self:active() and self._selecting
end

function DebugTool:mouse_pressed(button, x, y)
    if not self:active() or not self._selecting then
        return
    end

    if button == Idstring("0") then
       self:select_ai()
    elseif button == Idstring("1") then
        self._selecting = false
    end
end

function DebugTool:select_ai()
    local rays = managers.editor:select_units_by_raycast(managers.slot:get_mask("persons"))--, ClassClbk(self, "check_unit_ok"))
    if rays then
        for _, ray in pairs(rays) do
            if alive(ray.unit) and ray.unit:brain() then
                self:GetPart("static"):set_selected_unit(ray.unit)
                self._selecting = false
            end
        end
    end
end

function DebugTool:check_duality(item) 
    BLE.Utils:YesNoQuestion("This will go through every unit on the level, it might take some time to complete on bigger levels.", function()
        local units = {}
        local collisions = {
            only_positions = {},
            complete = {}
        }

        local continent_check = self._duality:GetItem("CompareContinents"):Value()
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:unit_data() and not unit:mission_element() then
                local pos = unit:position()
                pos = pos:with_x(math.floor(pos.x))
                pos = pos:with_y(math.floor(pos.y))
                pos = pos:with_z(math.floor(pos.z))
                local rot = unit:rotation()
                rot = Vector3(math.floor(rot:yaw()), math.floor(rot:pitch()), math.floor(rot:roll()))
                local ud = unit:unit_data()
                local unit_name = unit:name():s() .. (not continent_check and ud and ud.continent or "")
                local unit_table = units[unit_name]
                if unit_table then
                    for _, data in ipairs(unit_table) do
                        if data.pos == pos and data.rot == rot then
                            --if data.rot == rot then
                                table.insert(collisions.complete, {
                                    u1 = data.unit,
                                    u2 = unit,
                                    pos = pos
                                })
                            --else
                            --    table.insert(collisions.only_positions, {
                            --        u1 = data.unit,
                            --        u2 = unit,
                            --        pos = pos
                            --    })
                            --end
                        end
                    end
                    table.insert(unit_table, {
                        unit = unit,
                        pos = pos,
                        rot = rot
                    })
                else
                    units[unit_name] = {
                        {
                            unit = unit,
                            pos = pos,
                            rot = rot,
                        }
                    }
                end
            end
        end

        local results = self._duality:GetItem("Collisions")
        local button = self._duality:GetItem("CheckForCollisions")
        results:ClearItems()
        if #collisions.complete > 0 then
            results:SetVisible(true)
            button:SetVisible(false)
            local tb = results:GetToolbar()
            tb:tb_imgbtn("CheckAgain", ClassClbk(self, "check_duality"), nil, BLE.Utils.EditorIcons.reset_settings, {visible = true, help = "Re-check for collisions"})

            for _, collision in ipairs(collisions.complete) do
                self:build_collision(collision, results)
            end
        else
            results:SetVisible(false)
            button:SetVisible(true)
            BLE.Dialog:Show({title = "No Collisions!", message = "No collisions found. Great!", force = true})
        end

        --if #collisions.only_positions > 0 then
        --    for _, collision in ipairs(collisions.only_positions) do
        --        self:build_collision(collision, position)
        --    end
        --else
        --    position:divider("No collisions found. Great!", {border_left = false})
        --end
    end)
end

function DebugTool:build_collision(collision, group)
    local u1 = collision.u1
    local u2 = collision.u2
    local pos = collision.pos
    if not u1 or not u2 or not u1:unit_data() or not u2:unit_data() then
        return
    end
    local holder = group:holder(i, {offset = 2, align_method = "grid"})
    local w = holder.w / 2 - 1
    holder:button(u1:unit_data().name_id, ClassClbk(self, "select_unit", u1), {w = w})
    holder:button(u2:unit_data().name_id, ClassClbk(self, "select_unit", u2), {w = w, position = function(item)
        item:SetPositionByString("RightCentery")
    end})
end

function DebugTool:check_loops(item) 
    local loops = {}
    local elements = {}

    local function check_loop(id, on_executed)
        for _, executed in ipairs(on_executed) do
            if executed.delay == 0 then
                local element = managers.mission:get_mission_element(executed.id)
                for _, link in pairs(element.values.on_executed) do
                    if link.id == id and link.delay == 0 and not table.contains(elements, executed.id) then
                        table.insert(loops, {e1 = id, e2 = executed.id})
                        table.insert(elements, id)
                    end
                end
            end
        end
    end
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for _, element in pairs(tbl.elements) do
                    if element.values and element.values.on_executed then
                        check_loop(element.id, element.values.on_executed)
                    end
                end
            end
        end
    end

    self._loops:ClearItems()
    if #loops > 0 then
        local tb = self._loops:GetToolbar()
        tb:tb_imgbtn("CheckAgain", ClassClbk(self, "check_loops"), nil, BLE.Utils.EditorIcons.reset_settings, {help = "Re-check for loops"})
        for _, loop in ipairs(loops) do
            self:build_loop(loop, self._loops)
        end
    else
        self._loops:button("CheckForLoops", ClassClbk(self, "check_loops"), {help = "Goes through all elements and checks if any of them execute each other endlessly"})
        BLE.Dialog:Show({title = "No Loops!", message = "No execute loops found. Great!", force = true})
    end
end

function DebugTool:build_loop(loop, group)
    local mission = self:GetPart("mission")
    local e1 = mission:get_element_unit(loop.e1)
    local e2 = mission:get_element_unit(loop.e2)
    if not e1 or not e2 or not e1:mission_element() or not e2:mission_element() then
        return
    end
    local holder = group:holder(i, {offset = 2, align_method = "grid"})
    local w = holder.w / 2 - 1
    holder:button(e1:mission_element().element.editor_name, ClassClbk(self, "select_unit", e1), {w = w})
    holder:button(e2:mission_element().element.editor_name, ClassClbk(self, "select_unit", e2), {w = w, position = function(item)
        item:SetPositionByString("RightCentery")
    end})
end

function DebugTool:sort_units(item)
    BLE.Utils:YesNoQuestion("This will move all checked editor unit types over to the target continent.", function()
        local static = self:GetPart("static")
        local target_continent = self._sorter:GetItem("TargetContinent"):SelectedItem()
        local editor_units = {}
        if self._sorter:GetItem("NavBlockers"):Value() then
            table.insert(editor_units, "navigation_blocker")
            table.insert(editor_units, "nav_blocker")
        end
        if self._sorter:GetItem("NavSplitters"):Value() then
            table.insert(editor_units, "navigation_splitter") 
            table.insert(editor_units,"nav_splitter")
        end
        if self._sorter:GetItem("Coverpoints"):Value() then
            table.insert(editor_units, "ai_coverpoint")
        end

        local sorted = {}

        local continents = managers.worlddefinition._continent_definitions
        for _, unit in pairs(World:find_units_quick("disabled", "all")) do
            local ud = unit:unit_data()
            if ud and ud.name and ud.only_exists_in_editor and ud.continent ~= target_continent then
                for _, search in ipairs(editor_units) do 
                    if ud.name:find(search) then
                        static:set_unit_continent(unit, ud.continent, target_continent, true)
                        local index = search:gsub("nav_", ""):gsub("navigation_", ""):gsub("ai_", "")
                        sorted[index] = sorted[index] and sorted[index] + 1 or 1
                        break
                    end
                end
            end
        end
        static:selection_to_menu()

        if table.size(sorted) > 0 then
            local message = "Successfully moved all desired editor units to the target continent.\n"
            message = sorted.blocker and (message.."\nSorted Blockers: "..sorted.blocker) or message
            message = sorted.splitter and (message.."\nSorted Splitters: "..sorted.splitter) or message
            message = sorted.coverpoint and (message.."\nSorted Coverpoints: "..sorted.coverpoint) or message
            BLE.Dialog:Show({title = "Units Sorted!", message = message, force = true})
        else
            BLE.Dialog:Show({title = "Task Failed Successfully!", message = "Couldn't find any editor units outside the target continent.", force = true})
        end
    end)
end

function DebugTool:select_unit(unit, item)
    if alive(unit) then
        self:GetPart("static"):set_selected_unit(unit)
        managers.editor:center_view_on_unit(unit)
    end
end

function DebugTool:set_script_debug(item)
    local value = item:Value() 
    managers.editor:set_script_debug(value == 2)
    managers.mission:set_persistent_debug_enabled(value > 1)
end

function DebugTool:spawn_phalanx(item)
    local groupai = managers.groupai:state()

    if groupai._phalanx_spawn_group then
        BLE.Dialog:Show({title = "Can't spawn phalanx", message = "The captain is already alive!", force = true})
		return
	end

    if not groupai._phalanx_center_pos then
        BLE.Dialog:Show({title = "Can't spawn phalanx", message = "The captain cannot spawn without an active Special Objective set to the \"AI_phalanx\" action!", force = true})
        return
	end
    
    groupai:_spawn_phalanx()

    if not groupai._phalanx_spawn_group then
        BLE.Dialog:Show({title = "Can't spawn phalanx", message = "The captain cannot spawn without an active Enemy Group set to the \"Phalanx\" group type!", force = true})
		return
	end

    if table.size(groupai._flee_points) == 0 then
        BLE.Dialog:Show({title = "No flee points!", message = "The level is missing active flee points, the captain will not be able to leave!", force = true})
    end
end


function DebugTool:draw_group_ai(item) managers.groupai:state():set_debug_draw_state(item:Value()) end
function DebugTool:draw_drama(item) managers.groupai:state():set_drama_draw_state(item:Value()) end
function DebugTool:show_raycast(item) Global.show_raycast = item:Value() end
function DebugTool:set_combat_debug(item) self._parent:set_combat_debug(item:Value()) end
function DebugTool:set_draw_triggers(item) self._parent._draw_triggers = item:Value() end
function DebugTool:set_ai_enabled(item) managers.groupai:state():set_AI_enabled(item:Value()) end