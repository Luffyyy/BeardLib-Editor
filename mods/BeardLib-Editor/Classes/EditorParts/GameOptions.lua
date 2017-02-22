GameOptions = GameOptions or class(EditorPart)
function GameOptions:init(parent, menu)
    self.super.init(self, parent, menu, "GameOptions")    
    self._wanted_elements = {}
end

function GameOptions:build_default_menu()
    self.super.build_default_menu(self)
    local level =  "/" .. (Global.game_settings.level_id or "")
    self:Divider("Basic", self._menu.highlight_color)
    self._current_continent = self:ComboBox("CurrentContinent", callback(self, self, "set_current_continent"))
    self:Slider("CameraSpeed", callback(self, self, "update_option_value"), self:Value("CameraSpeed"), {max = 10, min = 0, step = 0.1})
    self:Slider("GridSize", callback(self._parent, self._parent, "update_grid_size"), 1, {max = 10000, min = 0.1, help = "Sets the amount(in centimeters) that the unit will move"})
    self:Slider("SnapRotation", callback(self._parent, self._parent, "update_snap_rotation"), 90, {max = 360, min = 1, help = "Sets the amount(in degrees) that the unit will rotate"})
    
    self:Divider("Map", self._menu.highlight_color)
    self:TextBox("SavePath", nil, BeardLib.current_map_mod and BeardLib.current_map_mod.ModPath or BeardLib.config.maps_dir .. level, {text = "Map save path"})
    self:Toggle("EditorUnits", callback(self, self, "set_editor_units_visible"), self:Value("EditorUnits"))
    self:Toggle("HighlightUnits", callback(self, self, "update_option_value"), self:Value("HighlightUnits"))
    self:Toggle("ShowElements", callback(self, self, "update_option_value"), self:Value("ShowElements"))
    self:Button("ElementsToDraw", callback(self, self, "elements_classes_dia"), {text = "Prefered Element Classes(none = all)"})
    self:Toggle("DrawPortals", nil, false, {text = "Draw Portals"})
    local group = self:Group("Draw", {toggleable = false, marker_color = self._menu.background_color / 1.2})
    local items = { 
        quads = false,
        doors = false,
        blockers = false,
        vis_graph = false,
        coarse_graph = false,
        nav_links = false,
        covers = false,
    }
    self._draw_options = {}
    for k, v in pairs(items) do
        self._draw_options[k] = self:Toggle(k, callback(self, self, "draw_nav_segments"), v, {items_size = 14, group = group})
    end
    self:Divider("Other", self._menu.highlight_color)
    self:Button("TeleportPlayer", callback(self, self, "drop_player"))
    self:Button("LogPosition", callback(self, self, "position_debug"))
    self:Button("ClearWorld", callback(self, self, "clear_world"))
    self:Button("ClearMassUnit", callback(self, self, "clear_massunit"))
    if self._parent._has_fix then
        self:Button("BuildNavigationData", callback(self, self, "build_nav_segments"))
        self:Button("SaveNavigationData", callback(self, self, "save_nav_data"))
    end
    self:Button("SaveCoverData", callback(self, self, "save_cover_data"))
    self:Toggle("PauseGame", callback(self, self, "pause_game"), false)  
end

function GameOptions:loaded_continents(continents, current_continent)
    self._current_continent:SetItems(continents)
    self._current_continent:SetSelectedItem(current_continent)
end

function GameOptions:update_option_value(menu, item)
    BeardLibEditor.Options:SetValue("Map/"..item.name, item:Value())
    if item.name == "ShowElements" then
        self:Manager("mission"):set_elements_vis()
    end
end

function GameOptions:elements_classes_dia()
    BeardLibEditor.managers.Dialog:show({
        title = "Select what elements to show(none = all)",
        items = {},
        yes = "Close",
        w = 600,
        h = 600,
    })
    self:load_all_elements_classes(BeardLibEditor.managers.Dialog._menu)
end

function GameOptions:select_element(id, menu)
    table.insert(self._wanted_elements, id) 
    self:load_all_elements_classes(menu)
end

