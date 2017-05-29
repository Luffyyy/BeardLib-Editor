StaticEditor = StaticEditor or class(EditorPart)
function StaticEditor:init(parent, menu)
    StaticEditor.super.init(self, parent, menu, "Selection")
    self._selected_units = {}
    self._disabled_units = {}
    self._nav_surfaces = {}
    self._ignore_raycast = {}
    self._nav_surface = Idstring("core/units/nav_surface/nav_surface")
    self._widget_slot_mask = World:make_slot_mask(1)
end

function StaticEditor:enable()
    self:bind_opt("DeleteSelection", callback(self, self, "delete_selected_dialog"))
    self:bind_opt("CopyUnit", callback(self, self, "CopySelection"))
    self:bind_opt("PasteUnit", callback(self, self, "Paste"))
    self:bind_opt("TeleportToSelection", callback(self, self, "KeyFPressed"))
    local menu = self:Manager("menu")
    self:bind_opt("ToggleRotationWidget", callback(menu, menu, "toggle_widget", "rotation"))
    self:bind_opt("ToggleMoveWidget", callback(menu, menu, "toggle_widget", "move"))
end

function StaticEditor:mouse_pressed(button, x, y)
    if button == Idstring("0") then
        self._parent:reset_widget_values()
        local from = self._parent:get_cursor_look_point(0)
        local to = self._parent:get_cursor_look_point(100000)
        local unit = self._parent:widget_unit()
        if unit then
            if self._parent._move_widget:enabled() then
                local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._move_widget:widget())
                if ray and ray.body then
                    if (alt() and not ctrl()) then self:Clone() end
                    self._parent._move_widget:add_move_widget_axis(ray.body:name():s())      
                    self._parent._move_widget:set_move_widget_offset(unit, unit:rotation())
                    self._parent._using_move_widget = true
                end
            end
            if self._parent._rotate_widget:enabled() and not self._parent._using_move_widget then
                local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._rotate_widget:widget())
                if ray and ray.body then
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
        self:select_unit(true)
        self._mouse_hold = true
    end  
end

function StaticEditor:loaded_continents()
    self._nav_surfaces = {}
    for _, unit in pairs(managers.worlddefinition._all_units) do
        if unit:name() == self._nav_surface then
            table.insert(self._nav_surfaces, unit)
        end
    end
end

function StaticEditor:build_default_menu()
    StaticEditor.super.build_default_menu(self)
    self._editors = {}
    self:Divider("No Selection")
end

function StaticEditor:build_quick_buttons()
    local quick_buttons = self:Group("QuickButtons")
    self:Button("Deselect", callback(self, self, "deselect_unit"), {group = quick_buttons})
    self:Button("DeleteSelection", callback(self, self, "delete_selected_dialog"), {group = quick_buttons})
    self:Button("CreatePrefab", callback(self, self, "add_selection_to_prefabs"), {group = quick_buttons})
    self:Button("AddRemovePortal", callback(self, self, "addremove_unit_portal"), {group = quick_buttons, text = "Add To / Remove From Portal"})
end

function StaticEditor:build_unit_editor_menu()
    StaticEditor.super.build_default_menu(self)
    self._editors = {}
    local other = self:Group("Main")    
    self:build_positions_items()
    self:TextBox("Name", callback(self, self, "set_unit_data"), nil, {group = other, help = "the name of the unit"})
    self:TextBox("Id", callback(self, self, "set_unit_data"), nil, {group = other})
    self:PathItem("UnitPath", callback(self, self, "set_unit_data"), nil, "unit", {group = other}, true, false, true)
    self:ComboBox("Continent", callback(self, self, "set_unit_data"), self._parent._continents, 1, {group = other})
    self:Toggle("HideOnProjectionLight", callback(self, self, "set_unit_data"), false, {group = other})
    self:Toggle("DisableShadows", callback(self, self, "set_unit_data"), false, {group = other})
    self:Toggle("DisableCollision", callback(self, self, "set_unit_data"), false, {group = other})
    self:Toggle("DisableOnAIGraph", callback(self, self, "set_unit_data"), false, {group = other})
    self:build_extension_items()
end

function StaticEditor:build_extension_items()
    self._editors = {}
    for k, v in pairs({light = EditUnitLight, ladder = EditLadder, editable_gui = EditUnitEditableGui, zipline = EditZipLine, wire = EditWire, mesh_variation = EditMeshVariation, ai_data = EditAIData}) do
        self._editors[k] = v:new():is_editable(self)
    end
