UnitEditor = UnitEditor or class()

function UnitEditor:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "selected_menu",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,        
        visible = true,
        w = 300,
    })    
    self._menu:SetSize(nil, self._menu:Panel():h() - 42)    
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom()) 
    self._parent._current_menu = self._menu
    self._widget_slot_mask = World:make_slot_mask(1)
    self._selected_units = {}
    self._disabled_units = {}
    self:build_default_menu()

    self._trigger_ids = {}
end

function UnitEditor:enabled()
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("delete"), callback(self, self, "delete_selected")))
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("c"), callback(self, self, "KeyCPressed")))
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("v"), callback(self, self, "KeyVPressed")))
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("f"), callback(self, self, "KeyFPressed")))
end

function UnitEditor:disabled()
    for _, id in pairs(self._trigger_ids) do
        Input:keyboard():remove_trigger(id)
    end

    self._trigger_ids = {}
end

function UnitEditor:build_default_menu()
    self._menu:ClearItems()
    self._menu:Divider({
        name = "no_unit",
        text = "No selection",
    })
    self._menu:Button({
        name = "select_exisiting_unit",
        text = "Select existing unit",
        callback = callback(self, self, "select_exisiting_unit")
    })        
    local element_editor = self._parent.managers.ElementEditor
    self._menu:Button({
        name = "select_exisiting_element",
        text = "Select existing element",
        callback = callback(element_editor, element_editor, "select_exisiting_elmenet")
    })    
    self._menu:Button({
        name = "create_new_unit",
        text = "Spawn a new unit",
        callback = callback(self, self, "spawn_new_unit")
    })
    self._menu:Button({
        name = "create_new_elmenet",
        text = "Create new element",
        callback = callback(element_editor, element_editor, "create_new_elmenet")
    })
end
function UnitEditor:select_exisiting_unit()
    self._parent.managers.SpawnSearch:load_all_units()    
end
function UnitEditor:spawn_new_unit()
    self._parent.managers.SpawnSearch:browse()
end
function UnitEditor:build_quick_buttons()
    local quick_buttons = self:Group("quick_buttons")
    self:Button("deselect_unit", quick_buttons, callback(self, self, "deselect_unit"), "Deselect unit(s)")
    self:Button("delete_selected", quick_buttons, callback(self, self, "delete_selected"), "Delete unit(s)")
    self:Button("add_units_to_prefabs", quick_buttons, callback(self, self, "add_units_to_prefabs"), "Add unit(s) to prefabs")
    self:Button("portal_button", quick_buttons, callback(self, self, "addremove_unit_portal"), "Add to/Remove from portal")
end
function UnitEditor:build_unit_editor_menu()
    self._menu:ClearItems()  
    local other = self:Group("other")    
    self:build_positions_items()
    self:TextBox("name", other, callback(self, self, "set_unit_data"), "")
    self:TextBox("id", other, callback(self, self, "set_unit_data"), "")
    self:ComboBox("mesh_variation", other, callback(self, self, "set_unit_data"), {}, 1)
    self:ComboBox("continent", other, callback(self, self, "set_unit_data"), self._continents, 1)
    self:TextBox("unit_path", other, callback(self, self, "set_unit_data"), "")
    self:Button("select_unit_path", other, callback(self, self, "select_unit_dialog"))
    local links = self:Group("links")
end
function UnitEditor:build_positions_items()
    self:build_quick_buttons()    
    local transform = self:Group("unit_transform")
    self._axis_controls = {"position_x", "position_y", "position_z", "rotation_yaw", "rotation_pitch", "rotation_roll"}
    for _, control in pairs(self._axis_controls) do
        self[control] = self._menu:NumberBox({
            name = control,
            text = string.pretty(control, true),
            step = self._parent.managers.GameOptions._menu:GetItem("grid_Size").value,
            value = 0,
            group = transform,
            callback = callback(self, self, "set_unit_data"),
        })
    end
end
function UnitEditor:update_grid_size()
    self:set_unit()
end

function UnitEditor:select_unit_dialog()
    BeardLibEditor.managers.Dialog:show({
        title = "Select unit",
        items = {},
        yes = "Close",
        w = 600,
        h = 600,
    })
    self:browse()
end
 
