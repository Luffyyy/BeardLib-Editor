StaticEditor = StaticEditor or class(EditorPart)
function StaticEditor:init(parent, menu)
    self.super.init(self, parent, menu, "StaticEditor")
    self._selected_units = {}
    self._disabled_units = {}
    self._nav_surfaces = {}
    self._nav_surface = Idstring("core/units/nav_surface/nav_surface")
    self._widget_slot_mask = World:make_slot_mask(1)
end

function StaticEditor:enable()
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("delete"), callback(self, self, "delete_selected")))
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("c"), callback(self, self, "KeyCPressed")))
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("v"), callback(self, self, "KeyVPressed")))
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("f"), callback(self, self, "KeyFPressed")))
end

function StaticEditor:build_default_menu()
    self.super.build_default_menu(self)
    self._editors = {}    
    self:Divider("No Selection")
end

function StaticEditor:build_quick_buttons()
    local quick_buttons = self:Group("QuickButtons")
    self:Button("Deselect unit(s)", callback(self, self, "deselect_unit"), {group = quick_buttons})
    self:Button("Delete unit(s)", callback(self, self, "delete_selected"), {group = quick_buttons})
    self:Button("Add unit(s) to prefabs", callback(self, self, "add_units_to_prefabs"), {group = quick_buttons})
    self:Button("Add to/Remove from portal", callback(self, self, "addremove_unit_portal"), {group = quick_buttons})
end

function StaticEditor:build_unit_editor_menu()
    self.super.build_default_menu(self)
    self._editors = {}
    local other = self:Group("Main")    
    self:build_positions_items()
    self:TextBox("Name", callback(self, self, "set_unit_data"), "", {group = other})
    self:TextBox("Id", callback(self, self, "set_unit_data"), "", {group = other})
    self:ComboBox("MeshVariation", callback(self, self, "set_unit_data"), {}, 1, {group = other})
    self:ComboBox("Continent", callback(self, self, "set_unit_data"), self._parent._continents, 1, {group = other})
    self:TextBox("UnitPath", callback(self, self, "set_unit_data"), "", {group = other})
    self:Button("SelectUnitPath", callback(self, SpawnSelect, "OpenSpawnUnitDialog", function()
        self._menu:GetItem("UnitPath"):SetValue(unit_path)
        self:set_unit_data()      
    end), {group = other})
    for k, v in pairs({light = EditUnitLight, ladder = EditLadder, editable_gui = EditUnitEditableGui, zipline = EditZipLine}) do
        self._editors[k] = v:new():is_editable(self)
    end
    local links = self:Group("Links")
end

function StaticEditor:build_positions_items()
    self:build_quick_buttons()    
    local transform = self:Group("Transform")
    for _, control in pairs({"position_x", "position_y", "position_z", "rotation_yaw", "rotation_pitch", "rotation_roll"}) do
        self[control] = self:NumberBox(string.pretty(control, true), callback(self, self, "set_unit_data"), 0, {group = transform, step = self:Manager("GameOptions")._menu:GetItem("GridSize").value})
    end
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
            self.position_x:SetValue(unit:position().x or 10, false, true)
            self.position_y:SetValue(unit:position().y or 10, false, true)
            self.position_z:SetValue(unit:position().z or 10, false, true)
            self.rotation_yaw:SetValue(unit:rotation():yaw() or 10, false, true)
            self.rotation_pitch:SetValue(unit:rotation():pitch() or 10, false, true)
            self.rotation_roll:SetValue(unit:rotation():roll() or 10, false, true) 
            self.position_x:SetStep(self._parent._grid_size)
            self.position_y:SetStep(self._parent._grid_size)
            self.position_z:SetStep(self._parent._grid_size)
        elseif unit:mission_element() and self._parent.managers.ElementEditor._current_script then
            self._parent.managers.ElementEditor._current_script:update_positions(unit:position(), unit:rotation())
        end      
    end
    self:recalc_all_locals()
end

function StaticEditor:set_unit_data()
    self._parent:set_unit_positions(Vector3(self.position_x.value, self.position_y.value, self.position_z.value))
    self._parent:set_unit_rotations(Rotation(self.rotation_yaw.value, self.rotation_pitch.value, self.rotation_roll.value))  
    if #self._selected_units == 1 then
        local unit = self._selected_units[1]
        if unit:unit_data() and unit:unit_data().unit_id then
            local prev_id = unit:unit_data().unit_id
            local ud = unit:unit_data()
            managers.worlddefinition:set_name_id(unit, self._menu:GetItem("Name").value)
            local mesh_variations = managers.sequence:get_editable_state_sequence_list(unit:name()) or {}
            ud.mesh_variation = mesh_variations[self._menu:GetItem("MeshVariation").value]
            local mesh_variation = unit:unit_data().mesh_variation
            if mesh_variation and mesh_variation ~= "" then
                managers.sequence:run_sequence_simple2(mesh_variation, "change_state", unit)
            end
            local old_continent = unit:unit_data().continent
            ud.continent = self._menu:GetItem("Continent"):SelectedItem()
            local new_continent = unit:unit_data().continent
            local path_changed = unit:unit_data().name ~= self._menu:GetItem("UnitPath").value

            ud.name = self._menu:GetItem("UnitPath").value
            ud.unit_id = self._menu:GetItem("Id").value

            ud.lights = BeardLibEditor.Utils:LightData(unit)
            ud.triggers = BeardLibEditor.Utils:TriggersData(unit)
            ud.editable_gui = BeardLibEditor.Utils:EditableGuiData(unit)
            ud.ladder = BeardLibEditor.Utils:LadderData(unit)
            ud.zipline = BeardLibEditor.Utils:ZiplineData(unit)
            unit:set_editor_id(ud.unit_id)
            managers.worlddefinition:set_unit(prev_id, ud, old_continent, new_continent)
            if PackageManager:has(Idstring("unit"), Idstring(ud.name)) and path_changed then
                self:delete_selected()
                self._parent:SpawnUnit(ud.name, ud, false, true)
            end
        end
    else            
        for _, unit in pairs(self._selected_units) do
            local ud = unit:unit_data()
            managers.worlddefinition:set_unit(ud.unit_id, ud, unit:unit_data().continent, ud.continent)
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
                name = items[1].value,
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

