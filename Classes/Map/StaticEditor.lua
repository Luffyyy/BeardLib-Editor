--Clean this script by separating parts of it to different classes
StaticEditor = StaticEditor or class(EditorPart)
local Static = StaticEditor
local Utils = BLE.Utils
function Static:init(parent, menu)
    Static.super.init(self, parent, menu, "Selection", nil, {delay_align_items = true})
    self._selected_units = {}
    self._nav_surfaces = {}
    self._ignore_raycast = {}
    self._ignored_collisions = {}
    self._set_units = {}
    self._set_elements = {}
    self._nav_surface = Idstring("core/units/nav_surface/nav_surface")
    self._widget_slot_mask = World:make_slot_mask(1)
end

function Static:enable()
    Static.super.enable(self)
    self:bind_opt("DeleteSelection", ClassClbk(self, "delete_selected_dialog"))
    self:bind_opt("CopyUnit", ClassClbk(self, "CopySelection"))
    self:bind_opt("PasteUnit", ClassClbk(self, "Paste"))
    self:bind_opt("TeleportToSelection", ClassClbk(self, "KeyFPressed"))
    local quick = self:GetPart("quick")
    self:bind_opt("ToggleRotationWidget", ClassClbk(quick, "toggle_widget", "rotation"))
    self:bind_opt("ToggleMoveWidget", ClassClbk(quick, "toggle_widget", "move"))
    self:bind_opt("ToggleTransformOrientation", ClassClbk(self._parent, "toggle_local_move"))
    self:bind_opt("RotateSpawnDummyYaw", ClassClbk(self, "RotateSpawnDummyYaw"))
    self:bind_opt("RotateSpawnDummyPitch", ClassClbk(self, "RotateSpawnDummyPitch"))
    self:bind_opt("RotateSpawnDummyRoll", ClassClbk(self, "RotateSpawnDummyRoll"))
    self:bind_opt("SettleUnits", ClassClbk(self, "SettleUnits"))
end

function Static:get_grabbed_unit()
    return self._grabbed_unit
end

function Static:RotateSpawnDummyYaw()
    local unit = self._parent:get_dummy_or_grabbed_unit()
    if alive(unit) then
        unit:set_rotation(unit:rotation() * Rotation(self:Val("RotateSpawnDummy"), 0, 0))
    end
end

function Static:RotateSpawnDummyPitch()
    local unit = self._parent:get_dummy_or_grabbed_unit()
    if alive(unit) then
        unit:set_rotation(unit:rotation() * Rotation(0, self:Val("RotateSpawnDummy"), 0))
    end
end

function Static:RotateSpawnDummyRoll()
    local unit = self._parent:get_dummy_or_grabbed_unit()
    if alive(unit) then
        unit:set_rotation(unit:rotation() * Rotation(0, 0, self:Val("RotateSpawnDummy")))
    end
end

function Static:SettleUnits()
    self:StorePreviousPosRot()
    local selected_units = self:selected_units()
    for i, unit in pairs(selected_units) do
        if alive(unit) then
            local from = unit:position()
            local to = from - Vector3(0, 0, 2000)
            local ray = World:raycast("ray", from, to, "slot_mask", self._parent._editor_all, "ignore_unit", selected_units)
            if ray and ray.body then
                local pos = ray.position
                local rot = unit:rotation()
                BLE.Utils:SetPosition(unit, pos, rot)
            end
        end
    end
    self:recalc_all_locals()
end

function Static:mouse_pressed(button, x, y)
    if not self:enabled() or managers.editor:mouse_busy() then
        return
    end
    if button == Idstring("2") then
        self:start_grabbing()
    end
    if button == Idstring("0") then
        if self:Val("EndlessSelection") then
            self._reset_raycast = TimerManager:game():time() + self:Val("EndlessSelectionReset")
        end
        if self._grabbed_unit then
            self:StorePreviousPosRot()
            local pos = self._grabbed_unit:position()
            self:finish_grabbing()
            self._parent:set_unit_positions(pos)
            return
        end
        self._widget_hold = true
        self._parent:reset_widget_values()
        local from = self._parent:get_cursor_look_point(0)
        local to = self._parent:get_cursor_look_point(100000)
        local unit = self._parent:widget_unit()
        if unit then
            if self._parent._move_widget:enabled() then
                local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._move_widget:widget())
                if ray and ray.body then
                    if (alt() and not ctrl()) then self:Clone() end
                    local rot = self._parent:use_local_move() and unit:rotation() or Rotation()
                    self:StorePreviousPosRot()
                    self._parent._move_widget:add_move_widget_axis(ray.body:name():s())
                    self._parent._move_widget:set_move_widget_offset(unit, rot)
                    self._parent._using_move_widget = true
                end
            end
            if self._parent._rotate_widget:enabled() and not self._parent._using_move_widget then
                local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._rotate_widget:widget())
                if ray and ray.body then
                    self:StorePreviousPosRot()
                    self._parent._rotate_widget:set_rotate_widget_axis(ray.body:name():s())
                    self._parent._rotate_widget:set_world_dir(ray.position)
                    self._parent._rotate_widget:set_rotate_widget_start_screen_position(self._parent:world_to_screen(ray.position):with_z(0))
                    self._parent._rotate_widget:set_rotate_widget_unit_rot(self._selected_units[1]:rotation())
                    self._parent._using_rotate_widget = true
                end
            end
        end
        if not self._parent._using_rotate_widget and not self._parent._using_move_widget then
            self:select_unit()
        end
    elseif button == Idstring("1") then
        if self._grabbed_unit then
            self._parent:set_unit_positions(self._grabbed_unit_original_pos)
            self:finish_grabbing()
            return
        end
        if self:Val("EndlessSelection") then
            self._reset_raycast = nil
            self._ignore_raycast = {}
        else
            self:set_drag_select()
        end
        self:select_unit(true)
        self._mouse_hold = true
    end
end

function Static:finish_grabbing()
    self._grabbed_unit = nil
    self:GetPart("menu"):set_tabs_enabled(true)
    local transform = self:GetItem('Transform')
    self:set_title(self._original_title)
    self._original_title = nil
    self:update_ignored_collisions()
    transform:SetEnabled(true)
end

function Static:deselect_unit(item) self:set_unit(true) end
function Static:mouse_released(button, x, y)
    if not self:enabled() then
        return
    end

    self._mouse_hold = false
    self._widget_hold = false
    self._drag_select = false

    self:remove_polyline()

    if self._drag_units and #self._drag_units > 0 then
        for _, unit in pairs(self._drag_units) do
            if ctrl() then
                self:set_selected_unit(unit, true, true)
            elseif alt() then
                table.delete(self._selected_units, unit)
            end
        end
        self:selection_to_menu()
	end

	self._drag_units = nil
    self:update_ignored_collisions()
end

function Static:update_ignored_collisions()
    for _, unit in pairs(self._ignored_collisions) do
        Utils:UpdateCollisionsAndVisuals(unit, true)
    end
    self._ignored_collisions = {}
    self:set_units()
end