function UnitEditor:browse()
    local menu = BeardLibEditor.managers.Dialog._menu
    menu:ClearItems("main")
    menu:ClearItems("temp")
    menu:ClearItems("temp2")
    self.current_dir = self.current_dir or ""
    local dir_split = string.split(self.current_dir, "/")

    local dir_tbl = BeardLibEditor.DBEntries
    for _, part in pairs(dir_split) do
        dir_tbl = dir_tbl[part]
    end
    local show_not_loaded = menu:GetItem("show_not_loaded") or menu:Toggle({
        name = "show_not_loaded",
        text = "Show not loaded units",
        value = false,
        callback = callback(self, self, "browse"),
    })    
    menu:Button({
        name = "uplevel_btn",
        text = "^ ( " .. (self.current_dir or self.custom_dir) .. " )",
        callback = callback(self, SpawnSearch, "folder_back"),
        label = "temp2"
    })
    menu:Button({
        name = "search_btn",
        text = "Search",
        callback = callback(self, SpawnSearch, "file_search"),
        label = "temp2"
    })            

    for key, data in pairs(dir_tbl) do
        if tonumber(key) ~= nil then
            if data.file_type == "unit" and (PackageManager:has(Idstring("unit"), Idstring(data.path)) or show_not_loaded.value) then
                menu:Button({
                    name = data.name,
                    text = data.name .. "." .. data.file_type,
                    label = "temp",
                    path = data.path,
                    color = PackageManager:has(Idstring("unit"), Idstring(data.path)) and Color.green or Color.red,
                    callback = callback(self, self, "file_click", data.path),
                })
            end
        else
            menu:Button({
                name = key,
                text = key,
                label = "temp",
                callback = callback(self, SpawnSearch, "folder_click"),
            })
        end
    end