function GameOptions:unselect_element(id, menu)
    table.delete(self._wanted_elements, id)
    self:load_all_elements_classes(menu)
end
 
function GameOptions:load_all_elements_classes(menu, item)
    menu:ClearItems("select_buttons")
    menu:ClearItems("unselect_buttons")

    local searchbox = menu:GetItem("searchbox") or menu:TextBox({
        name = "searchbox",
        text = "Search what: ",
        callback = callback(self, self, "load_all_elements_classes")         
    })     
    local selected_divider = menu:GetItem("selected_divider") or menu:Divider({
        name = "selected_divider",
        text = "Selected: ",
        size = 30,    
    })        
    local unselected_divider = menu:GetItem("unselected_divider") or menu:Divider({
        name = "unselected_divider",
        text = "Unselected: ",
        size = 30,    
    })     
    for _, element in pairs(self._wanted_elements) do
        local new = menu:GetItem(element) or menu:Button({
            name = element, 
            text = element,
            label = "unselect_buttons",
            index = menu:GetItem("selected_divider"):Index() + 1,
            callback = callback(self, self, "unselect_element", element)
        })      
    end    

    for _, element in pairs(self:Manager("mission")._mission_elements) do
        if not searchbox.value or searchbox.value == "" or string.match(element, searchbox.value) and not table.has(self._wanted_elements, element) then
            menu:Button({
                name = element, 
                text = element,
                label = "select_buttons",
                callback = callback(self, self, "select_element", element) 
            })    
        end   
    end
end

function GameOptions:pause_game(menu, item)
    Application:set_pause(item.value)
end

function GameOptions:set_current_continent(menu, item)
    self._parent._current_continent = item:SelectedItem()
end

function GameOptions:set_editor_units_visible(menu, item)
    self:update_option_value(meun, item)
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
			unit:set_visible(self._menu:GetItem("EditorUnits"):Value())
		end
	end
end

function GameOptions:draw_nav_segments(menu, item)
    if managers.navigation then
        managers.navigation:set_debug_draw_state(self._draw_options)
    end
end

function GameOptions:drop_player()
	game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0))
end

function GameOptions:position_debug()
    BeardLibEditor:log("Camera Position: %s", tostring(self._parent._camera_pos))
	BeardLibEditor:log("Camera Rotation: %s", tostring(self._parent._camera_rot))
end

function GameOptions:clear_world()
    BeardLibEditor.Utils:YesNoQuestion("This will delete all units in the world!", function()
        for k, unit in pairs(World:find_units_quick("all")) do
            if alive(unit) and unit:editor_id() ~= -1 then
                managers.worlddefinition:delete_unit(unit)
                World:delete_unit(unit)
            end
        end
    end)
end

function GameOptions:clear_massunit()
    BeardLibEditor.Utils:YesNoQuestion("This will clear the MassUnits in the world", function()
        MassUnitManager:delete_all_units()
    end)
end

function GameOptions:update(t, dt)
    if self:Value("HighlightUnits") and managers.viewport:get_current_camera() then
        for _, body in ipairs(World:find_bodies("intersect", "sphere", self._parent._camera_pos, 2500)) do
            if self._parent:_should_draw_body(body) then
                self._pen:set(Color.white)
                self._pen:body(body)
            end
        end
	end
    local draw_portals = self._menu:GetItem("draw_portals")
	if draw_portals and draw_portals.value then
		for _, portal in pairs(managers.portal:unit_groups()) do
			portal:draw(t, dt, 0.5, false, true)
		end
	end
end

function GameOptions:map_path()
    return self._menu:GetItem("SavePath"):Value():gsub("\\" , "/")
end

function GameOptions:map_world_path()
    local map_path = BeardLib.Utils.Path:Combine(self:map_path(), "world")
    if not SystemFS:exists(map_path) then
        SystemFS:make_dir(map_path)
    end
    return map_path
end

