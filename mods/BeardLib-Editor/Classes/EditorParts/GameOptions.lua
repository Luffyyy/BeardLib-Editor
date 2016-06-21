GameOptions = GameOptions or class()

function GameOptions:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "game_options",
        text = "Game",
        w = 250,
        help = "",
    })
    self._menu:SetSize(nil, self._menu:Panel():h() - 42)    
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom())     
    self._wanted_elements = {}
    self:CreateItems()
end

function GameOptions:CreateItems()
    local level =  "/" .. (Global.game_settings.level_id or "")
    self._menu:Divider({
        name = "basic_options",
        normal_color = self._menu.highlight_color,
        size = 30,
        text = "Basic",
    }) 
    self._menu:Slider({
        name = "Map/CameraSpeed",
        text = "Camera Speed",
        help = "",
        max = 10,
        min = 0,
        step = 0.1,
        value = BeardLibEditor.Options:GetOption("Map/CameraSpeed").value,
        callback = callback(self, self, "update_option_value"),
    })       
    self._menu:ComboBox({
        name = "grid_Size",
        text = "Grid Size",
        help = "The grid size(how much the unit will move)",
        value = 2,
        items = self._parent._grid_sizes,
        callback = callback(self._parent, self._parent, "update_grid_size")
    })    
    self._menu:ComboBox({
        name = "snap_rotation",
        text = "Snap rotation",
        help = "The snap rotation(how much the unit will rotate)",
        value = 7,
        items = self._parent._snap_rotations,
        callback = callback(self._parent, self._parent, "update_snap_rotation")
    }) 
    self._menu:Divider({
        name = "map_options",
        normal_color = self._menu.highlight_color,
        size = 30,
        text = "Map",
    })      
    self._menu:TextBox({
        name = "savepath",
        text = "Map save path: ",
        value = BeardLib.MapsPath .. level,
        help = "",
    })
    self._menu:Toggle({
        name = "Map/EditorUnits",
        text = "Editor Units",
        help = "",
        value = BeardLibEditor.Options:GetOption("Map/EditorUnits").value,
        callback = callback(self, self, "set_editor_units_visible"),
    })
    self._menu:Toggle({
        name = "Map/HighlightUnits",
        text = "Highlight Units",
        help = "",
        value = BeardLibEditor.Options:GetOption("Map/HighlightUnits").value,
        callback = callback(self, self, "update_option_value"),
    })
    self._menu:Toggle({
        name = "Map/ShowElements",
        text = "Show Elements",
        help = "",
        value = BeardLibEditor.Options:GetOption("Map/EditorUnits").ShowElements,
        callback = callback(self, self, "update_option_value"),
    })
    self._menu:Button({
        name = "elements_to_show",
        text = "Elements to draw",
        help = "Decide what elements to draw(none = all)",
        callback = callback(self, self, "show_elements_classes_dialog")
    })        
    self._menu:Toggle({
        name = "draw_portals",
        text = "Draw Portals",
        help = "",
        value = false,
    })
    self._menu:Toggle({
        name = "draw_nav_segments",
        text = "Draw Nav segments",
        help = "",
        callback = callback(self, self, "draw_nav_segments"),
        value = false,
    })
    self._menu:Table({
        name = "draw_nav_segments_options",
        text = "Draw:",
        add = false,
        remove = false,
        help = "",
        items = {
            quads = true,
            doors = true,
            blockers = true,
            vis_graph = true,
            coarse_graph = true,
            nav_links = true,
            covers = true,
        },
        callback = callback(self, self, "draw_nav_segments"),
        value = false,
    })    
    self._menu:Divider({
        name = "other",
        normal_color = self._menu.highlight_color,
        size = 30,
        text = "Other",
    })      
    self._menu:Button({
        name = "teleport_player",
        text = "Teleport Player",
        help = "",
        callback = callback(self, self, "drop_player"),
    })      
    self._menu:Button({
        name = "position_debug",
        text = "Position Debug",
        help = "",
        callback = callback(self, self, "position_debug"),
    })
    self._menu:Button({
        name = "delete_all_units",
        text = "Delete All Units",
        help = "",
        callback = callback(self, self, "delete_all_units")
    })
    self._menu:Button({
        name = "clear_massunit",
        text = "Clear MassUnit",
        help = "",
        callback = callback(self, self, "clear_massunit")
    })

    local has_fix = self._parent._has_fix
    self._menu:Button({
        name = "build_nav",
        text = "Build Navigation Data" .. (has_fix and "" or "[Disabled]"),
        help = "",
        callback = has_fix and callback(self, self, "_build_nav_segments") or callback(self._parent, self._parent, "error_has_no_fix"),
    })
    self._menu:Button({
        name = "save_nav_data",
        text = "Save Navigation Data" .. (has_fix and "" or "[Disabled]"),
        help = "",
        callback = has_fix and callback(self, self, "save_nav_data") or callback(self._parent, self._parent, "error_has_no_fix")
    })
    self._menu:Button({
        name = "save_cover_data",
        text = "Save Cover Data",
        help = "",
        callback = callback(self, self, "save_cover_data"),
    })
    self._menu:Toggle({
        name = "pause_game",
        text = "Pause Game",
        help = "",
        value = false,
        callback = callback(self, self, "pause_game")
    })    
