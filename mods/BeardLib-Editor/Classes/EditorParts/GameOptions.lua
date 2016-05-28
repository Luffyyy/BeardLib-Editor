GameOptions = GameOptions or class()

function GameOptions:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "game_options",
        text = "Game",
        help = "",
    })
    self._wanted_elements = {}
    self:CreateItems()
end

function GameOptions:CreateItems()
    self._menu:Button({
        name = "teleport_player",
        text = "Teleport player",
        help = "",
        callback = callback(self, self, "drop_player"),
    })
    self._menu:Button({
        name = "position_debug",
        text = "Position debug",
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
    self._menu:Slider({
        name = "camera_speed",
        text = "Camera speed",
        help = "",
        max = 10,
        min = 0,
        step = 0.1,
        value = 2,
    })
    self._menu:Toggle({
        name = "units_visibility",
        text = "Editor units visibility",
        help = "",
        value = false,
        callback = callback(self, self, "set_editor_units_visible"),
    })
    self._menu:Toggle({
        name = "units_highlight",
        text = "Highlight all units",
        help = "",
        value = false,
    })
    self._menu:Toggle({
        name = "show_elements",
        text = "Show elements",
        help = "",
        value = false,
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
        text = "Draw nav segments",
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
    self._menu:Toggle({
        name = "pause_game",
        text = "Pause game",
        help = "",
        value = false,
        callback = callback(self, self, "pause_game")
    })    
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
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
			unit:set_visible( self._menu:GetItem("units_visibility").value )
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
	local p = self._parent._camera_pos
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

    if self._menu:GetItem("units_highlight").value then
		for _, unit in pairs(World:find_units_quick("all")) do
			if unit:editor_id() ~= -1 then
                local cam_up = managers.viewport:get_current_camera():rotation():z()
                local cam_right = managers.viewport:get_current_camera():rotation():x()
				Application:draw(unit, 1, 1,1)
                brush:set_font(Idstring("fonts/font_medium"), 32)
                brush:center_text(unit:position() + Vector3(-10, -10, 200), unit:editor_id(), cam_right, -cam_up) --Sometimes you can't select and can't find the unit..
			end
		end
	end
	if self._menu:GetItem("draw_portals").value then
		for _, portal in pairs(managers.portal:unit_groups()) do
			portal:draw(t,dt, 0.5, false, true)
		end
	end
end