function Static:set_units()
    for key, unit in pairs(self._set_units) do
        if alive(unit) then
            local ud = unit:unit_data()
            managers.worlddefinition:set_unit(ud.unit_id, unit, ud.continent, ud.continent)
        end
    end
    for _, me in pairs(self._set_elements) do
        local element = me.element
        if alive(me._unit) then
            element.values.position = me._unit:position()
            element.values.rotation = me._unit:rotation()
            managers.mission:set_element(element)
        else
            BLE:log('Something is wrong with element with ID %s', tostring(element.id))
        end
	end
	self:update_positions()
    self._set_units = {}
    self._set_elements = {}
end

function Static:build_default()
    self._editors = {}
    self:set_title("Selection")
    self:divider("No selection >_<", {border_left = false})
    self:button("World Menu", ClassClbk(self:GetPart("world"), "Switch"))
end

function Static:build_quick_buttons(cannot_be_saved, cannot_be_prefab)
	self:set_title("Selection")
    local quick = self:group("QuickActions", {align_method = "grid"})
    quick:s_btn("Deselect", ClassClbk(self, "deselect_unit"))
    quick:s_btn("DeleteSelection", ClassClbk(self, "delete_selected_dialog"))
    if not cannot_be_prefab then
        quick:s_btn("CreatePrefab", ClassClbk(self, "add_selection_to_prefabs"))
    end
    if not cannot_be_saved then
        quick:s_btn("AddToCurrentPortal", ClassClbk(self, "add_unit_to_portal"))
        quick:s_btn("RemoveFromCurrentPortal", ClassClbk(self, "remove_unit_from_portal"))
        self:group("Group", {align_method = "grid"}) --lmao
		self:build_group_options()
    end
end

function Static:build_group_options()
	local group = self:GetItem("Group")
	local selected_unit = self:selected_unit()
	if not group or not selected_unit then
		return
	end
    local selected_units = self:selected_units()
    local can_group = #selected_units > 1
    local inside_group = false
    local is_unit = false
	local sud = selected_unit:unit_data()
	if can_group then
		for _, unit in pairs(selected_units) do
			local ud = unit:unit_data()
			if not ud.unit_id or not ud.continent or managers.worlddefinition:is_world_unit(unit) then
				can_group = false
                break
			end
        end
    else
        local unit = selected_units[1]
        if alive(unit) then
            local ud = unit:unit_data()
            if ud.unit_id and ud.continent then
                is_unit = true
            end
        end
	end
	group:ClearItems()
    if self._selected_group then
        group:divider("GroupToolTip", {text = "Hold ctrl and press mouse 2 to add units to/remove units from group"})
        group:textbox("GroupName", ClassClbk(self, "set_group_name"), self._selected_group.name)
        group:s_btn("DestroyGroup", ClassClbk(self, "remove_group"))
    else
        if can_group or is_unit then
            group:s_btn("AddToGroup", ClassClbk(self, "open_addremove_group_dialog", false), {text = "Add Unit(s) To Group"})
            group:s_btn("GroupUnits", ClassClbk(self, "add_group"), {text = (can_group and "Group Units" or "Make a Group")})
        else
            group:Destroy()
        end
    end
end

function Static:unit_value(value_key, toggle)
    local selected_units = self._selected_units
    local selected_unit = selected_units[1]
    local value = selected_unit:unit_data()[value_key]
    if selected_unit then
        if #selected_units > 1 then
            local values_differ
            for _, unit in pairs(selected_units) do
                local ud = unit:unit_data()
                if ud[value_key] then
                    if ud[value_key] ~= value then
                        values_differ = true
                    end
                elseif value ~= nil then
                    values_differ = true
                end
            end
            return values_differ and "*" or value, values_differ
        else
            return value
        end
    end
end

function Static:build_unit_editor_menu()
    self:clear_menu()
    self:set_title("Selection")
    self:build_unit_main_values()
    self:build_positions_items()
    self:build_extension_items()
end

function Static:build_unit_main_values()
    local name = self:unit_value("name")
    local main = self:group("Main", {align_method = "grid", visible = not self._built_multi or name ~= nil})
    if not self._built_multi then
        main:GetToolbar():lbl("ID", {text = "ID: 0000000", size_by_text = true, foreground = main.foreground, auto_foreground = false})
        main:textbox("Name", ClassClbk(self, "set_unit_data"), nil, {help = "the name of the unit", control_slice = 0.8})
    end

    main:pathbox("UnitPath", ClassClbk(self, "set_unit_data"), name, "unit", {control_slice = 0.75, check = function(unit)
        local t = Utils:GetUnitType(unit)
        return t ~= Idstring("being") and t ~= Idstring("brush") and t ~= Idstring("wpn") and t ~= Idstring("item")
    end})

    local has_elements = false
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:mission_element() then
            has_elements = true
            break
        end
    end

    if not has_elements then
        local continent, values_differ = self:unit_value("continent")
        local list = self._parent._continents
        if values_differ then
            list = table.list_add({"*", list})
        end
        local con = main:combobox("Continent", ClassClbk(self, "set_unit_data"), list, 1, {visible = not self._built_multi or continent ~= nil})
        con:SetSelectedItem(continent)
    end

    main:tickbox("Enabled", ClassClbk(self, "set_unit_data"), true, {size_by_text = true, help = "Setting the unit enabled or not[Debug purpose only]"})
    main:tickbox("HideOnProjectionLight", ClassClbk(self, "set_unit_data"), self:unit_value("hide_on_projection_light") == true, {size_by_text = true})
    main:tickbox("DisableShadows", ClassClbk(self, "set_unit_data"), self:unit_value("disable_shadows") == true, {size_by_text = true})
    main:tickbox("DisableCollision", ClassClbk(self, "set_unit_data"), self:unit_value("disable_collision") == true, {size_by_text = true})
    main:tickbox("DisableOnAIGraph", ClassClbk(self, "set_unit_data"), self:unit_value("disable_on_ai_graph") == true, {size_by_text = true})
    main:tickbox("DelayLoading", ClassClbk(self, "set_unit_data"), self:unit_value("delayed_load") == true, {size_by_text = true})
end

function Static:build_extension_items()
    self._editors = {}
    for k, v in pairs({
        light = EditUnitLight,
        ladder = EditLadder,
        editable_gui = EditUnitEditableGui,
        zipline = EditZipLine,
        wire = EditWire,
        mesh_variation = EditMeshVariation
    }) do
        self._editors[k] = v:new():is_editable(self)
    end
end

function Static:build_grab_button(transform)
    transform:button("Grab", ClassClbk(self, "start_grabbing"))
end

function Static:start_grabbing()
    if self._grabbed_unit then
        return
    end
    local unit = self:selected_unit()
    if unit ~= nil then --MiamiCenter
       self._grabbed_unit_original_pos = unit:position()
       self._grabbed_unit = unit
       self._original_title = self:get_title()
       self:set_title("Press: LMB to place, RMB to cancel")
       self:GetPart("menu"):set_tabs_enabled(false)
       self:GetItem("Transform"):SetEnabled(false)
   end
end