function GameOptions:save()
    local path = self:map_path()
    if SystemFS:exists(path) then
        local backup_dir = BeardLib.Utils.Path:Combine(path, "..", "backups", table.remove(string.split(path, "/")))
        if SystemFS:exists(backup_dir) then
            SystemFS:delete_file(backup_dir)
        end
        os.execute("xcopy \"" .. path .. "\" \"" .. backup_dir .. "\" /e /i /h /y /c")
    else
        SystemFS:make_dir(path)
    end
    local map_path = self:map_world_path()
    self:SaveData(map_path, "world.world", BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(managers.worlddefinition._world_data, "generic_xml"))
    local continents = {}
    local missions = {}
    for name, data in pairs(managers.worlddefinition._continent_definitions) do
        local dir = BeardLib.Utils.Path:Combine(map_path, name)
        self:SaveData(dir, name .. ".continent", BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(data, "custom_xml"))
        self:SaveData(dir, name .. ".mission", BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(managers.mission._missions[name], "generic_xml"))
        continents[name] = {name = name, editor_only = (ontinent_name == "editor_only")}
        missions[name] = {file = BeardLib.Utils.Path:Combine(name, name)}
    end
    self:SaveData(map_path, "continents.continents", BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(continents, "custom_xml"))
    self:SaveData(map_path, "mission.mission", BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(missions, "custom_xml"))
end

function GameOptions:SaveData(path, file_name, data)
    if not SystemFS:exists(path) then
        SystemFS:make_dir(path)
    end
    local file = SystemFS:open(BeardLib.Utils.Path:Combine(path, file_name), "w") 
    self._parent:Log("Saving file '%s' as generic_xml in %s", file_name, path)
    if file then
        file:write(data)
        file:close()
    else
        self._parent:Error("Failed to save file %s", c_file)
    end
end

function GameOptions:save_nav_data()    
    local path = self:map_world_path()
    if managers.navigation:get_save_data() and managers.navigation._load_data then
        self:SaveData(path, "nav_manager_data.nav_data", managers.navigation._load_data)
    else
        self._parent:Log("Save data is not ready!")
    end
end

function GameOptions:save_cover_data()
    local path = self._menu:GetItem("SavePath").value
    local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))
    local covers = {
        positions = {},
        rotations = {}
    }
    for i, unit in pairs(all_cover_units) do
        local pos = Vector3()
        unit:m_position(pos)
        mvector3.set_static(pos, math.round(pos.x), math.round(pos.y), math.round(pos.z))
        table.insert(covers.positions, pos)
        local rot = unit:rotation()
        table.insert(covers.rotations, math.round(rot:yaw()))
    end
    self:SaveData(path, "cover_data.cover_data", BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(covers, "custom_xml"))
end

function GameOptions:build_nav_segments() -- Add later the options to the menu
    BeardLibEditor.Utils:YesNoQuestion("This will disable the player and AI and build the nav data proceed?", function()
        local settings = {}
        local units = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                table.insert(units, unit)
            end
        end
        for _, unit in ipairs(units) do
            local ray = World:raycast(unit:position() + Vector3(0, 0, 50), unit:position() - Vector3(0, 0, 150), nil, managers.slot:get_mask("all"))
            if ray and ray.position then
                table.insert(settings, {
                    position = unit:position(),
                    id = unit:editor_id(),
                    color = Color(),
                    location_id = unit:ai_editor_data().location_id
                })
            end
        end
        if #settings > 0 then
            local SE = self:Manager("static")
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:in_slot(managers.slot:get_mask("persons"))   then
                    unit:set_enabled(false)
                    if unit:brain() then
                       unit:brain()._current_logic.update = nil
                    end
                    if SE._disabled_units then
                        table.insert(SE._disabled_units, unit)
                    end
                    for _, extension in pairs(unit:extensions()) do
                        unit:set_extension_update_enabled(Idstring(extension), false)
                    end
                end
            end
            managers.navigation:clear()
            managers.navigation:build_nav_segments(settings, callback(self, self, "build_visibility_graph"))
        else
            self._parent:Log("No nav surface found.")
        end       
    end)
end

function GameOptions:build_visibility_graph()
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
    managers.navigation:build_visibility_graph(callback(self, self, "_finish_visibility_graph"), all_visible, exclude, include, ray_lenght)
end

function GameOptions:_finish_visibility_graph(menu, item)
    managers.groupai:set_state("none")
end