end

function StaticEditor:build_positions_items()
    self:build_quick_buttons()    
    local transform = self:Group("Transform")
    self:Button("IgnoreRaycastOnce", function()
        for _, unit in pairs(self:selected_units()) do
            if unit:unit_data().unit_id then
                self._ignore_raycast[unit:unit_data().unit_id] = true
            end
        end      
    end, {group = transform})
    self:AxisControls(callback(self, self, "set_unit_data"), {group = transform, step = self:Manager("opt")._menu:GetItem("GridSize"):Value()})
end

function StaticEditor:update_grid_size()
    self:set_unit()
end

function StaticEditor:deselect_unit(menu, item)
    self:set_unit(true)
end

function StaticEditor:update_positions()
    local unit = self._selected_units[1]
    if unit then
        if #self._selected_units > 1 or not unit:mission_element() then
            self:SetAxisControls(unit:position(), unit:rotation())
            if self:Manager("wdata").managers.env:is_env_unit(unit:name()) then
                self:Manager("wdata").managers.env:save()
            end
            for i, control in pairs(self._axis_controls) do
                self[control]:SetStep(i < 4 and self._parent._grid_size or self._parent._snap_rotation)
            end
        elseif unit:mission_element() and self:Manager("mission")._current_script then
            self:Manager("mission")._current_script:update_positions(unit:position(), unit:rotation())
        end      
    end
    for _, editor in pairs(self._editors) do
        if editor.update_positions then
            editor:update_positions(unit)
        end
    end    
    self:recalc_all_locals()
end

function StaticEditor:set_unit_data()
    self._parent:set_unit_positions(self:AxisControlsPosition())
    self._parent:set_unit_rotations(self:AxisControlsRotation())

    if #self._selected_units == 1 then    
        if not self:GetItem("Continent") then
            return
        end 
        local unit = self._selected_units[1]
        if unit:unit_data() and unit:unit_data().unit_id then
            local prev_id = unit:unit_data().unit_id
            local ud = unit:unit_data()
            managers.worlddefinition:set_name_id(unit, self:GetItem("Name"):Value())
            local old_continent = unit:unit_data().continent
            ud.continent = self:GetItem("Continent"):SelectedItem()
            local new_continent = unit:unit_data().continent
            local path_changed = unit:unit_data().name ~= self:GetItem("UnitPath"):Value()
            local u_path = self:GetItem("UnitPath"):Value()
            ud.name = (u_path and u_path ~= "" and u_path) or ud.name
            ud.unit_id = self:GetItem("Id"):Value()
            ud.disable_shadows = self:GetItem("DisableShadows"):Value()
            ud.disable_collision = self:GetItem("DisableCollision"):Value()
            ud.hide_on_projection_light = self:GetItem("HideOnProjectionLight"):Value()
            ud.disable_on_ai_graph = self:GetItem("DisableOnAIGraph"):Value()
            for _, editor in pairs(self._editors) do
                if editor.set_unit_data then
                    editor:set_unit_data()
                end
            end
            BeardLib.Utils:RemoveAllNumberIndexes(ud, true) --Custom xml issues happen in here also 😂🔫 

            ud.lights = BeardLibEditor.Utils:LightData(unit)
            ud.triggers = BeardLibEditor.Utils:TriggersData(unit)
            ud.editable_gui = BeardLibEditor.Utils:EditableGuiData(unit)
            ud.ladder = BeardLibEditor.Utils:LadderData(unit)
            ud.zipline = BeardLibEditor.Utils:ZiplineData(unit)
            unit:set_editor_id(ud.unit_id)
            managers.worlddefinition:set_unit(prev_id, unit, old_continent, new_continent)
            for index = 0, unit:num_bodies() - 1 do
                local body = unit:body(index)
                if body then
                    body:set_collisions_enabled(not ud.disable_collision)
                    body:set_collides_with_mover(not ud.disable_collision)
                end
            end       
            unit:set_shadows_disabled(unit:unit_data().disable_shadows)     
            if PackageManager:has(Idstring("unit"), Idstring(ud.name)) and path_changed then
                self._parent:SpawnUnit(ud.name, unit)                
                self._parent:DeleteUnit(unit)
            end
        end
    else            
        for _, unit in pairs(self._selected_units) do
            local ud = unit:unit_data()
            managers.worlddefinition:set_unit(ud.unit_id, unit, ud.continent, ud.continent)
        end
    end
