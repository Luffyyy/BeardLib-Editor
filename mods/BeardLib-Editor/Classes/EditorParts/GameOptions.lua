GameOptions = GameOptions or class()

function GameOptions:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "game_options",
        text = "Game",
        help = "",
    })

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
    managers.navigation:set_debug_draw_state(menu:GetItem("draw_nav_segments").value and menu:GetItem("draw_nav_segments_options").items or false )
end

function GameOptions:drop_player()
	local rot_new = Rotation(self._parent._camera_rot:yaw(), 0, 0)
	game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, rot_new)
end

function GameOptions:position_debug()
	local p = self._camera_pos
	log("Camera Pos: " .. tostring(p))
    if self._parent.managers.UnitEditor._selected_unit then
        log("Selected Unit[" .. self._parent.managers.UnitEditor._selected_unit:unit_data().name_id .. "] Pos: " .. tostring(self._parent.managers.UnitEditor._selected_unit:position()))
        log("Selected Unit[" .. self._parent.managers.UnitEditor._selected_unit:unit_data().name_id .. "] Rot: " .. tostring(self._parent.managers.UnitEditor._selected_unit:rotation()))
    end
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