end

function GameOptions:update_option_value(menu, item)
    BeardLibEditor.Options:SetValue(item.name, item.value)
end

function GameOptions:show_elements_classes_dialog()
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

    for _, element in pairs(self._parent._mission_elements) do
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

function GameOptions:set_editor_units_visible(menu, item)
    self:update_option_value(meun, item)
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
			unit:set_visible( self._menu:GetItem("Map/EditorUnits").value )
		end
	end
end

function GameOptions:draw_nav_segments( menu, item )
    if managers.navigation then
        managers.navigation:set_debug_draw_state(menu:GetItem("draw_nav_segments").value and menu:GetItem("draw_nav_segments_options").items or false )
    end
end

function GameOptions:drop_player()
	local rot_new = Rotation(self._parent._camera_rot:yaw(), 0, 0)
	game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, rot_new)
end

function GameOptions:position_debug()
	local p = self._camera_pos
	log("Camera Pos: " .. tostring(p))
end

function GameOptions:delete_all_units()
    QuickMenu:new( "Are you sure you want to continue?", "Are you sure you want to delete all units?",
        {[1] = {text = "Yes", callback = function()
            for k, unit in pairs(World:find_units_quick("all")) do
                if alive(unit) and unit:editor_id() ~= -1 then
                    managers.worlddefinition:delete_unit(unit)
                    World:delete_unit(unit)
                end
            end
        end
        },[2] = {text = "No", is_cancel_button = true}},
        true
    )
end

function GameOptions:clear_massunit()
    QuickMenu:new( "Are you sure you want to continue?", "Are you sure you want to clear the MassUnit?",
        {[1] = {text = "Yes", callback = function()
            MassUnitManager:delete_all_units()
        end
        },[2] = {text = "No", is_cancel_button = true}},
        true
    )
end

function GameOptions:update(t, dt)
    local brush = Draw:brush(Color(0, 0.5, 0.85))
    local highlight = self._menu:GetItem("Map/HighlightUnits")
    local pen = Draw:pen(Color(0.15, 1, 1, 1))

    if highlight and highlight.value and managers.viewport:get_current_camera() then
        local bodies = World:find_bodies("intersect", "sphere", self._parent._camera_pos, 2500)
        for _, body in ipairs(bodies) do
            if self._parent:_should_draw_body(body) then
                pen:set(Color.white)
                pen:body(body)
            end
        end
	end
	if self._menu:GetItem("draw_portals").value then
		for _, portal in pairs(managers.portal:unit_groups()) do
			portal:draw(t,dt, 0.5, false, true)
		end
	end