end

function StaticEditor:StorePreviousPosRot()
    if #self._selected_units > 1 then
        for _, unit in pairs(self._selected_units) do
            unit:unit_data()._prev_pos = unit:position()
            unit:unit_data()._prev_rot = unit:rotation()
        end
    end
end

function StaticEditor:add_selection_to_prefabs(menu, item)
    BeardLibEditor.managers.InputDialog:Show({title = "Prefab Name", text = #self._selected_units == 1 and self._selected_units[1]:unit_data().name_id or "Prefab", callback = function(prefab_name)
        BeardLibEditor.Prefabs[prefab_name] = self:GetCopyData()
        FileIO:WriteScriptDataTo(BeardLib.Utils.Path:Combine(BeardLibEditor.PrefabsDirectory, prefab_name..".prefab"), BeardLibEditor.Prefabs[prefab_name], "binary")
    end})
end

function StaticEditor:mouse_moved(x, y)
    if self._mouse_hold then
        self:select_unit(true)
    end
end

function StaticEditor:mouse_released(button, x, y)
    self._mouse_hold = false
end

function StaticEditor:widget_unit()
    local unit = self:selected_unit()
    if alive(unit) and unit:unit_data().instance then
        local instance = managers.world_instance:get_instance_data_by_name(unit:unit_data().instance)
        self._fake_object = self._fake_object or FakeObject:new(instance)
        return self._fake_object
    end
    if self:Enabled() then
        for _, editor in pairs(self._editors) do
            if editor.widget_unit then
                return editor:widget_unit()
            end
        end
    end
    return nil
end

function StaticEditor:recalc_all_locals()
    if alive(self._selected_units[1]) then
        local reference = self._selected_units[1]
        reference:unit_data().local_pos = Vector3()
        reference:unit_data().local_rot = Rotation()
        for _, unit in pairs(self._selected_units) do
            if unit ~= reference then
                self:recalc_locals(unit, reference)
            end
        end
    end
end

function StaticEditor:recalc_locals(unit, reference)
    local pos = reference:position()
    local rot = reference:rotation()
    unit:unit_data().local_pos = unit:unit_data().position - pos --:rotate_with(rot:inverse()) Trying to improve widget rotation but sadly failing.
    unit:unit_data().local_rot = rot:inverse() * unit:rotation()
end