end
function UnitEditor:search(success, search)
    local menu = BeardLibEditor.managers.Dialog._menu    
    if not success then
        return
    end    
    if not search or search == "" then
        return
    end

    if not self._is_searching then
        menu:ClearItems("temp")
        self._is_searching = true
    end
    for _, unit_path in pairs(BeardLibEditor.DBPaths["unit"]) do
        local split = string.split(unit_path, "/")
        local unit = split[#split]
        if unit:match(search) and (PackageManager:has(Idstring("unit"), Idstring(unit_path)) or menu:GetItem("show_not_loaded").value) then
            menu:Button({
                name = unit,
                text = unit,   
                path = unit_path,
                label = "temp",
                color = PackageManager:has(Idstring("unit"), Idstring(unit_path)) and Color.green or Color.red,
                callback = callback(self, self, "file_click", unit_path),
            })
        end
    end
end

function UnitEditor:file_click(unit_path)
    BeardLibEditor.managers.Dialog:hide()
    self._menu:GetItem("unit_path"):SetValue(unit_path)
    self:set_unit_data()
end
function UnitEditor:deselect_unit(menu, item)
    self:set_unit(true)
end

function UnitEditor:update_positions(menu, item)
    local unit = self._selected_units[1]
    if unit then
        if #self._selected_units > 1 or not unit:unit_data().mission_element then
            self.position_x:SetValue(unit:position().x or 10, false, true)
            self.position_y:SetValue(unit:position().y or 10, false, true)
            self.position_z:SetValue(unit:position().z or 10, false, true)
            self.rotation_yaw:SetValue(unit:rotation():yaw() or 10, false, true)
            self.rotation_pitch:SetValue(unit:rotation():pitch() or 10, false, true)
            self.rotation_roll:SetValue(unit:rotation():roll() or 10, false, true) 
            log(string.format("%.2f", Application:time()) .. " building rotation " .. string.format("%s, %s, %s", self.rotation_yaw.value, self.rotation_pitch.value, self.rotation_roll.value))
            self.position_x:SetStep(self._parent._grid_size)
            self.position_y:SetStep(self._parent._grid_size)
            self.position_z:SetStep(self._parent._grid_size)
        elseif unit:unit_data().mission_element and self._parent.managers.ElementEditor._current_script then
            self._parent.managers.ElementEditor._current_script:update_positions(unit:position(), unit:rotation())
        end      
    end
    self:recalc_all_locals()
end
function UnitEditor:set_unit_data()
    local position = Vector3(self.position_x.value, self.position_y.value, self.position_z.value)
    log(string.format("%.2f", Application:time()) .. " building rotation " .. string.format("%s, %s, %s", self.rotation_yaw.value, self.rotation_pitch.value, self.rotation_roll.value))
    local rotation = Rotation(self.rotation_yaw.value, self.rotation_pitch.value, self.rotation_roll.value)

    if #self._selected_units == 1 then
        local unit = self._selected_units[1]
        self._parent:set_unit_positions(position)
        self._parent:set_unit_rotations(rotation)
        if unit:unit_data() and unit:unit_data().unit_id then
            local prev_id = unit:unit_data().unit_id
            managers.worlddefinition:set_name_id(unit, self._menu:GetItem("name").value)
            local mesh_variations = managers.sequence:get_editable_state_sequence_list(unit:name()) or {}
            unit:unit_data().mesh_variation = mesh_variations[self._menu:GetItem("mesh_variation").value]
            local mesh_variation = unit:unit_data().mesh_variation
            if mesh_variation and mesh_variation ~= "" then
                managers.sequence:run_sequence_simple2(mesh_variation, "change_state", unit)
            end
            local old_continent = unit:unit_data().continent
            unit:unit_data().continent = self._menu:GetItem("continent"):SelectedItem()
            local new_continent = unit:unit_data().continent
            local path_changed = unit:unit_data().name ~= self._menu:GetItem("unit_path").value

            unit:unit_data().name = self._menu:GetItem("unit_path").value
            unit:unit_data().unit_id = self._menu:GetItem("id").value

            unit:set_editor_id(unit:unit_data().unit_id)

            managers.worlddefinition:set_unit(prev_id, unit:unit_data(), old_continent, new_continent)
            if PackageManager:has(Idstring("unit"), Idstring(unit:unit_data().name)) and path_changed then
                local unit_data = unit:unit_data()

                self:delete_selected()
                for k,v in pairs(unit_data) do
                    log(tostring(k) .. "  = "  .. tostring(v) )
                end
                self._parent:SpawnUnit(unit_data.name, unit_data, false, true)
            end
        end
    else            
        self._parent:set_unit_positions(position)
        self._parent:set_unit_rotations(rotation)
        for _, unit in pairs(self._selected_units) do

            managers.worlddefinition:set_unit( unit:unit_data().unit_id, unit:unit_data(), unit:unit_data().continent,  unit:unit_data().continent)
        end
    end
end

function UnitEditor:StorePreviousPosRot()
    for _, unit in pairs(self._selected_units) do
        unit:unit_data()._prev_pos = unit:position()
        unit:unit_data()._prev_rot = unit:rotation()
    end
end

function UnitEditor:add_units_to_prefabs(menu, item)
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
        callback = callback(self, self, "add_unit_dialog_yes"),
        w = 600,
        h = 200,
    })    

end

function UnitEditor:add_unit_dialog_yes(items)
    local prefab = {
        name = items[1].value,
        units = {},
    }

    for _, unit in pairs(self._selected_units) do
        table.insert(prefab.units, unit:unit_data())
    end
    table.insert(BeardLibEditor.Options._storage.Prefabs, {_meta = "option", name = #BeardLibEditor.Options._storage.Prefabs + 1, value = prefab})
    BeardLibEditor.Options:Save()
end
function UnitEditor:select_widget()
    local from = self._parent:get_cursor_look_point(0)
    local to = self._parent:get_cursor_look_point(100000)
    local ok
    if self._selected_units[1] and self._parent._move_widget:enabled() then
        local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._move_widget:widget())
        if ray and ray.body then
            if alt() then
                self:clone()
            end
            self._parent._move_widget:add_move_widget_axis(self._parent._widget_bodies[ray.body:name():t()])
            self._grab = true
            self._grab_info = CoreEditorUtils.GrabInfo:new(self._selected_units[1])
            self._parent._using_move_widget = true
            self._parent._move_widget:set_move_widget_offset(self._selected_units[1], self._selected_units[1]:rotation())
            return true
        end
    end
    if self._selected_units[1] and self._parent._rotate_widget:enabled() then
        local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._parent._rotate_widget:widget())
        if ray and ray.body then
            self._parent._rotate_widget:set_rotate_widget_axis(self._parent._widget_bodies[ray.body:name():t()])
            self._grab = true
            self._grab_info = CoreEditorUtils.GrabInfo:new(self._selected_units[1])
            self._parent._using_rotate_widget = true
            self._parent._rotate_widget:set_world_dir(ray.position)
            self._parent._rotate_widget:set_rotate_widget_start_screen_position(self._parent:world_to_screen(ray.position):with_z(0))
            self._parent._rotate_widget:set_rotate_widget_unit_rot(self._selected_units[1]:rotation())
            return true
        end
    end
