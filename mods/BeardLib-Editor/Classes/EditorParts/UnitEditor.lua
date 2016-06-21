UnitEditor = UnitEditor or class()

function UnitEditor:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "selected_unit",
        text = "Selected Unit",
        visible = true,
        w = 250,
        help = "",
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
        text = "No unit selected",
    })
    self._menu:Button({
        name = "select_exisiting",
        text = "Select existing unit",
        callback = callback(self, self, "select_exisiting_unit")
    })    
    self._menu:Button({
        name = "create_new",
        text = "Spawn a new unit",
        callback = callback(self, self, "spawn_new_unit")
    })
end
function UnitEditor:select_exisiting_unit()
    self._parent.managers.SpawnSearch:load_all_units()    
end
function UnitEditor:spawn_new_unit()
    self._parent.managers.SpawnSearch:browse()
end
function UnitEditor:InitItems()
    self._menu:ClearItems()
    local quick_buttons = self._menu:ItemsGroup({
        name = "quick_buttons",
        text = "Quick actions",
    })
    local other = self._menu:ItemsGroup({
        name = "other",
        text = "Other",
    })       
    local transform = self._menu:ItemsGroup({
        name = "unit_transform",
        text = "Transform",
    })        
    self._menu:Button({
        name = "deselect_unit",
        text = "Deselect unit(s)",
        help = "",
        group = quick_buttons,
        callback = callback(self, self, "deselect_unit"),
    })
    self._menu:TextBox({
        name = "unit_name",
        text = "Name: ",
        value = "",
        help = "",
        group = other,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:TextBox({
        name = "unit_id",
        text = "ID: ",
        value = "",
        help = "",
        group = other,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:ComboBox({
        name = "unit_mesh_variation",
        text = "Mesh variation: ",
        value = 1,
        items = {},
        help = "",
        group = other,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:ComboBox({
        name = "unit_continent",
        text = "Continent: ",
        value = 1,
        items = self._continents,
        help = "",
        group = other,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:TextBox({
        name = "unit_path",
        text = "Unit path: ",
        value = "",
        help = "",
        group = other,
        callback = callback(self, self, "set_unit_data"),
    })   
    self._menu:Button({
        name = "select_unit_path",
        text = "Set unit",
        help = "",
        group = other,
        callback = callback(self, self, "select_unit_dialog"),
    })    
    local grid_size = self._parent.managers.GameOptions._menu:GetItem("grid_Size").value
    self._menu:Slider({
        name = "positionx",
        text = "Position x: ",
        value = 0,
        help = "",
        step = grid_size,
        group = transform,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "positiony",
        text = "Position Y: ",
        value = 0,
        help = "",
        step = grid_size,
        group = transform,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "positionz",
        text = "Position z: ",
        value = 0,
        help = "",
        step = grid_size,
        group = transform,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "rotationyaw",
        text = "Rotation yaw: ",
        value = 0,
        help = "",
        step = grid_size,
        group = transform,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "rotationpitch",
        text = "Rotation pitch: ",
        value = 0,
        help = "",
        step = grid_size,
        group = transform,
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "rotationroll",
        text = "Rotation roll: ",
        value = 0,
        help = "",
        step = grid_size,
        group = transform,
        callback = callback(self, self, "set_unit_data"),
    })    
    self._menu:Button({
        name = "unit_delete_btn",
        text = "Delete unit(s)",
        help = "",
        group = quick_buttons,
        callback = callback(self, self, "delete_unit"),
    })
    self._menu:ItemsGroup({
        name = "links",
        text = "Links",
    })    
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

    BeardLibEditor:log(self.current_dir)   
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
                    callback = callback(self, self, "unit_click", data.path),
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
                callback = callback(self, self, "unit_click", unit_path),
            })
        end
    end
end

function UnitEditor:unit_click(unit_path)
    BeardLibEditor.managers.Dialog:hide()
    self._menu:GetItem("unit_path"):SetValue(unit_path)
    self:set_unit_data(self._menu)
end
function UnitEditor:deselect_unit(menu, item)
    self:set_unit(true)
end

function UnitEditor:update_positions(menu, item)
    if #self._selected_units == 1 then
        local unit = self._selected_units[1]
        self._menu:GetItem("positionx"):SetValue(unit:position().x or 0)
        self._menu:GetItem("positiony"):SetValue(unit:position().y or 0)
        self._menu:GetItem("positionz"):SetValue(unit:position().z or 0)
        self._menu:GetItem("rotationyaw"):SetValue(unit:rotation():yaw() or 0)
        self._menu:GetItem("rotationpitch"):SetValue(unit:rotation():pitch() or 0)
        self._menu:GetItem("rotationroll"):SetValue(unit:rotation():roll() or 0)
    end
end
function UnitEditor:set_unit_data(menu, item)
    local x = menu:GetItem("positionx").value
    local y = menu:GetItem("positiony").value
    local z = menu:GetItem("positionz").value
    local yaw = menu:GetItem("rotationyaw").value
    local pitch = menu:GetItem("rotationpitch").value
    local roll =  menu:GetItem("rotationroll").value

    if #self._selected_units == 1 then
        local unit = self._selected_units[1]
        self:set_position(unit, Vector3(x, y, z), Rotation( yaw, pitch, roll))
        if unit:unit_data() and unit:unit_data().unit_id then
            local prev_id = unit:unit_data().unit_id
            managers.worlddefinition:set_name_id(unit, self._menu:GetItem("unit_name").value)
            local mesh_variations = managers.sequence:get_editable_state_sequence_list(unit:name()) or {}
            unit:unit_data().mesh_variation = mesh_variations[self._menu:GetItem("unit_mesh_variation").value]
            local mesh_variation = unit:unit_data().mesh_variation
            if mesh_variation and mesh_variation ~= "" then
                managers.sequence:run_sequence_simple2(mesh_variation, "change_state", unit)
            end
            local old_continent = unit:unit_data().continent
            unit:unit_data().continent = self._menu:GetItem("unit_continent"):SelectedItem()
            local new_continent = unit:unit_data().continent
            local path_changed = unit:unit_data().name ~= self._menu:GetItem("unit_path").value 
            
            unit:unit_data().name = self._menu:GetItem("unit_path").value 
            unit:unit_data().unit_id = self._menu:GetItem("unit_id").value
 
            unit:set_editor_id(unit:unit_data().unit_id)            

            managers.worlddefinition:set_unit(prev_id, unit:unit_data(), old_continent, new_continent)            
            if PackageManager:has(Idstring("unit"), Idstring(unit:unit_data().name)) and path_changed then
                local unit_data = unit:unit_data()
      
                self:delete_unit()                
                for k,v in pairs(unit_data) do
                    log(tostring(k) .. "  = "  .. tostring(v) )
                end      
                self._parent:SpawnUnit(unit_data.name, unit_data, false, true)
            end
        end
    else
        for _, unit in pairs(self._selected_units) do
            self:set_position(unit, Vector3(x, y, z), Rotation(yaw, pitch, roll), true)
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
    for _, unit in pairs(self._selected_units) do
        if self._parent._menu:GetItem("prefabs") and not self._parent._menu:GetItem("prefabs"):GetItem(unit:unit_data().name_id) then
            self._parent._menu:GetItem("prefabs"):Button({
                name = unit:unit_data().name_id,
                text = unit:unit_data().name_id,
                callback = callback(self._parent, self._parent, "SpawnUnit", unit:unit_data().name)
            })
        end
    end
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
            for _, unit in pairs(self._selected_units) do
                self._parent._move_widget:set_move_widget_offset(unit)
            end
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
            for _, unit in pairs(self._selected_units) do
                self._parent._rotate_widget:set_rotate_widget_unit_rot(unit)
            end
            return true
        end
    end
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

function UnitEditor:select_unit(mouse2)
	local cam = self._parent._camera_object
	local ray
    local from = self._parent:get_cursor_look_point(0)
    local to = self._parent:get_cursor_look_point(200000)
	if self._parent._menu:GetItem("Map/EditorUnits").value then
        ray = World:raycast("ray", from, to, "ray_type", "body editor walk", "slot_mask", self._parent._editor_all)
    else
        ray = World:raycast("ray", from, to)
    end
	if ray then
		BeardLibEditor:log("Ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
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
        self:set_unit()
	else
		BeardLibEditor:log("No ray")
	end

end

function UnitEditor:set_unit(reset)
    if reset then
        self._selected_units = {}
    end
    local unit = self._selected_units[1]
    local show_real = #self._selected_units == 1  
    if not reset and alive(unit) then
        self:InitItems()
        self._parent:use_widgets(alive(unit))
        self._menu:GetItem("unit_name"):SetValue(show_real and unit:unit_data().name_id or "", true)
        self._menu:GetItem("unit_path"):SetValue(show_real and unit:unit_data().name or "", true)    
        self._menu:GetItem("unit_id"):SetValue(show_real and unit:unit_data().unit_id or "", true)        
        local mesh_variations = show_real and managers.sequence:get_editable_state_sequence_list(unit:name() or "") or {}
        self._menu:GetItem("unit_mesh_variation"):SetItems(mesh_variations)
        self._menu:GetItem("unit_mesh_variation"):SetValue(show_real and unit:unit_data().mesh_variation and table.get_key(mesh_variations, unit:unit_data().mesh_variation) or nil)
        local continent_item = self._menu:GetItem("unit_continent")
        continent_item:SetValue(show_real and unit:unit_data().continent and table.get_key(continent_item.items, unit:unit_data().continent) or nil)
        self._menu:GetItem("positionx"):SetValue(show_real and unit:position().x or 0)
        self._menu:GetItem("positiony"):SetValue(show_real and unit:position().y or 0)
        self._menu:GetItem("positionz"):SetValue(show_real and unit:position().z or 0)
        self._menu:GetItem("rotationyaw"):SetValue(show_real and unit:rotation():yaw() or 0)
        self._menu:GetItem("rotationpitch"):SetValue(show_real and unit:rotation():pitch() or 0)
        self._menu:GetItem("rotationroll"):SetValue(show_real and unit:rotation():roll() or 0)
        self._menu:GetItem("rotationroll"):SetEnabled(show_real)       
        continent_item:SetEnabled(show_real)
        self._menu:GetItem("rotationpitch"):SetEnabled(show_real)        
        self._menu:GetItem("rotationyaw"):SetEnabled(show_real)    

        self._menu:GetItem("positionx"):SetStep(self._parent._grid_size)
        self._menu:GetItem("positiony"):SetStep(self._parent._grid_size)
        self._menu:GetItem("positionz"):SetStep(self._parent._grid_size)
        self._menu:GetItem("rotationyaw"):SetStep(self._parent._snap_rotation)
        self._menu:GetItem("rotationpitch"):SetStep(self._parent._snap_rotation)
        self._menu:GetItem("rotationroll"):SetStep(self._parent._snap_rotation)
     
        self._menu:GetItem("unit_mesh_variation"):SetEnabled(show_real)        
        self._menu:GetItem("unit_name"):SetEnabled(show_real)
        self._menu:GetItem("unit_path"):SetEnabled(show_real)
        self._menu:GetItem("unit_id"):SetEnabled(show_real)
    
        if show_real then
            for _, element in pairs(managers.mission:get_links(unit:unit_data().unit_id)) do
                self._menu:Button({
                    name = element.editor_name,
                    text = element.editor_name .. " [" .. (element.class or "") .."]",
                    label = "elements",
                    group = self._menu:GetItem("links"),
                    callback = callback(self._parent, self._parent, "_select_element", element)
                })
            end
        end
    else
        self:build_default_menu() 
    end
end

function UnitEditor:delete_unit(menu, item)
    if #self._selected_units ~= 0 then
        for _, unit in pairs(self._selected_units) do
            if alive(unit) then
                managers.worlddefinition:delete_unit(unit)
                World:delete_unit(unit)
            end
        end
        self._selected_units = {}
        self:set_unit()
    end
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
    managers.worlddefinition:set_unit( unit:unit_data().unit_id, unit:unit_data(), unit:unit_data().continent, unit:unit_data().continent)        
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
        self:set_unit_data(self._menu)
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
    self:set_unit_data(self._menu)
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