function StaticEditor:check_unit_ok(unit)
    local ud = unit:unit_data()
    if not ud then
        return false
    end
    if ud.unit_id and self._ignore_raycast[ud.unit_id] == true then
        self._ignore_raycast[ud.unit_id] = nil
        return false
    end
    local mission_element = unit:mission_element() and unit:mission_element().element
    local wanted_elements = self:Manager("opt")._wanted_elements
    if mission_element then    
        return BeardLibEditor.Options:GetValue("Map/ShowElements") and (#wanted_elements == 0 or table.get_key(wanted_elements, managers.mission:get_mission_element(mission_element).class))
    else
        return unit:visible()
    end
end

function StaticEditor:reset_selected_units()
    self:Manager("mission"):remove_script()
    self:Manager("wdata").managers.env:check_units()
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:mission_element() then unit:mission_element():unselect() end
    end
    self._fake_object = nil
    self._instance_units = nil
    self._selected_units = {}
end

function StaticEditor:set_selected_unit(unit, add)
    self:recalc_all_locals()
    local units = {unit}
    if alive(unit) and self:Manager("opt"):get_value("SelectEditorGroups") then
        local continent = managers.worlddefinition:get_continent_of_static(unit)
        if not add then
            add = true
            self:reset_selected_units()
        end
        if continent then
            continent.editor_groups = continent.editor_groups or {}
            for _, group in pairs(continent.editor_groups) do
                if group.units then
                    for _, unit_id in pairs(group.units) do
                        local u = managers.worlddefinition:get_unit(unit_id)
                        if alive(u) and not table.contains(units, u) then
                            table.insert(units, u)
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

    self:StorePreviousPosRot()
    local unit = self:selected_unit()
    self._parent:use_widgets(unit and alive(unit) and unit:enabled())
    if (alive(unit) and unit:unit_data().instance) or #self._selected_units > 1 then
        self:set_multi_selected()
    else
        if alive(unit) then
            if unit:mission_element() then
                self:Manager("mission"):set_element(unit:mission_element().element)
            elseif self:Manager("wdata").managers.env:is_env_unit(unit:name()) then
                self:Manager("wdata").managers.env:build_unit_menu()
            else
                self:set_unit()
            end
        else
            self:set_unit()
        end
    end 
end

local bain_ids = Idstring("units/payday2/characters/fps_mover/bain")

function StaticEditor:select_unit(mouse2)
    local ray = self._parent:select_unit_by_raycast(self._parent._editor_all, callback(self, self, "check_unit_ok"))
    self:recalc_all_locals()
	if ray then
        if alive(ray.unit) and ray.unit:name() ~= bain_ids then
            if not self._mouse_hold then
                self._parent:Log("Ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
            end
            self:set_selected_unit(ray.unit, mouse2) 
        end
	end
end

function StaticEditor:set_multi_selected()
    self._editors = {}
    self:ClearItems()
    self:build_positions_items()
    self:update_positions()
end

function StaticEditor:set_unit(reset)
    if reset then
        self:reset_selected_units()
    end
    local unit = self._selected_units[1]
    if alive(unit) and unit:unit_data() and not unit:mission_element() then
        if not reset then
            self:set_menu_unit(unit)
            return
        end
    end
    self:build_default_menu()
end

function StaticEditor:set_menu_unit(unit)   
    self:build_unit_editor_menu()
    self:GetItem("Name"):SetValue(unit:unit_data().name_id, false, true)
    self:GetItem("UnitPath"):SetValue(unit:unit_data().name, false, true)
    self:GetItem("Id"):SetValue(unit:unit_data().unit_id, false, true)
    self:GetItem("DisableShadows"):SetValue(unit:unit_data().disable_shadows, false, true)
    self:GetItem("DisableCollision"):SetValue(unit:unit_data().disable_collision, false, true)
    self:GetItem("HideOnProjectionLight"):SetValue(unit:unit_data().hide_on_projection_light, false, true)
    self:GetItem("DisableOnAIGraph"):SetValue(unit:unit_data().disable_on_ai_graph, false, true)
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
end

function StaticEditor:build_links(id, is_element)
    local links = managers.mission:get_links(id, is_element)
    if #links > 0 then
        local links_group = self:GetItem("Links") or self:Group("Links")
        for _, element in pairs(links) do
            self:Button(element.editor_name, callback(self._parent, self._parent, "select_element", element), {
                group = links_group, font_size = 16, label = "elements", text = tostring(element.editor_name) .. " | " .. tostring(element.id) .. " | " .. tostring(element.class):gsub("Element", "")
            })
        end
    end
    return links
end

function StaticEditor:addremove_unit_portal(menu, item)
    local portal = self:Manager("wdata")._selected_portal
    if portal then
        for _, unit in pairs(self._selected_units) do
            if unit:unit_data().unit_id then
                portal:add_unit_id(unit)
            end
        end
    else
        QuickMenuPlus:new("Error", "No portal selected")  
    end    
end      

function StaticEditor:delete_selected(menu, item)    
    for _, unit in pairs(self._selected_units) do
        self._parent:DeleteUnit(unit)
    end
    self:reset_selected_units()
    self:set_unit()      
end

function StaticEditor:delete_selected_dialog(menu, item)
    if not self:selected_unit() then
        return
    end        
    QuickMenuPlus:new("Warning", "This will delete the selection, Continue?",{
        {text = "Yes", callback = callback(self, self, "delete_selected")},
        {text = "No", is_cancel_button = true}
    })
end

function StaticEditor:update(t, dt)
    self.super.update(self, t, dt)
    for _, unit in pairs(self._nav_surfaces) do 
        Application:draw(unit, 0,0.8,1)
    end
    for _, editor in pairs(self._editors) do
        if editor.update then
            editor:update(t, dt)
        end
    end
    local color = BeardLibEditor.Options:GetValue("AccentColor"):with_alpha(1)
    self._pen:set(color)
    local draw_bodies = self:Value("DrawBodies")
    if managers.viewport:get_current_camera() then
        for _, unit in pairs(self._selected_units) do
            if alive(unit) then
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
end

function StaticEditor:GetCopyData()
    self:set_unit_data()
    local copy_data = {}    
    local id
    local unit_id
    for _, unit in pairs(self._selected_units) do
        local typ = unit:mission_element() and "element" or "unit"
        local copy = {
            type = typ,
            mission_element_data = typ == "element" and unit:mission_element().element and deep_clone(unit:mission_element().element) or nil,
            unit_data = typ == "unit" and unit:unit_data() and deep_clone(unit:unit_data()) or nil,
            wire_data = typ == "unit" and unit:wire_data() and deep_clone(unit:wire_data()) or nil,
            ai_editor_data = typ == "unit" and unit:ai_editor_data() and deep_clone(unit:ai_editor_data()) or nil
        }
        --Get smallest id
        if typ == "element" then
            id = math.min(copy.mission_element_data.id, id or copy.mission_element_data.id)
        elseif typ == "unit" then
            unit_id = math.min(copy.unit_data.unit_id, unit_id or copy.unit_data.unit_id)
        end
        table.insert(copy_data, copy)
    end

    --The id is now used as the number it should add to the latest id before spawning the prefab
    --Why we need to save ids? so elements can function even after copy pasting
    for _, v in pairs(copy_data) do
        local is_element = v.type == "element"
        local is_unit = v.type == "unit"
        if v.type == "element" and id then
            v.mission_element_data.script = nil
            local new_id = v.mission_element_data.id - id
            for _, link in pairs(managers.mission:get_links_paths(v.mission_element_data.id, true, copy_data)) do
                link.tbl[link.key] = 1000000 + new_id
            end
            v.mission_element_data.id = new_id
        elseif v.type == "unit" and unit_id then
            v.unit_data.continent = nil
            local new_id = v.unit_data.unit_id - unit_id
            for _, link in pairs(managers.mission:get_links_paths(v.unit_data.unit_id, false, copy_data)) do
                link.tbl[link.key] = 1000000 + new_id
            end
            v.unit_data.unit_id = new_id
        end
    end
    return copy_data
end

function StaticEditor:CopySelection()
    if #self._selected_units > 0 and not self._parent._menu._highlighted then
        self._copy_data = self:GetCopyData() --Sadly thanks for ovk's "crash at all cost" coding I cannot use script converter because it would crash.
    end
end

function StaticEditor:Paste()
    if not self._parent._menu._highlighted and self._copy_data then
        self:SpawnCopyData(self._copy_data)
    end
end

function StaticEditor:SpawnPrefab(prefab)
    self:SpawnCopyData(prefab)
    if self.x then
        local cam = managers.viewport:get_current_camera()
        self:SetAxisControls(cam:position() + cam:rotation():y(), self:AxisControlsRotation())
        self:set_unit_data()
    end
end

function StaticEditor:SpawnCopyData(copy_data)
    self:reset_selected_units()
    local new_id = managers.mission:get_new_id(self._parent._current_continent)
    local new_unit_id = managers.worlddefinition:GetNewUnitID(self._parent._current_continent, "")
    local new_world_unit_id = managers.worlddefinition:GetNewUnitID(self._parent._current_continent, "wire")
    for _, v in pairs(copy_data) do
        local is_element = v.type == "element"
        local is_unit = v.type == "unit"
        if v.type == "element" then
            local new_final_id = new_id + v.mission_element_data.id
            for _, link in pairs(managers.mission:get_links_paths(1000000 + v.mission_element_data.id, true, copy_data)) do
                link.tbl[link.key] = new_final_id
            end
            v.mission_element_data.id = new_final_id
        elseif v.type == "unit" and unit_id then
            local new_final_id = (old_unit:wire_data() or old_unit:ai_editor_data() and new_world_unit_id or new_unit_id) + v.unit_data.unit_id
            for _, link in pairs(managers.mission:get_links_paths(1000000 + v.unit_data.unit_id, false, copy_data)) do
                link.tbl[link.key] = new_final_id
            end
            v.unit_data.unit_id = new_final_id
        end
    end
    for _, v in pairs(copy_data) do
        if v.type == "element" then
            self:Manager("mission"):add_element(v.mission_element_data.class, true, v.mission_element_data)
        elseif v.unit_data then
            self._parent:SpawnUnit(v.unit_data.name, v, true)
        end
    end
    self:StorePreviousPosRot()
end

function StaticEditor:Clone()
    self:CopySelection()
    self:Paste()
end

function StaticEditor:KeyFPressed()
    if self._selected_units[1] then
        self._parent:set_camera(self._selected_units[1]:position())
    end
end

function StaticEditor:set_unit_enabled(enabled)
	for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            unit:set_enabled(enabled)
        end
	end
end