end
function UnitEditor:recalc_all_locals()
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
function UnitEditor:recalc_locals(unit, reference)
    local pos = reference:position()
    local rot = reference:rotation()
    unit:unit_data().local_pos = unit:unit_data().position - pos 
    unit:unit_data().local_rot = rot:inverse() * unit:rotation()
end
function UnitEditor:use_grab_info()
    if self._grab then
        self._grab = false
        --self._parent:set_unit_positions(self._grab_info:position())
     --   self:set_unit_rotations(self._grab_info:rotation())
    end    
    self._parent:reset_widget_values()
    self._grab = false
end

function UnitEditor:check_unit_ok(unit)
    if not unit:unit_data() then
        return false
    end
    local mission_element = unit:unit_data().mission_element
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
function UnitEditor:select_unit(mouse2)
	local cam = self._parent._camera_object
	local ray
    local from = self._parent:get_cursor_look_point(0)
    local to = self._parent:get_cursor_look_point(200000)
    for _, r in pairs(World:raycast_all("ray", from, to, "ray_type", "body editor walk", "slot_mask", self._parent._editor_all)) do
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
        if mouse2 then
            if not table.contains(self._selected_units, ray.unit) then
            	table.insert(self._selected_units, ray.unit)
            	self:StorePreviousPosRot()
            elseif not self._parent._mouse_hold then
                table.delete(self._selected_units, ray.unit)
            end
        else
            self._selected_units = {}
            self._selected_units[1] = ray.unit
        end      
        local unit = self._selected_units[1]  
        if #self._selected_units == 1 then
            if unit:unit_data() and unit:unit_data().mission_element then
                log("mission element")
                self._parent.managers.ElementEditor:set_element(managers.mission:get_mission_element(unit:unit_data().mission_element))
            else
                self:set_unit()
            end
        else
           self:set_multi_selected()    
        end
	else
		self._parent:Log("No ray")
	end
end

function UnitEditor:set_multi_selected()
    self._menu:ClearItems()  
    self:build_positions_items()
    self:update_positions()
end

function UnitEditor:set_unit(reset)
    if reset then
        self._selected_units = {}
    end
    local unit = self._selected_units[1]
    if not reset and alive(unit) then
        self:build_unit_editor_menu()
        self._parent:use_widgets(alive(unit))
        self._menu:GetItem("name"):SetValue(unit:unit_data().name_id, false, true)
        self._menu:GetItem("unit_path"):SetValue(unit:unit_data().name, false, true)
        self._menu:GetItem("id"):SetValue(unit:unit_data().unit_id, false, true)
        local mesh_variations = managers.sequence:get_editable_state_sequence_list(unit:unit_data().name or "") or {}
        self._menu:GetItem("mesh_variation"):SetItems(mesh_variations)
        self._menu:GetItem("mesh_variation"):SetValue(table.get_key(mesh_variations, unit:unit_data().mesh_variation))
        self:update_positions()
        self._selected = self._selected_units
        local continent_item = self._menu:GetItem("continent")
        continent_item:SetValue(table.get_key(continent_item.items, unit:unit_data().continent))
 
        for _, element in pairs(managers.mission:get_links(unit:unit_data().unit_id)) do
            self._menu:Button({
                name = element.editor_name,
                text = element.editor_name .. " [" .. (element.class or "") .."]",
                label = "elements",
                group = self._menu:GetItem("links"),
                callback = callback(self._parent, self._parent, "_select_element", element)
            })
        end
    else
        self:build_default_menu() 
    end
end