function StaticEditor:select_widget()
    self._parent:reset_widget_values()
    local from = self._parent:get_cursor_look_point(0)
    local to = self._parent:get_cursor_look_point(100000)
    if self._selected_units[1] then
        if self._parent._move_widget:enabled() then
            local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._move_widget:widget())
            if ray and ray.body then
                if alt() then self:clone() end
                self._parent._move_widget:add_move_widget_axis(ray.body:name():s())      
                self._parent._move_widget:set_move_widget_offset(self._selected_units[1], self._selected_units[1]:rotation())
                self._parent._using_move_widget = true
                return true
            end
        end
        if self._parent._rotate_widget:enabled() then
            local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._rotate_widget:widget())
            if ray and ray.body then
                self._parent._rotate_widget:set_rotate_widget_axis(ray.body:name():s())
                self._parent._rotate_widget:set_world_dir(ray.position)
                self._parent._rotate_widget:set_rotate_widget_start_screen_position(self._parent:world_to_screen(ray.position):with_z(0))
                self._parent._rotate_widget:set_rotate_widget_unit_rot(self._selected_units[1]:rotation())
                self._parent._using_rotate_widget = true
                return true
            end
        end         
    end  
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
    local wanted_elements = self._parent.managers.GameOptions._wanted_elements
    if mission_element then    
        if BeardLibEditor.Options:GetOption("Map/ShowElements").value and (#wanted_elements == 0 or table.get_key(wanted_elements, managers.mission:get_mission_element(mission_element).class)) then
            return true
        else
            return false
        end
    elseif unit:visible() then
        return true
    else
        return false
    end
end

function StaticEditor:set_selected_unit(unit, add)
    self:recalc_all_locals()
    if add then
        if not table.contains(self._selected_units, unit) then
            table.insert(self._selected_units, unit)
        elseif not self._parent._mouse_hold then
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
            self:Manager("ElementEditor"):set_element(unit:mission_element().element)
        else
            self:set_unit()
        end
    end 
end

function StaticEditor:select_unit(mouse2)
	local ray
    for _, r in pairs(World:raycast_all("ray", self._parent:get_cursor_look_point(0), self._parent:get_cursor_look_point(200000), "ray_type", "body editor walk", "slot_mask", self._parent._editor_all)) do
    	if self:check_unit_ok(r.unit) then 
    		ray = r
    		break
    	end
    end
    self:recalc_all_locals()
	if ray then
        if not self._parent._mouse_hold then
			self._parent:Log("Ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
        end
        self:set_selected_unit(ray.unit, mouse2) 
	end
end

function StaticEditor:set_multi_selected()
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
        self:build_unit_editor_menu()
        self._menu:GetItem("Name"):SetValue(unit:unit_data().name_id, false, true)
        self._menu:GetItem("UnitPath"):SetValue(unit:unit_data().name, false, true)
        self._menu:GetItem("Id"):SetValue(unit:unit_data().unit_id, false, true)
        local Mesh = self._menu:GetItem("MeshVariation")
        if alive(unit) then
            local variations = managers.sequence:get_editable_state_sequence_list(unit:name())
            local enabled = #variations > 1
            Mesh:SetEnabled(enabled)
            if enabled then 
                Mesh:SetItems(variations)
                Mesh:SetValue(table.get_key(variations, unit:unit_data().mesh_variation))     
            end
        end
        self:update_positions()
        self._selected = self._selected_units
        self._menu:GetItem("Continent"):SetSelectedItem(unit:unit_data().continent)
        for _, element in pairs(managers.mission:get_links(unit:unit_data().unit_id)) do
            self._menu:Button({
                name = element.editor_name,
                text = element.editor_name .. " [" .. (element.class or "") .."]",
                label = "elements",
                items_size = 14,
                group = self._menu:GetItem("Links"),
                callback = callback(self._parent, self._parent, "_select_element", element)
            })
        end
    else
        self:build_default_menu() 
    end
end

function StaticEditor:addremove_unit_portal(menu, item)        
    local portal = self._parent.managers.WorldDataEditor._selected_portal
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
    QuickMenu:new("Warning", "This will delete the selected unit(s)/element(s), Continue?",
        {[1] = {text = "Yes", callback = function()
            for _, unit in pairs(self._selected_units) do
                if alive(unit) then
                    if unit:mission_element() then
                        managers.mission:delete_element(unit:mission_element().element.id)
                    end
                    managers.worlddefinition:delete_unit(unit)
                    World:delete_unit(unit)
                end
            end
            self._selected_units = {}
            self:set_unit()            
        end
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
            table.insert(all_unit_data, unit:unit_data())
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
                self._parent:SpawnUnit(sub_data.name, sub_data, true)
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
        self._parent:SpawnUnit(unit:unit_data().name, clone(unit:unit_data()), true)
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

 