function Static:build_positions_items(cannot_be_saved, cannot_be_prefab)
    self._editors = {}
    self:build_quick_buttons(cannot_be_saved, cannot_be_prefab)
    local transform = self:group("Transform")
    self:build_grab_button(transform)

    transform:button("IgnoreRaycastOnce", function()
        for _, unit in pairs(self:selected_units()) do
            if unit:unit_data().unit_id then
                self._ignore_raycast[unit:unit_data().unit_id] = true
            end
        end
    end)

    transform:Vec3Rot("", ClassClbk(self, "set_unit_data"), nil, nil, {on_click = ClassClbk(self, "StorePreviousPosRot"), step = self:GetPart("opt")._menu:GetItem("GridSize"):Value()})
end

function StaticEditor:update_positions()
    local unit = self._selected_units[1]
    if alive(unit) then
        if #self._selected_units > 1 or not unit:mission_element() then
            self:GetItem("Position"):SetValue(unit:position())
            self:GetItem("Rotation"):SetValue(unit:rotation())
            self:GetPart("instances"):update_positions()
            self:GetPart("world"):update_positions()
            self:GetItem("Position"):SetStep(self._parent._grid_size)
            --self:GetItem("Rotation"):SetStep(self._parent._snap_rotation)
        elseif unit:mission_element() and self:GetPart("mission")._current_script then
            self:GetPart("mission")._current_script:update_positions(unit:position(), unit:rotation())
        end
        for _, unit in pairs(self:selected_units()) do
            if alive(unit) and unit:editable_gui() then
                unit:editable_gui():set_blend_mode(unit:editable_gui():blend_mode())
            end
        end
        for _, editor in pairs(self._editors) do
            if editor.update_positions then
                editor:update_positions(unit)
            end
        end
        if self._built_multi and not self._grabbed_unit then
            self:set_title("Selection - " .. tostring(#self._selected_units))
        end
    end
end

function Static:open_addremove_group_dialog(remove)
    local list_groups = {}
    local continents = managers.worlddefinition._continent_definitions
    if remove then
        local groups = self:get_groups_from_unit(self._selected_units[1])
        for _, group in pairs(groups) do
            if group.name then
                table.insert(list_groups, {name = group.name, group = group})
            end
        end
    else
        for _, continent in pairs(self._parent._continents) do
            if continents[continent].editor_groups then
                for _, editor_group in pairs(continents[continent].editor_groups) do
                    if editor_group.name then table.insert(list_groups, {name = editor_group.name, group = editor_group}) end
                end
            end
        end
    end

    local units = self._selected_units
    BLE.ListDialog:Show({
        list = list_groups,
        force = true,
        callback = function(item)
            local group = item.group
            self:select_group(group)
            for _, unit in pairs(units) do
                if alive(unit) then
                    if remove and table.contains(group.units, unit:unit_data().unit_id) then
                        table.delete(group.units, unit:unit_data().unit_id)
                    elseif not table.contains(group.units, unit:unit_data().unit_id) then
                        table.insert(group.units, unit:unit_data().unit_id)
                        self:set_selected_unit(unit, true)
                    end
                    if #group.units <= 1 then
                        self:remove_group()
                    end
                    self:part("world"):refresh()
                end
            end
            BLE.ListDialog:hide()
        end
    })
end

function Static:set_unit_data()
    self._parent:set_unit_positions(self:GetItemValue("Position"))
    self._parent:set_unit_rotations(self:GetItemValue("Rotation"))

    if #self._selected_units == 1 then
        if not self:GetItem("Continent") then
            return
        end
		local unit = self._selected_units[1]
        local ud = unit:unit_data()
        if ud and ud.unit_id then
            local prev_id = ud.unit_id
            managers.worlddefinition:set_name_id(unit, self:GetItem("Name"):Value())

            --ud.unit_id = self:GetItem("ID"):Value()

            for _, editor in pairs(self._editors) do
                if editor.set_unit_data and editor:editable(unit) then
                    editor:set_unit_data()
                end
			end

            BeardLib.Utils:RemoveAllNumberIndexes(ud, true)
            ud.lights = Utils:LightData(unit)
            ud.triggers = Utils:TriggersData(unit)
            ud.editable_gui = Utils:EditableGuiData(unit)
            ud.ladder = Utils:LadderData(unit)
            ud.zipline = Utils:ZiplineData(unit)
			ud.cubemap = Utils:CubemapData(unit)

			local old_continent = ud.continent
            local new_continent = self:GetItem("Continent"):SelectedItem()

			if old_continent ~= new_continent then
				self:set_unit_continent(unit, old_continent, new_continent)
                self:GetItem("ID"):SetText("ID "..ud.unit_id)
			end

            self:set_unit_simple_values(unit)
            managers.worlddefinition:set_unit(prev_id, unit, old_continent, new_continent)
            self:set_unit_path(unit, self:GetItem("UnitPath"):Value())
        end
    else
        local i = 0
        for _, unit in pairs(self._selected_units) do
			local ud = unit:unit_data()
            if alive(unit) and ud.unit_id then
                i = i + 1
                self:set_unit_simple_values(unit)

                local continent = self:GetItem("Continent")
                if continent then
                    self:set_unit_continent(unit, ud.continent, continent:SelectedItem(), true)
                end
                self:set_unit_path(unit, self:GetItem("UnitPath"):Value(), i ~= 1)
            end
        end
    end
    --TODO: put in a different place
    self:GetPart("instances"):update_positions()
    self:GetPart("world"):update_positions()
end

function Static:set_unit_simple_values(unit)
    if not alive(unit) or not unit.unit_data then
        return
    end
    local ud = unit:unit_data()

    ud.disable_shadows = self:GetItem("DisableShadows"):Value()
    ud.disable_collision = self:GetItem("DisableCollision"):Value()
    ud.hide_on_projection_light = self:GetItem("HideOnProjectionLight"):Value()
    ud.disable_on_ai_graph = self:GetItem("DisableOnAIGraph"):Value()
    ud.delayed_load = self:GetItem("DelayLoading"):Value()

    for index = 0, unit:num_bodies() - 1 do
        local body = unit:body(index)
        if body then
            body:set_collisions_enabled(not ud.disable_collision)
            body:set_collides_with_mover(not ud.disable_collision)
        end
    end
    unit:set_enabled(self:GetItem("Enabled"):Value())
    unit:set_shadows_disabled(ud.disable_shadows)
end

function Static:set_unit_path(unit, path, add)
    local ud = unit:unit_data()

    if ud.name == path then
        return
    end

    local new_unit = unit

    if path and path ~= "" and path ~= "*" and PackageManager:has(Idstring("unit"), path:id()) then
        ud.name = path
        new_unit = self._parent:SpawnUnit(ud.name, unit, add == true, ud.unit_id)
        self._parent:DeleteUnit(unit, true)
        self:GetPart("select"):reload_menu("unit")
    end
    return new_unit
end

function Static:set_unit_continent(unit, old_continent, new_continent, set)
	local ud = unit:unit_data()
	local old_id = ud.unit_id
	if new_continent ~= "*" and old_continent ~= new_continent then
		ud.continent = new_continent

		managers.worlddefinition:ResetUnitID(unit, old_continent)
		self:set_unit_group(old_id, ud.unit_id, old_continent, new_continent)

		--Change all links to match the new ID.
		for _, link in pairs(managers.mission:get_links_paths_new(old_id, Utils.LinkTypes.Unit)) do
			link.tbl[link.key] = ud.unit_id
		end
	else
		new_continent = nil
	end
	if set then
		managers.worlddefinition:set_unit(old_id, unit, old_continent, new_continent)
	end
end

function Static:set_unit_group(old_id, new_id, old_continent, new_continent)
	for _, continent in pairs(managers.worlddefinition._continent_definitions) do
		continent.editor_groups = continent.editor_groups or {}
		for _, group in pairs(continent.editor_groups) do
			if type(group) == "table" and group.units then
				if group.reference == old_id then
					group.reference = new_id

					local continents = managers.worlddefinition._continent_definitions
					table.delete(continents[old_continent].editor_groups, group)
					continents[new_continent].editor_groups = continents[new_continent].editor_groups or {}
					table.insert(continents[new_continent].editor_groups, group)
				end
				for i, unit_id in pairs(group.units) do
					if unit_id == old_id then
						group.units[i] = new_id
						return
					end
				end
				return
			end
		end
	end
end

function Static:StorePreviousPosRot()
	for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            unit:unit_data()._prev_pos = unit:position()
            unit:unit_data()._prev_rot = unit:rotation()
        end
	end
end

function Static:set_group_name(item, group, name)
    local exists
    local continent = group and group.continent or self._selected_group.continent
    name = name or item:Value()
    for _, editor_group in pairs(managers.worlddefinition._continent_definitions[continent].editor_groups) do
        if editor_group.name == name then
            exists = true
            break
        end
    end
    if not exists then
        if item then
            self._selected_group.name = item:Value()
            self:part("world"):refresh()
            return
        end
        for _, editor_group in pairs(managers.worlddefinition._continent_definitions[continent].editor_groups) do
            if editor_group.name == group.name then
                editor_group.name = name
            end
        end
    end
    self:part("world"):refresh()
end

function Static:remove_group(item, group)
    group = group or self._selected_group
    if group then
        table.delete(managers.worlddefinition._continent_definitions[group.continent].editor_groups, group)
	    if self._selected_group then
            self._selected_group = nil
            self:build_group_options()
        end
    end
    self:part("world"):refresh()
end

function Static:add_group(item)
    local unit = self:selected_unit()
    BLE.InputDialog:Show({title = "Group Name", text = unit:unit_data().name_id, callback = function(name)
        local continent = managers.worlddefinition:get_continent_of_static(unit)
        local exists
        for _, group in pairs(continent.editor_groups) do
            if group.name == name then
                exists = true
            end
        end
        if not exists then
            local group = {continent = unit:unit_data().continent, reference = unit:unit_data().unit_id, name = name, units = {}, visible = true}
            for _, unit in pairs(self:selected_units()) do
                table.insert(group.units, unit:unit_data().unit_id)
            end
            table.insert(continent.editor_groups, group)
            self._selected_group = group
            self:build_group_options()
        end
        self:part("world"):refresh()
    end})
end

function Static:build_group_links(unit)
    local function create_link(text, id, group, clbk)
        group:button(id, clbk, {
            text = text,
            font_size = 16,
            label = "groups"
        })
    end

    local group = self:GetItem("InsideGroups") or self:group("InsideGroups", {max_height = 200, h = 200})

    local editor_groups = self:get_groups_from_unit(unit)
    for _, editor_group in pairs(editor_groups) do
        create_link(editor_group.name, unit:unit_data().unit_id, group, ClassClbk(self, "select_group", editor_group))
    end

    local group_buttons = self:GetItem("Group")
    if #group:Items() == 0 then
        group:Destroy()
	else
		group_buttons:SetVisible(true)
		group_buttons:button("RemoveFromGroup", ClassClbk(self, "open_addremove_group_dialog", true))
    end
end

function Static:get_groups_from_unit(unit)
    local continent = managers.worlddefinition:get_continent_of_static(unit)
    if not continent or not continent.editor_groups then return {} end
    local groups = {}
    for _, editor_group in pairs(continent.editor_groups) do
        if editor_group.name then   -- temp bandaid for nil groups
            for _, unit_id in pairs(editor_group.units) do
                if unit_id == unit:unit_data().unit_id then
                    table.insert(groups, editor_group)
                end
            end
        end
    end
    return groups
end

function Static:select_group(editor_group)
    self:reset_selected_units()
    self._selected_group = editor_group
    self:build_positions_items(false)
    for _, unit_id in pairs(editor_group.units) do
        local unit = managers.worlddefinition:get_unit(unit_id)
        self:set_selected_unit(unit, true)
    end
end

function Static:toggle_group_visibility(editor_group)
    if editor_group.visible == nil then editor_group.visible = false end

    editor_group.visible = not editor_group.visible
    for _, unit_id in pairs(editor_group.units) do
        local unit = managers.worlddefinition:get_unit(unit_id)
        if alive(unit) then unit:set_visible(editor_group.visible) end
    end
end

function Static:delete_unit_group_data(unit)
    if unit:mission_element() or not unit:unit_data() then return end
    local groups = self:get_groups_from_unit(unit)
    if groups then
        for _, editor_group in pairs(groups) do
            table.delete(editor_group.units, unit:unit_data().unit_id)
        end
    end
end

function Static:add_selection_to_prefabs(item, prefab_name)
    local remove_old_links
    local name_id = self._selected_units[1]:unit_data().name_id
    BLE.InputDialog:Show({title = "Prefab Name", text = #self._selected_units == 1 and name_id ~= "none" and name_id or prefab_name or "Prefab", callback = function(prefab_name, menu)
    	if prefab_name:len() > 200 then
    		BLE.Dialog:Show({title = "ERROR!", message = "Prefab name is too long!", callback = function()
    			self:add_selection_to_prefabs(item, prefab_name)
    		end})
    		return
    	end
        BLE.Prefabs[prefab_name] = self:GetCopyData(NotNil(remove_old_links and remove_old_links:Value(), true))
        FileIO:WriteScriptData(Path:Combine(BLE.PrefabsDirectory, prefab_name..".prefab"), BLE.Prefabs[prefab_name], "binary")
        self:GetPart("spawn"):get_menu("prefab"):reload()
    end, create_items = function(input_menu)
        remove_old_links = input_menu:tickbox("RemoveOldLinks", nil, self:Val("RemoveOldLinks"), {text = "Remove Old Links Of Copied Elements"})
    end})
end

function Static:mouse_moved(x, y)
    if self._mouse_hold then
        if not self._drag_select then
            self:select_unit(true)
        else
            self:_update_drag_select()
        end
    end
end

function Static:widget_unit()
    if self:Enabled() then
        for _, editor in pairs(self._editors) do
            if editor.widget_unit then
                return editor:widget_unit()
            end
        end
    end
    return self:selected_unit()
end

function Static:recalc_all_locals()
    if alive(self._selected_units[1]) then
        local reference = self._selected_units[1]
        reference:unit_data().local_pos = Vector3()
        reference:unit_data().local_rot = Rotation()
        for _, unit in pairs(self._selected_units) do
            if alive(unit) and unit ~= reference then
                self:recalc_locals(unit, reference)
            end
        end
    end
end

function Static:recalc_locals(unit, reference)
    local pos = unit:position()
    local ref_rot = reference:rotation():inverse()
    unit:unit_data().local_pos = (pos - reference:position()):rotate_with(ref_rot)
	unit:unit_data().local_rot = ref_rot * unit:rotation()
end

function Static:check_unit_ok(unit)
    local ud = unit:unit_data()
    if not ud then
        return false
    end
    if self:Val("EndlessSelection") then
        if ud.unit_id and self._ignore_raycast[ud.unit_id] == true then
            return false
        else
            self._ignore_raycast[ud.unit_id] = true
        end
    else
        if ud.unit_id and self._ignore_raycast[ud.unit_id] == true then
            self._ignore_raycast[ud.unit_id] = nil
            return false
        end
    end
    local current_layer = self:GetPart("world")._current_layer
    if ud.env_unit and not (self:Val("EnvironmentUnits") or (self:Val("EnvironmentUnitsWhileMenu") and current_layer == "environment")) then
        return false
    end
    if ud.sound_unit and not (self:Val("SoundUnits") or (self:Val("SoundUnitsWhileMenu") and current_layer == "sound")) then
        return false
    end
    if ud.instance and not self:Val("SelectInstances") then
        return false
    end
    if ud.unit_id == 0 and ud.name_id == "none" and not ud.name and not ud.position then
        return false
    end
    local mission_element = unit:mission_element() and unit:mission_element().element
    local wanted_elements = self:GetPart("opt")._wanted_elements
    if mission_element then
        return BLE.Options:GetValue("Map/ShowElements") and (#wanted_elements == 0 or table.get_key(wanted_elements, managers.mission:get_mission_element(mission_element).class))
    else
        return unit:visible()
    end
end

function Static:set_selected_units(units)
    self._selected_units = units
    self:set_selected_unit()
end

function Static:reset_selected_units()
    self:GetPart("mission"):remove_script()
    self:GetPart("world"):reset_selected_units()
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:mission_element() then unit:mission_element():unselect() end
    end
	self._selected_units = {}
    self._selected_group = nil
end

function Static:set_selected_unit(unit, add, skip_menu, skip_recalc)
    add = add == true
    if not skip_recalc then
        self:recalc_all_locals()
    end
    local units = {unit}
    if alive(unit) then
        local ud = unit:unit_data()
        if ud and ud.instance then
            if not unit:fake() then
                local instance = ud.instance_data or managers.world_instance:get_instance_data_by_name(ud.instance)
                local fake_unit
                for _, u in pairs(self:selected_units()) do
                    if u:fake() and u:object().name == ud.instance then
                        fake_unit = u
                        break
                    end
                end
                unit = fake_unit or FakeObject:new(instance, {instance = true})
                units[1] = unit
            end
        end
        if add and self._selected_group and ctrl() then
            if not unit:fake() and not not ud.continent and not managers.worlddefinition:is_world_unit(unit) then
                if table.contains(self._selected_group.units, ud.unit_id) then
                    table.delete(self._selected_group.units, ud.unit_id)
                else
                    table.insert(self._selected_group.units, ud.unit_id)
                end
                if #self._selected_group.units <= 1 then
                    self:remove_group()
                end
            end
        else
            if self:GetPart("opt"):get_value("SelectEditorGroups") then
                local continent = managers.worlddefinition:get_continent_of_static(unit)
                if not add then
                    add = true
                    self:reset_selected_units()
				end
				local found
				for _, continent in pairs(managers.worlddefinition._continent_definitions) do
                    continent.editor_groups = continent.editor_groups or {}
					for _, group in pairs(continent.editor_groups) do
						if group.units then
							if table.contains(group.units, unit:unit_data().unit_id) then
                                for _, unit_id in pairs(group.units) do
                                    local u = managers.worlddefinition:get_unit(unit_id)
                                    if alive(u) and not table.contains(units, u) then
                                        table.insert(units, u)
                                    end
								end
                                if self._selected_group then
                                    self._selected_group = nil
                                else
                                    self._selected_group = group
                                end
								found = true
								break
                            end
						end
						if found then
							break
						end
                    end
				end
            end
        end
    end
    if add then
        for _, unit in pairs(self:selected_units()) do
            if unit:mission_element() then unit:mission_element():unselect() end
        end
        for _, u in pairs(units) do
            if not table.contains(self._selected_units, u) then
                table.insert(self._selected_units, u)
            elseif not self._mouse_hold then
                table.delete(self._selected_units, u)
            end
        end
    elseif alive(unit) then
        self:reset_selected_units()
        self._selected_units[1] = unit
    end

    if not skip_menu then
        self:selection_to_menu()
    end
end

function Static:selection_to_menu()
    self:StorePreviousPosRot()
    local unit = self:selected_unit()
    self._parent:use_widgets(unit and alive(unit) and unit:enabled())
    for _, check_unit in pairs(self:selected_units()) do
        if alive(check_unit) and check_unit:mission_element() then
            check_unit:mission_element():select()
        end
    end

    if #self._selected_units > 1 then
        self:set_multi_selected()
        if self:Val("SelectAndGoToMenu") and not ctrl() then
            self:Switch()
        end
    else
        self._editors = {}
        if alive(unit) then
            if unit:mission_element() then
                self:GetPart("mission"):set_element(unit:mission_element().element)
            elseif self:GetPart("world"):is_world_unit(unit:name()) then
                self:GetPart("world"):build_unit_menu()
            elseif unit:fake() then
                self:GetPart("instances"):set_instance()
            else
                self:set_unit()
            end
            if self:Val("SelectAndGoToMenu") and not ctrl() then
                self:Switch()
            end
        else
            self:set_unit()
        end
    end
    self:GetPart("world"):set_selected_unit()
    self:recalc_all_locals()
end

local bain_ids = Idstring("units/payday2/characters/fps_mover/bain")

function Static:select_unit(mouse2)
    local rays = self._parent:select_units_by_raycast(self._parent._editor_all, ClassClbk(self, "check_unit_ok"))
    self:recalc_all_locals()
    if rays then
        for _, ray in pairs(rays) do
            if alive(ray.unit) and ray.unit:name() ~= bain_ids then
                if not self._mouse_hold then
                    self._parent:Log("Ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
                end
                if not mouse2 and ctrl() then
                    local selected_unit = self:selected_unit()
                    if alive(selected_unit) and selected_unit:mission_element() then
                        local script = self:GetPart("mission")._current_script
                        if script then
                            script:link_selection(ray.unit)
                            return
                        end
                    end
                end
                self:set_selected_unit(ray.unit, mouse2)
            end
        end
    end
end

function Static:set_multi_selected()
    self._built_multi = true
    self._editors = {}
	self:clear_menu()
    self:build_unit_main_values()
    self:build_positions_items()
	self:update_positions()
    self:build_group_options()
end

function Static:set_unit(reset)
    if reset then
        self:reset_selected_units()
    end
    self._built_multi = false
    local unit = self._selected_units[1]
    if alive(unit) and unit:unit_data() and not unit:mission_element() then
        if not reset then
            self:set_menu_unit(unit)
            return
        end
    end
    self:build_default_menu()
end

--Default menu for unit editing
function Static:set_menu_unit(unit)
    self:build_unit_editor_menu()

    self:GetItem("Name"):SetValue(unit:unit_data().name_id, false, true)
    self:GetItem("Enabled"):SetValue(unit:enabled())
    self:GetItem("UnitPath"):SetValue(unit:unit_data().name, false, true)
	self:GetItem("ID"):SetText("ID "..unit:unit_data().unit_id)
	local not_brush = not unit:unit_data().brush_unit
	local disable_shadows = self:GetItem("DisableShadows")
	local disable_collision = self:GetItem("DisableCollision")
	local hide_on_projection_light = self:GetItem("HideOnProjectionLight")
	local disable_on_ai_graph = self:GetItem("DisableOnAIGraph")
	local delayed_load = self:GetItem("DelayLoading")

	disable_shadows:SetVisible(not_brush)
	disable_collision:SetVisible(not_brush)
	hide_on_projection_light:SetVisible(not_brush)
	disable_on_ai_graph:SetVisible(not_brush)
	delayed_load:SetVisible(not_brush)

    disable_shadows:SetValue(unit:unit_data().disable_shadows, false, true)
    disable_collision:SetValue(unit:unit_data().disable_collision, false, true)
    hide_on_projection_light:SetValue(unit:unit_data().hide_on_projection_light, false, true)
	disable_on_ai_graph:SetValue(unit:unit_data().disable_on_ai_graph, false, true)
	delayed_load:SetValue(unit:unit_data().delayed_load, false, true)

    for _, editor in pairs(self._editors) do
        if editor.set_menu_unit then
            editor:set_menu_unit(unit)
        end
    end
    self:update_positions()
    self:GetItem("Continent"):SetSelectedItem(unit:unit_data().continent)
    local not_w_unit = not (unit:wire_data() or unit:ai_editor_data())
    self:GetItem("Continent"):SetEnabled(not_w_unit)
    self:GetItem("UnitPath"):SetEnabled(not_w_unit)
    self:build_links(unit:unit_data().unit_id)
    self:build_group_links(unit)
end

local function element_link_text(element, link, warn)
    --ugly
    return tostring(element.editor_name)
        .. "\n" .. tostring(element.id)
        .. " | " .. (link and string.pretty2(link)
        .. " | " or "") .. tostring(element.class):gsub("Element", "")
        .. "\n" .. (warn or "")
end

local function unit_link_text(ud, link)
    return tostring(ud.name_id) .. "\n" .. tostring(ud.unit_id) .. link
end

local function instance_link_text(instance_data, link)
    return tostring(instance_data.name) .. "\n" .. tostring(instance_data.folder) .. link
end

local function portal_link_text(name)
    return "Inside portal " .. name
end

function Static:build_links(id, match, element)
    match = match or Utils.LinkTypes.Unit
    local function create_link(text, id, group, clbk)
        group:button(id, clbk, {
            text = text,
            font_size = 14,
            label = "elements"
        })
    end

    local links = managers.mission:get_links_paths_new(id, match)
    local links_group = self:GetItem("LinkedBy") or self:group("LinkedBy", {max_height = 200})
    local same_links = {}
    links_group:ClearItems()

    for _, link in pairs(links) do
        same_links[link.element.id] = true
        create_link(element_link_text(link.element, link.upper_k or link.key), link.id, links_group, ClassClbk(self._parent, "select_element", link.element))
    end

    if match == Utils.LinkTypes.Unit then
        --Get portals that have the unit attached to - https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues/49
        local portal_layer = self:GetLayer("portal")
        for _, portal in pairs(clone(managers.portal:unit_groups())) do
            local ids = portal._ids
            if ids and ids[id] then
                local name = portal:name()
                create_link(portal_link_text(name), name, links_group, ClassClbk(portal_layer, "select_portal", name, true))
            end
        end
    end

    if match == Utils.LinkTypes.Element then
        local linking_group = self:GetItem("LinkingTo") or self:group("LinkingTo", {max_height = 200})
        if alive(linking_group) then
            linking_group:ClearItems()
        end
        for _, script in pairs(managers.mission._missions) do
            for _, tbl in pairs(script) do
                if tbl.elements then
                    for k, e in pairs(tbl.elements) do
                        local eid = e.id
                        for _, link in pairs(managers.mission:get_links_paths_new(eid, Utils.LinkTypes.Element, {{mission_element_data = element}})) do
                            local warn
                            if link.location == "on_executed" then
                                if same_links[eid] and link.tbl.delay == 0 then
                                    warn = "Warning - link already exists and can cause an endless loop, increase the delay."
                                end
                            end
                            same_links[eid] = true
                            create_link(element_link_text(e, link.location, warn), eid, linking_group, ClassClbk(self._parent, "select_element", e))
                        end
                    end
                end
            end
        end

        for uid, unit in pairs(managers.worlddefinition._all_units) do
            if alive(unit) then
                local ud = unit:unit_data()
                for _, link in pairs(managers.mission:get_links_paths_new(ud.unit_id, Utils.LinkTypes.Unit, {{mission_element_data = element}})) do
                    local linking_from = link.location
                    linking_from = linking_from and " | " .. string.pretty2(linking_from) or ""
                    create_link(unit_link_text(ud, linking_from), uid, linking_group, ClassClbk(self, "set_selected_unit", unit))
                end
            end
        end

        for _, instance in pairs(managers.world_instance:instance_data()) do
            for _, link in pairs(managers.mission:get_links_paths_new(instance.name, Utils.LinkTypes.Instance, {{mission_element_data = element}})) do
                local linking_from = link.location
                linking_from = linking_from and " | " .. string.pretty2(linking_from) or ""
                local fake_unit = FakeObject:new(instance, {instance = true})
                create_link(instance_link_text(instance, linking_from), "instance_"..instance.name, linking_group, ClassClbk(self, "set_selected_unit", fake_unit))
            end
        end

        if #linking_group:Items() == 0 then
            linking_group:Destroy()
        end
    end

    if #links_group:Items() == 0 then
        links_group:Destroy()
    end

    return links
end

function Static:remove_unit_from_portal()
    local portal_layer = self:layer("portal")
    local count = 0
    if portal_layer and portal_layer:selected_portal() then
        for _, unit in pairs(self._selected_units) do
            if unit:unit_data().unit_id then
                portal_layer:remove_unit_from_portal(unit)
                count = count + 1
            end
        end
        if #self:selected_units() == 1 then
            self:build_links(self:selected_unit():unit_data().unit_id)
        end
        Utils:Notify("Success", string.format("Removed %d units to selected portal", count))
    else
        Utils:Notify("Error", "No portal selected")
    end
end

function Static:add_unit_to_portal()
    local portal_layer = self:layer("portal")
    local count = 0
    if portal_layer and portal_layer:selected_portal() then
        for _, unit in pairs(self._selected_units) do
            if unit:unit_data().unit_id then
                portal_layer:add_unit_to_portal(unit, true)
                count = count + 1
            end
        end
        if #self:selected_units() == 1 then
            self:build_links(self:selected_unit():unit_data().unit_id)
        end
        portal_layer:load_portal_units()
        Utils:Notify("Success", string.format("Added %d units to selected portal", count))
    else
        Utils:Notify("Error", "No portal selected")
    end
end

function Static:delete_selected(item)
    self:GetPart("undo_handler"):SaveUnitValues(self._selected_units, "delete")
    local should_reload = #self._selected_units < 10
    for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            if unit:fake() then
                self:GetPart("instances"):delete_instance()
                if should_reload then
                    self:GetPart("select"):get_menu("instance"):reload()
                end
            else
                self:delete_unit_group_data(unit)
                self._parent:DeleteUnit(unit, false, should_reload)
            end
        end
    end
    if not should_reload then
        self:GetPart("select"):reload_menus()
    end
    self:reset_selected_units()
    self:set_unit()
end

function Static:delete_selected_dialog(item)
    if not self:selected_unit() or self._grabbed_unit then
        return
    end
    Utils:YesNoQuestion("This will delete the selection", ClassClbk(self, "delete_selected"))
end

function Static:update(t, dt)
    self.super.update(self, t, dt)
    if self._reset_raycast and self._reset_raycast <= t then
        self._ignore_raycast = {}
        self._reset_raycast = nil
    end
    for _, unit in pairs(self._nav_surfaces) do
        Application:draw(unit, 0,0.8,1)
    end
    for _, editor in pairs(self._editors) do
        if editor.update then
            editor:update(t, dt)
        end
    end

    if alive(self._grabbed_unit) then
        self._parent:set_unit_positions(self._parent._spawn_position)
        if self._parent._current_rot then
            self._parent:set_unit_rotations(self._parent._current_rot)
        else
            self._parent:set_unit_rotations(self._grabbed_unit:rotation())
        end
        Application:draw_line(self._parent._spawn_position - Vector3(0, 0, 2000), self._parent._spawn_position + Vector3(0, 0, 2000), 0, 1, 0)
        Application:draw_sphere(self._parent._spawn_position, 30, 0, 1, 0)
    end

    local color = BLE.Options:GetValue("AccentColor"):with_alpha(1)
    self._pen:set(color)
    local draw_bodies = self:Val("DrawBodies")
    if managers.viewport:get_current_camera() then
        for _, unit in pairs(self._selected_units) do
            if alive(unit) and not unit:fake() then
                if draw_bodies then
                    for i = 0, unit:num_bodies() - 1 do
                        local body = unit:body(i)
                        if self._parent:_should_draw_body(body) then
                            self._pen:body(body)
                        end
                    end
                else
                    Application:draw(unit, color:unpack())
                end
            end
        end
    end

    self:_update_drag_select_draw()
end

function Static:_update_drag_select_draw()
    local r = 1
	local g = 1
	local b = 1
	local brush = Draw:brush()

	if alt() then
		b = 0
		g = 0
		r = 1
	end

	if ctrl() then
		b = 0
		g = 1
		r = 0
    end

    brush:set_color(Color(0.15, 0.5 * r, 0.5 * g, 0.5 * b))
    for _, unit in ipairs(self._drag_units or {}) do
        brush:draw(unit)
        Application:draw(unit, r * 0.75, g * 0.75, b * 0.75)
    end
end

function Static:GetCopyData(remove_old_links, keep_location)
    local copy_data = {}
    local element_type = Utils.LinkTypes.Element
    local unit_type = Utils.LinkTypes.Unit
    local instance_type = Utils.LinkTypes.Instance
    for _, unit in pairs(self._selected_units) do
        local typ = unit:mission_element() and "element" or not unit:fake() and "unit" or unit:unit_data().instance and "instance" or "unsupported"
        local copy = {
            type = typ,
            mission_element_data = typ == "element" and unit:mission_element().element and deep_clone(unit:mission_element().element) or nil,
            unit_data = typ == "unit" and unit:unit_data() and deep_clone(unit:unit_data()) or nil,
            wire_data = typ == "unit" and unit:wire_data() and deep_clone(unit:wire_data()) or nil,
            ai_editor_data = typ == "unit" and unit:ai_editor_data() and deep_clone(unit:ai_editor_data()) or nil,
            instance_data = typ == "instance" and deep_clone(unit._o) or nil
        }
        if typ ~= "unsupported" then
            table.insert(copy_data, copy)
        end
    end

    --The id is now used as the number it should add to the latest id before spawning the prefab
    --Why we need to save ids? so elements can function even after copy pasting
    local unit_id = 0
    local world_unit_id = 0
    local element_id = 0
    local instance_id = 0
    for _, v in pairs(copy_data) do
        local typ = v.type
		if typ == "element" then
			if not keep_location then
				v.mission_element_data.script = nil
			end
            for _, link in pairs(managers.mission:get_links_paths_new(v.mission_element_data.id, element_type, copy_data)) do
                link.tbl[link.key] = element_id
            end
            v.mission_element_data.id = element_id
            element_id = element_id + 1
        elseif typ == "unit" then
            if v.unit_data.unit_id then
                local is_world = v.wire_data or v.ai_editor_data
                if not keep_location then
                    v.unit_data.continent = nil
                end
                for _, link in pairs(managers.mission:get_links_paths_new(v.unit_data.unit_id, unit_type, copy_data)) do
                    link.tbl[link.key] = is_world and world_unit_id or unit_id
                end
                v.unit_data.unit_id = is_world and world_unit_id or unit_id
                if is_world then
                    world_unit_id = world_unit_id + 1
                else
                    unit_id = unit_id + 1
                end
            end
        elseif typ == "instance" then
            if not keep_location then
                v.instance_data.continent = nil
                v.instance_data.script = nil
            end
            for _, link in pairs(managers.mission:get_links_paths_new(v.instance_data.name, instance_type, copy_data)) do
                link.tbl[link.key] = instance_id
            end

            v.instance_data._id = instance_id
            instance_id = instance_id + 1
        end
    end
	--Remove old links
	if remove_old_links then
        for _, v in pairs(copy_data) do
			if v.type == "element" then
				local e = {v}
				for _, continent in pairs(managers.mission._ids) do
					for id, _ in pairs(continent) do
						managers.mission:delete_links(id, element_type, e)
					end
                end
                for id, _ in pairs(managers.worlddefinition._all_units) do
                    managers.mission:delete_links(id, unit_type, e)
                end
            end
        end
	end

    return copy_data
end

function Static:CopySelection()
    if #self._selected_units > 0 and not self._parent._menu._highlighted then
        self._copy_data = self:GetCopyData(self:Val("RemoveOldLinks"), true) --Sadly thanks for ovk's "crash at all cost" coding I cannot use script converter because it would crash.
        if #self._copy_data == 0 then
        	self._copy_data = nil
        end
    end
end

function Static:Paste()
    if not Global.editor_safe_mode and not self._grabbed_unit and not self._parent._menu._highlighted and self._copy_data then
        self:SpawnCopyData(self._copy_data)
    end
end

function Static:SpawnPrefab(prefab)
    self:SpawnCopyData(prefab, true)
    if self.x then
        local cam = managers.viewport:get_current_camera()
        self:GetItem("Position"):SetValue(cam:position() + cam:rotation():y())
        self:set_unit_data()
    end
end

function Static:SpawnCopyData(copy_data, prefab)
    copy_data = deep_clone(copy_data)
    local project = BLE.MapProject
    local missing_units = {}
    local missing
    local assets = self:GetPart("assets")
    local mod, data = project:get_mod_and_config()
    local unit_ids = Idstring("unit")
    local add
    if data then
        add = project:get_level_by_id(data, Global.current_level_id).add
    end
	self:reset_selected_units()

    local instance_names = {}

    for _, v in pairs(copy_data) do
        local is_element = v.type == "element"
        local is_unit = v.type == "unit"
		if v.type == "element" then
			local c = managers.mission._scripts[v.mission_element_data.script] or nil
			c = c and c._continent or self._parent._current_continent
            local new_final_id = managers.mission:get_new_id(c)
            for _, link in pairs(managers.mission:get_links_paths_new(v.mission_element_data.id, Utils.LinkTypes.Element, copy_data)) do
                link.tbl[link.key] = new_final_id
            end
            v.mission_element_data.id = new_final_id
        elseif v.type == "unit" and v.unit_data.unit_id then
            local new_final_id = managers.worlddefinition:GetNewUnitID(v.unit_data.continent or self._parent._current_continent, (v.wire_data or v.ai_editor_data) and "wire" or "")
			for _, link in pairs(managers.mission:get_links_paths_new(v.unit_data.unit_id, Utils.LinkTypes.Unit, copy_data)) do
                link.tbl[link.key] = new_final_id
            end
            v.unit_data.unit_id = new_final_id
            local unit = v.unit_data.name
            if missing_units[unit] == nil then
                local is_preview_not_loaded = (not assets and not PackageManager:has(unit_ids, unit:id()))
                local not_loaded = not assets and assets:is_asset_loaded("unit", unit)
                if is_preview_not_loaded or not_loaded then
                    missing_units[unit] = true
                    missing = true
                else
                    missing_units[unit] = false
                end
            end
        elseif v.type == "instance" then
            local folder = v.instance_data.folder
            local instance_name = Path:GetFileName(Path:GetDirectory(folder)).."_"
            local new_final_name
            local i = instance_names[folder]
            if not i then
                local instance_names = managers.world_instance:instance_names()
                i = 1
                while(table.contains(instance_names, instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i)) do
                    i = i + 1
                end
            end
            new_final_name = instance_name .. (i < 10 and "00" or i < 100 and "0" or "") .. i
            instance_names[folder] = i + 1

			for _, link in pairs(managers.mission:get_links_paths_new(v.instance_data._id, Utils.LinkTypes.Instance, copy_data)) do
                link.tbl[link.key] = new_final_name
            end
            v.instance_data.name = new_final_name
            v.instance_data._id = nil
        end
	end
    local function all_ok_spawn()
        local units = {}
        for _, v in pairs(copy_data) do
            if v.type == "element" then
				table.insert(units, self:GetPart("mission"):add_element(v.mission_element_data.class, nil, v.mission_element_data, true))
            elseif v.type == "instance" then
                table.insert(units, self:GetPart("world"):SpawnInstance(v.instance_data.folder, v.instance_data, false))
            elseif v.unit_data then
                table.insert(units, self._parent:SpawnUnit(v.unit_data.name, v, nil, v.unit_data.unit_id, true))
            end
		end
		--When all units are spawned properly you can select.
        self:set_selected_units(units)
        self:GetPart("undo_handler"):SaveUnitValues(units, "spawn")
        self:GetPart("select"):reload_menu("unit")
        self:StorePreviousPosRot()
    end
    if missing then
        if assets then
            Utils:QuickDialog({title = ":(", message = "A unit or more are unloaded, to spawn the prefab/copy you have to load all of the units"}, {
                {"Load Units Using DB", function()
                    for unit, is_missing in pairs(missing_units) do
                        if assets:db_has_asset("unit", unit) then
                            assets:quick_load_from_db("unit", unit)
                        else
                            Utils:Notify("Failed", "Unfortunately not all assets can be loaded, therefore this prefab cannot be spawned in this map.")
                            return
                        end
                    end
                    all_ok_spawn()
                end},
                {"Load Units Using Packages", function()
                    local function find_packages()
                        for unit, is_missing in pairs(missing_units) do
                            if is_missing then
                                if (assets:is_asset_loaded(unit, "unit") or add and FileIO:Exists(Path:Combine(mod.ModPath, add.directory, unit..".unit"))) then
                                    missing_units[unit] = nil
                                end
                            else
                                missing_units[unit] = nil
                            end
                        end
                        if table.size(missing_units) > 0 then
                            assets:find_packages({unit = missing_units}, find_packages)
                        else
                            Utils:Notify("Nice!", "All units are now loaded, spawning prefab/copy..")
                            all_ok_spawn()
                        end
                    end
                    find_packages()
                end}
            })
        else
            Utils:Notify("ERROR!", "Cannot spawn the prefab[Unloaded units]")
        end
    else
        all_ok_spawn()
    end
end

function Static:Clone()
    self:CopySelection()
    self:Paste()
end

function Static:KeyFPressed()
    if self._selected_units[1] then
        self._parent:set_camera(self._selected_units[1]:position())
    end
end

function Static:set_unit_enabled(enabled)
	for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            unit:set_enabled(enabled)
        end
	end
end

function Static:set_drag_select()
	if self._parent._using_rotate_widget or self._parent._using_move_widget then
		return
    end

    if alt() or ctrl() then
        self._drag_select = true
        self._polyline = self._parent._menu._panel:polyline({
            color = Color(0.5, 1, 1, 1)
        })

        self._polyline:set_closed(true)

        self._drag_start_pos = managers.editor:cursor_pos()
    end
end

function Static:_update_drag_select()
	if not self._drag_select then
		return
	end

    local end_pos = managers.editor:cursor_pos()

	if self._polyline then
        local p1 = managers.editor:screen_pos(self._drag_start_pos)
		local p3 = managers.editor:screen_pos(end_pos)
		local p2 = Vector3(p3.x, p1.y, 0)
		local p4 = Vector3(p1.x, p3.y, 0)

		self._polyline:set_points({
			p1,
			p2,
			p3,
			p4
		})
	end

	local len = (end_pos - self._drag_start_pos):length()

	if len > 0.05 then
		local top_left = self._drag_start_pos
		local bottom_right = end_pos

		if bottom_right.y < top_left.y and top_left.x < bottom_right.x or top_left.y < bottom_right.y and bottom_right.x < top_left.x then
			top_left = Vector3(self._drag_start_pos.x, end_pos.y, 0)
			bottom_right = Vector3(end_pos.x, self._drag_start_pos.y, 0)
        end

		local units = World:find_units("camera_frustum", managers.editor:camera(), top_left, bottom_right, 500000, self._parent._editor_all)
		self._drag_units = {}

		for _, unit in ipairs(units) do
            if self:check_unit_ok(unit) then
                table.insert(self._drag_units, unit)
            end
		end
	end
end

function Static:remove_polyline()
	if self._polyline then
		managers.editor._menu._panel:remove(self._polyline)

		self._polyline = nil
	end
end