end

function GameOptions:save_continents()
    local path = self._menu:GetItem("savepath").value:gsub("\\" , "/")
    local world_def = managers.worlddefinition
    if not file.DirectoryExists( path ) then
        os.execute("mkdir \"" .. path .. "\"")
    end
    if file.DirectoryExists( path ) then
        for continent_name, data in pairs(world_def._continent_definitions) do
            self:save_continent(continent_name, data, path)
        end
    else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
    end
end

function GameOptions:save_continent(continent, data, path)
    local sub_path = path .. "/" .. continent .. "/"
    if not file.DirectoryExists(sub_path) then
        os.execute("mkdir \"" .. sub_path .. "\"")
    end

    local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(data, "custom_xml")
    local continent_file = io.open(sub_path .. "/" .. continent .. ".continent.custom_xml", "w+")
    _G.BeardLibEditor:log("Saving continent: " .. continent .. " as a custom_xml in " .. path)
    if continent_file then
        continent_file:write(new_data)
        continent_file:close()
    else
        _G.BeardLibEditor:log("Failed to save continent: " .. continent .. " path: " .. path)
    end
end

function GameOptions:save_missions()
    local path = self._menu:GetItem("savepath").value:gsub("\\" , "/")
    if not file.DirectoryExists( path ) then
        os.execute("mkdir \"" .. path .. "\"")
    end
    if file.DirectoryExists( path ) then
        for mission_name, data in pairs(managers.mission._missions) do
            self:save_mission_file(mission_name, data, path)
        end
    else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
    end
end

function GameOptions:save_mission_file(mission, data, path)
    local sub_path = path .. "/" .. mission .. "/"
    if not file.DirectoryExists(sub_path) then
        os.execute("mkdir \"" .. sub_path .. "\"")
    end

    local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(data, "generic_xml")
    local mission_file = io.open(sub_path .. "/" .. mission .. ".mission.generic_xml", "w+")
    _G.BeardLibEditor:log("Saving mission: " .. mission .. " as a generic_xml in " .. path)
    if mission_file then
        mission_file:write(new_data)
        mission_file:close()
    else
        _G.BeardLibEditor:log("Failed to save mission: " .. mission .. " path: " .. path)
    end
end

function GameOptions:save_nav_data()
    local path = self._menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end
    if file.DirectoryExists( path ) then
        if managers.navigation:get_save_data() and managers.navigation._load_data then
            local file = io.open(path .. "/nav_manager_data.nav_data", "w+")
            file:write(managers.navigation._load_data)
            file:close()
        else
            BeardLibEditor:log("Save data is not ready!")
        end
    else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
    end
end

function GameOptions:save_cover_data()
    local path = self._menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end
    if file.DirectoryExists( path ) then
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
        local file = io.open(path .. "/cover_data.cover_data", "w+")
        local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(covers, "custom_xml")
        file:write(new_data)
        file:close()
    else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
    end
end

function GameOptions:_build_nav_segments()
    QuickMenu:new( "Info", "This will disable the player and AI and build the nav data proceed?",
    {[1] = {text = "Yes", callback = function()
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
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:in_slot(managers.slot:get_mask("persons"))   then
                    unit:set_enabled(false)
                    if unit:brain() then
                       unit:brain()._current_logic.update = nil
                    end
                    if self._parent.managers.UnitEditor._disabled_units then
                        table.insert(self._parent.managers.UnitEditor._disabled_units, unit)
                    end
                    for _, extension in pairs(unit:extensions()) do
                        unit:set_extension_update_enabled(Idstring(extension), false)
                    end
                end
            end
            managers.navigation:clear()
            managers.navigation:build_nav_segments(settings, callback(self, self, "_build_visibility_graph"))
        else
            BeardLibEditor:log("No nav surface found.")
        end
    end
    },[2] = {text = "No", is_cancel_button = true}}, true)
end

function GameOptions:_build_visibility_graph()
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
