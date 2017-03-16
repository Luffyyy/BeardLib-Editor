StaticEditor = StaticEditor or class(EditorPart)
function StaticEditor:init(parent, menu)
    StaticEditor.super.init(self, parent, menu, "StaticEditor")
    self._selected_units = {}
    self._disabled_units = {}
    self._nav_surfaces = {}
    self._nav_surface = Idstring("core/units/nav_surface/nav_surface")
    self._widget_slot_mask = World:make_slot_mask(1)
end

function StaticEditor:enable()
    self:bind("delete", callback(self, self, "delete_selected_dialog"))
    self:bind("c", callback(self, self, "KeyCPressed"))
    self:bind("v", callback(self, self, "KeyVPressed"))
    self:bind("f", callback(self, self, "KeyFPressed"))
    local menu = self:Manager("menu")
    self:bind("r", callback(menu, menu, "toggle_rotation_widget"))
    self:bind("t", callback(menu, menu, "toggle_move_widget"))
end

function StaticEditor:build_default_menu()
    StaticEditor.super.build_default_menu(self)
    self._editors = {}    
    self:Divider("No Selection")
end

function StaticEditor:build_quick_buttons()
    local quick_buttons = self:Group("QuickButtons")
    self:Button("Deselect unit(s)", callback(self, self, "deselect_unit"), {group = quick_buttons})
    self:Button("Delete unit(s)", callback(self, self, "delete_selected_dialog"), {group = quick_buttons})
    self:Button("Add unit(s) to prefabs", callback(self, self, "add_units_to_prefabs"), {group = quick_buttons})
    self:Button("Add to/Remove from portal", callback(self, self, "addremove_unit_portal"), {group = quick_buttons})
end

function StaticEditor:build_unit_editor_menu()
    StaticEditor.super.build_default_menu(self)
    self._editors = {}
    local other = self:Group("Main")    
    self:build_positions_items()
    self:TextBox("Name", callback(self, self, "set_unit_data"), "", {group = other})
    self:TextBox("Id", callback(self, self, "set_unit_data"), "", {group = other})
    self:TextBox("UnitPath", callback(self, self, "set_unit_data"), "", {group = other})
    self:ComboBox("Continent", callback(self, self, "set_unit_data"), self._parent._continents, 1, {group = other})
    self:Toggle("HideOnProjectionLight", callback(self, self, "set_unit_data"), false, {group = other})
    self:Toggle("DisableShadows", callback(self, self, "set_unit_data"), false, {group = other})
    self:Toggle("DisableCollision", callback(self, self, "set_unit_data"), false, {group = other})
    self:Toggle("DisableOnAIGraph", callback(self, self, "set_unit_data"), false, {group = other})
    self:Button("SelectUnitPath", callback(self, SpawnSelect, "OpenSpawnUnitDialog", {
        on_click = function(unit_path)
            self._menu:GetItem("UnitPath"):SetValue(unit_path)
            self:set_unit_data()      
        end,
    }), {group = other})
    self:build_extension_items()
    local links = self:Group("Links")
end

function StaticEditor:build_extension_items()
    for k, v in pairs({light = EditUnitLight, ladder = EditLadder, editable_gui = EditUnitEditableGui, zipline = EditZipLine, wire = EditWire, mesh_variation = EditMeshVariation, ai_data = EditAIData}) do
        self._editors[k] = v:new():is_editable(self)
    end
end

function StaticEditor:build_positions_items()
    self:build_quick_buttons()    
    local transform = self:Group("Transform")
    self:AxisControls(callback(self, self, "set_unit_data"), {group = transform, step = self:Manager("opt")._menu:GetItem("GridSize"):Value()})
end

function StaticEditor:update_grid_size()
    self:set_unit()
end

function StaticEditor:deselect_unit(menu, item)
    self:set_unit(true)
end

function StaticEditor:update_positions(menu, item)
    local unit = self._selected_units[1]
    if unit then
        if #self._selected_units > 1 or not unit:mission_element() then
            self:SetAxisControls(unit:position(), unit:rotation())
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
        local unit = self._selected_units[1]
        if unit:unit_data() and unit:unit_data().unit_id then
            local prev_id = unit:unit_data().unit_id
            local ud = unit:unit_data()
            managers.worlddefinition:set_name_id(unit, self._menu:GetItem("Name"):Value())
            local old_continent = unit:unit_data().continent
            ud.continent = self._menu:GetItem("Continent"):SelectedItem()
            local new_continent = unit:unit_data().continent
            local path_changed = unit:unit_data().name ~= self._menu:GetItem("UnitPath"):Value()
            local u_path = self._menu:GetItem("UnitPath"):Value()
            ud.name = (u_path and u_path ~= "" and u_path) or ud.name
            ud.unit_id = self._menu:GetItem("Id"):Value()
            ud.disable_shadows = self._menu:GetItem("DisableShadows"):Value()
            ud.disable_collision = self._menu:GetItem("DisableCollision"):Value()
            ud.hide_on_projection_light = self._menu:GetItem("HideOnProjectionLight"):Value()
            ud.disable_on_ai_graph = self._menu:GetItem("DisableOnAIGraph"):Value()

            ud.lights = BeardLibEditor.Utils:LightData(unit)
            ud.triggers = BeardLibEditor.Utils:TriggersData(unit)
            ud.editable_gui = BeardLibEditor.Utils:EditableGuiData(unit)
            ud.ladder = BeardLibEditor.Utils:LadderData(unit)
            ud.zipline = BeardLibEditor.Utils:ZiplineData(unit)
            unit:set_editor_id(ud.unit_id)           
            for _, editor in pairs(self._editors) do
                if editor.set_unit_data then
                    editor:set_unit_data()
                end
            end            
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
    for _, unit in pairs(self._selected_units) do
        unit:unit_data()._prev_pos = unit:position()
        unit:unit_data()._prev_rot = unit:rotation()
    end