function UnitEditor:addremove_unit_portal(menu, item)        
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
function UnitEditor:delete_selected(menu, item)                    
    QuickMenu:new( "Warning", "This will delete the selected unit(s)/element(s), Continue?",
        {[1] = {text = "Yes", callback = function()
            for _, unit in pairs(self._selected_units) do
                if alive(unit) then
                    if unit:unit_data().mission_element then
                        managers.mission:delete_element(unit:unit_data().mission_element)
                    end
                    managers.worlddefinition:delete_unit(unit)
                    World:delete_unit(unit)
                end
            end
            self._selected_units = {}
            self:set_unit()            
            self._parent.managers.SpawnSearch:refresh_search()   
        end
    },[2] = {text = "No", is_cancel_button = true}}, true)    
end

function UnitEditor:set_position(unit, position, rotation, offset)
    if offset and unit:unit_data()._prev_pos and unit:unit_data()._prev_rot then
        local pos = mvector3.copy(unit:unit_data()._prev_pos)
        mvector3.add(pos, position)
        unit:set_position(pos)
        local prev_rot = unit:unit_data()._prev_rot
        local rot = Rotation(prev_rot:yaw(), prev_rot:pitch(), prev_rot:roll())
        rot:yaw_pitch_roll(rot:yaw() + rotation:yaw(), rot:pitch() + rotation:pitch(), rot:roll() + rotation:roll())
        unit:set_rotation(rot)
    else
    	unit:set_position(position)
    	unit:set_rotation(rotation)
    end
	local objects = unit:get_objects_by_type(Idstring("model"))
	for _, object in pairs(objects) do
		object:set_visibility(not object:visibility())
		object:set_visibility(not object:visibility())
	end
	local num = unit:num_bodies()
	for i = 0, num - 1 do
		local unit_body = unit:body(i)
		unit_body:set_enabled(not unit_body:enabled())
		unit_body:set_enabled(not unit_body:enabled())
	end

    unit:unit_data().position = unit:position()
    unit:unit_data().rotation = unit:rotation()
    if unit:unit_data().mission_element then
		local element = managers.mission:get_mission_element(unit:unit_data().mission_element)
        element.values.position = unit:position()
        element.values.rotation = unit:rotation()
    else
        managers.worlddefinition:set_unit( unit:unit_data().unit_id, unit:unit_data(), unit:unit_data().continent, unit:unit_data().continent)        
    end
end
function UnitEditor:update(t, dt)
    if managers.viewport:get_current_camera() then
        local pen = Draw:pen(Color(0.15, 1, 1, 1))
        if #self._selected_units > 0 then
            local brush = Draw:brush(Color(0.15, 1, 1, 1))
            brush:set_font(Idstring("core/fonts/nice_editor_font"), 24)
            brush:set_render_template(Idstring("OverlayVertexColorTextured"))
            for _, unit in ipairs(self._selected_units) do
                if alive(unit) then
                    local num = unit:num_bodies()
                    for i = 0, num - 1 do
                        local body = unit:body(i)
                        if self._parent:_should_draw_body(body) then
                            pen:set(Color(0, 0.5, 1))
                            pen:body(body)
                            brush:set_color(Color(0, 0.5, 1))
                        end                            
                    end
                end
            end
            return
        end
    end
end

function UnitEditor:KeyCPressed(button_index, button_name, controller_index, controller, trigger_id)
    if ctrl() and #self._selected_units > 0 and not self._parent._menu._highlighted then
        self:set_unit_data()
        local all_unit_data = {}
        for _, unit in pairs(self._selected_units) do
            table.insert(all_unit_data, unit:unit_data())
        end
        Application:set_clipboard(json.custom_encode(all_unit_data))
    end
end

function UnitEditor:KeyVPressed(button_index, button_name, controller_index, controller, trigger_id)
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

function UnitEditor:clone()
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

function UnitEditor:KeyFPressed(button_index, button_name, controller_index, controller, trigger_id)
    if Input:keyboard():down(Idstring("left ctrl")) then
        if self._selected_units[1] then
            self._parent:set_camera(self._selected_units[1]:position())
        end
	end
end

function UnitEditor:set_unit_enabled(enabled)
	for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            unit:set_enabled(enabled)
        end
	end
end

 