end

function StaticEditor:add_units_to_prefabs(menu, item)
    BeardLibEditor.managers.Dialog:show({
        title = "Add new prefab",
        items = {
            {
                type = "TextBox",
                name = "prefab_name",
                text = "Name",
                value = #self._selected_units == 1 and self._selected_units[1]:unit_data().name_id or "Prefab",
            },           
            {
                type = "Toggle",
                name = "save_prefab",
                text = "Save",
                value = true,
            }
        },
        yes = "Add",
        no = "Cancel",
        callback = function(items)
            local prefab = {
                name = items[1]:Value(),
                units = {},
            }
            for _, unit in pairs(self._selected_units) do
                table.insert(prefab.units, unit:unit_data())
            end
            table.insert(BeardLibEditor.Options._storage.Prefabs, {_meta = "option", name = #BeardLibEditor.Options._storage.Prefabs + 1, value = prefab})
            BeardLibEditor.Options:Save()
        end,
        w = 600,
        h = 200,
    })    
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
                    if (alt() and not ctrl()) then self:clone() end
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

function StaticEditor:mouse_moved(x, y)
    if self._mouse_hold then
        self:select_unit(true)
    end
end

function StaticEditor:mouse_released(button, x, y)
    self._mouse_hold = false
end

function StaticEditor:widget_unit()
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
        reference:unit_data().local_pos = Vector3(0, 0, 0)
        reference:unit_data().local_rot = Rotation(0, 0, 0)
        for _, unit in ipairs(self._selected_units) do
            if unit ~= reference then
                self:recalc_locals(unit, reference)
            end
        end
    end
end

function StaticEditor:recalc_locals(unit, reference)
    local pos = reference:position()
    local rot = reference:rotation()
    unit:unit_data().local_pos = unit:unit_data().position - pos 
    unit:unit_data().local_rot = rot:inverse() * unit:rotation()
end

function StaticEditor:check_unit_ok(unit)
    if not unit:unit_data() then
        return false
    end
    local mission_element = unit:mission_element() and unit:mission_element().element
    local wanted_elements = self:Manager("opt")._wanted_elements
    if mission_element then    
        return BeardLibEditor.Options:GetOption("Map/ShowElements").value and (#wanted_elements == 0 or table.get_key(wanted_elements, managers.mission:get_mission_element(mission_element).class))
    else
        return unit:visible()
    end
end

function StaticEditor:set_selected_unit(unit, add)
    self:recalc_all_locals()
    if add then
        if not table.contains(self._selected_units, unit) then
            table.insert(self._selected_units, unit)
        elseif not self._mouse_hold then
            table.delete(self._selected_units, unit)
        end
    else
        self._selected_units = {}
        self._selected_units[1] = unit
    end
    self:StorePreviousPosRot()
    local unit = self._selected_units[1]
    self._parent:use_widgets(unit and alive(unit))          
    if #self._selected_units > 1 then
        self:set_multi_selected()    
    else
        if alive(unit) and unit:mission_element() then
            self:Manager("mission"):set_element(unit:mission_element().element)
        else
            self:set_unit()
        end
    end 
end

function StaticEditor:select_unit(mouse2)
    local ray = self._parent:select_unit_by_raycast(self._parent._editor_all, callback(self, self, "check_unit_ok"))
    self:recalc_all_locals()
	if ray then
        if not self._mouse_hold then
			self._parent:Log("Ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
        end
        self:set_selected_unit(ray.unit, mouse2) 
	end
end

function StaticEditor:set_multi_selected()
    self._editors = {}
    self._menu:ClearItems()  
    self:build_positions_items()
    self:update_positions()
end

function StaticEditor:set_unit(reset)
    if reset then
        self._selected_units = {}
    end
    local unit = self._selected_units[1]
    if not reset and alive(unit) then
        self:set_menu_unit(unit)
    else
        self:build_default_menu() 
    end
end

function StaticEditor:set_menu_unit(unit)   
    self:build_unit_editor_menu()
    self._menu:GetItem("Name"):SetValue(unit:unit_data().name_id, false, true)
    self._menu:GetItem("UnitPath"):SetValue(unit:unit_data().name, false, true)
    self._menu:GetItem("Id"):SetValue(unit:unit_data().unit_id, false, true)
    self._menu:GetItem("DisableShadows"):SetValue(unit:unit_data().disable_shadows, false, true)
    self._menu:GetItem("DisableCollision"):SetValue(unit:unit_data().disable_collision, false, true)
    self._menu:GetItem("HideOnProjectionLight"):SetValue(unit:unit_data().hide_on_projection_light, false, true)
    self._menu:GetItem("DisableOnAIGraph"):SetValue(unit:unit_data().disable_on_ai_graph, false, true)
    for _, editor in pairs(self._editors) do
        if editor.set_menu_unit then
            editor:set_menu_unit(unit)
        end
    end
    self:update_positions()
    self._menu:GetItem("Continent"):SetSelectedItem(unit:unit_data().continent)
    local not_w_unit = not (unit:wire_data() or unit:ai_editor_data())
    self._menu:GetItem("Continent"):SetEnabled(not_w_unit)
    self._menu:GetItem("UnitPath"):SetEnabled(not_w_unit)
    self._menu:GetItem("SelectUnitPath"):SetEnabled(not_w_unit)
    for _, element in pairs(managers.mission:get_links(unit:unit_data().unit_id)) do
        self._menu:Button({
            name = element.editor_name,
            text = element.editor_name .. " [" .. (element.class or "") .."]",
            label = "elements",
            items_size = 14,
            group = self._menu:GetItem("Links"),
            callback = callback(self._parent, self._parent, "select_element", element)
        })
    end
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
        QuickMenu:new( "Error", "No portal selected.", {{text = "ok", is_cancel_button = true}}, true)  
    end    
end      

function StaticEditor:delete_selected(menu, item)    
    for _, unit in pairs(self._selected_units) do
        self._parent:DeleteUnit(unit)
    end
    self._selected_units = {}
    self:set_unit()      
end

function StaticEditor:delete_selected_dialog(menu, item)                    
    QuickMenu:new("Warning", "This will delete the selected unit(s)/element(s), Continue?",
        {[1] = {text = "Yes", callback = callback(self, self, "delete_selected")
    },[2] = {text = "No", is_cancel_button = true}}, true)    
end

function StaticEditor:update(t, dt)
    for _, unit in pairs(self._nav_surfaces) do 
        Application:draw(unit, 0,0.8,1) 
    end
    for _, editor in pairs(self._editors) do
        if editor.update then
            editor:update(t, dt)
        end
    end
    if managers.viewport:get_current_camera() then
        if #self._selected_units > 0 then
            self._brush:set_font(Idstring("core/fonts/nice_editor_font"), 24)
            self._brush:set_render_template(Idstring("OverlayVertexColorTextured"))
            for _, unit in ipairs(self._selected_units) do
                if alive(unit) then
                    if unit:name() == self._nav_surface then
                        Application:draw(unit, 1,0.2,0)
                    end
                    local num = unit:num_bodies()
                    for i = 0, num - 1 do
                        local body = unit:body(i)
                        if self._parent:_should_draw_body(body) then
                            self._pen:set(Color(0, 0.5, 1))
                            self._pen:body(body)
                            self._brush:set_color(Color(0, 0.5, 1))
                        end                            
                    end
                end
            end
            return
        end
    end
end

function StaticEditor:KeyCPressed(button_index, button_name, controller_index, controller, trigger_id)
    if ctrl() and #self._selected_units > 0 and not self._parent._menu._highlighted then
        self:set_unit_data()
        local all_unit_data = {}
        for _, unit in pairs(self._selected_units) do
            table.insert(all_unit_data, {
                unit_data = unit:unit_data(),
                wire_data = unit:wire_data(),
                ai_editor_data = unit:ai_editor_data()
            })
        end
        Application:set_clipboard(json.custom_encode(all_unit_data))
    end
end

function StaticEditor:KeyVPressed(button_index, button_name, controller_index, controller, trigger_id)
    if ctrl() and not self._parent._menu._highlighted then
        local ret, data = pcall(function() return json.custom_decode(Application:get_clipboard()) end)
        if ret and type(data) == "table" then
            self._selected_units = {}
            for _, sub_data in pairs(data) do
                self._parent:SpawnUnit(sub_data.unit_data.name, sub_data, true)
            end

            if #self._selected_units > 1 then
                self:StorePreviousPosRot()
            end
        else
            log(tostring(data))
        end
    end
end

function StaticEditor:clone()
    if #self._selected_units > 1 then
        self:StorePreviousPosRot()
    end
    self:set_unit_data()
    local all_unit_data = clone(self._selected_units)
    self._selected_units = {}
    for _, unit in pairs(all_unit_data) do
        self._parent:SpawnUnit(unit:unit_data().name, unit, true)
        if #self._selected_units > 1 then
            self:StorePreviousPosRot()
        end 
    end
end

function StaticEditor:KeyFPressed(button_index, button_name, controller_index, controller, trigger_id)
    if Input:keyboard():down(Idstring("left ctrl")) then
        if self._selected_units[1] then
            self._parent:set_camera(self._selected_units[1]:position())
        end
	end
end

function StaticEditor:set_unit_enabled(enabled)
	for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            unit:set_enabled(enabled)
        end
	end
end

 