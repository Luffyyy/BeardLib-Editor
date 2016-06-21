MapEditor = MapEditor or class()

local MOVEMENT_SPEED_BASE = 1000
local FAR_RANGE_MAX = 250000
local TURN_SPEED_BASE = 1
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
function MapEditor:init()
    self._grid_sizes = {
        1,
        25,
        50,
        100,
        400,
        800,
        1000,
        1600,
        2000,
        10000
    }
    self._grid_size = self._grid_sizes[2]
    self._snap_rotations = {
        1,
        2,
        5,
        10,
        15,
        30,
        45,
        60,
        90,
        180
    }   
    self._snap_rotation = self._snap_rotations[9]
    self._widget_bodies = {
        ["@ID4f01cba97e94239b@"] = "x",
        ["@IDce15c901d9af3e30@"] = "y",
        ["@ID1a99fc522e3faad0@"] = "z",
        ["@IDc126f12c99c8804d@"] = "xy",
        ["@ID5dac81a18d09497c@"] = "xz",
        ["@ID0602a12dbeee9c14@"]= "yz"
    }
    self._screen_borders = {x = 1280, y = 720}     
	self._camera_object = World:create_camera()
	self._camera_object:set_far_range(FAR_RANGE_MAX)
	self._camera_object:set_fov(75)
	self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()
	self._closed = true
    self._editor_all = World:make_slot_mask(1, 2, 3, 10, 11, 12, 15, 19, 29, 33, 34, 35, 36, 37, 38, 39)
	self._con = managers.menu._controller
	self._turn_speed = 5
    self._move_widget = MoveWidget:new(self)
    self._rotate_widget = RotationWidget:new(self)
    if Global.editor_mode then
        Input:keyboard():add_trigger(Idstring("f10"), function()                
            if self._closed then 
                self._before_state = game_state_machine:current_state_name()               
                game_state_machine:change_state_by_name("editor")
            elseif managers.platform._current_presence == "Playing" then
                game_state_machine:change_state_by_name(self._before_state)
            else
                game_state_machine:change_state_by_name("ingame_waiting_for_players")
            end
        end)
    end
    self._mission_elements = {   
        --Custom Elements--
        "ElementMoveUnit",
        "ElementTeleportPlayer",
        "ElementEnvironment",
        --Normal--
        "ElementAccessCamera",
        "ElementAccessCameraOperator",
        "ElementAccessCameraTrigger",
        "ElementActionMessage",
        "ElementAIArea",
        "ElementAIAttention",
        "ElementAIGlobalEvent",
        "ElementAIGraph",
        "ElementAIRemove",
        "ElementAlertTrigger",
        "ElementAreaMinPoliceForce",
        "ElementAreaTrigger",
        "ElementAssetTrigger",
        "ElementAwardAchievment",
        "ElementBainState",
        "ElementBlackScreenVariant",
        "ElementBlurZone",
        "ElementCarry",
        "ElementVariable",
        "ElementCharacterOutline",
        "ElementCharacterSequence",
        "ElementCharacterTeam",
        "ElementCinematicCamera",
        "ElementConsoleCommand",
        "ElementDangerZone",
        "ElementUnitSequenceTrigger",
        "ElementDialogue",
        "ElementDifficulty",
        "ElementDifficultyLevelCheck",
        "ElementDisableShout",
        "ElementDisableUnit",
        "ElementDropInState",
        "ElementEnableUnit",
        "ElementEnemyDummyTrigger",
        "ElementEnemyPrefered",
        "ElementEquipment",
        "ElementExperience",
        "ElementExplosion",
        "ElementExplosionDamage",
        "ElementFadeToBlack",
        "ElementFakeAssaultState",
        "ElementFeedback",
        "ElementFilter",
        "ElementFlashlight",
        "ElementFleepoint",
        "Elementgamedirection",
        "ElementHeat",
        "ElementHint",
        "ElementInstigator",
        "ElementInstigatorRule",
        "ElementInteraction",
        "ElementInventoryDummy",
        "ElementJobStageAlternative",
        "ElementJobValue",
        "ElementUnitSequence",
        "ElementKillZone",
        "ElementLaserTrigger",
        "ElementLookatTrigger",
        "ElementLootBag",
        "ElementLootSecuredTrigger",
        "ElementMandatoryBags",
        "ElementMissionEnd",
        "ElementMissionFilter",
        "ElementModifyPlayer",
        "ElementMoney",
        "ElementMotionPathMarker",
        "ElementNavObstacle",
        "ElementObjective",
        "ElementPickup",
        "ElementPlayerNumberCheck",
        "ElementPlayerSpawner",
        "ElementPlayerState",
        "ElementPlaySound",
        "ElementPlayerStyle",
        "ElementPointOfNoReturn",
        "ElementPrePlanning",
        "ElementLogicChance",
        "MissionScriptElement",
        "ElementPressure",
        "ElementProfileFilter",
        "ElementScenarioEvent",
        "ElementSecurityCamera",
        "ElementSequenceCharacter",
        "ElementSetOutline",
        "ElementSlowMotion",
        "ElementSmokeGrenade",
        "ElementSpawnCivilian",
        "ElementSpawnCivilianGroup",
        "ElementSpawnDeployable",
        "ElementSpawnEnemyDummy",
        "ElementSpawnEnemyGroup",
        "ElementSpawnGageAssignment",
        "ElementSpawnGrenade",
        "ElementSpecialObjective",
        "ElementSpecialObjectiveGroup",
        "ElementSpecialObjectiveTrigger",
        "ElementSpotter",
        "ElementStatistics",
        "ElementToggle",
        "ElementRandom",
        "ElementTimer",
        "ElementTeammateComment",
        "ElementTeamRelation",
        "ElementVehicleOperator",
        "ElementVehicleSpawner",
        "ElementVehicleTrigger",
        "ElementWayPoint",
        "ElementWhisperState",
    }
    self._file_streamer_max_workload = 0
	self.managers = {}
    self._side_buttons = {}
    self:check_has_fix()    
    self._use_move_widget = self._has_fix    
    self:create_menu() 
end
function MapEditor:check_has_fix()
    local unit = World:spawn_unit(Idstring("core/units/move_widget/move_widget"), Vector3())
    local ray = World:raycast("ray", unit:position(), unit:position():with_z(100), "ray_type", "widget", "target_unit", unit)
    if not ray then
        self._has_fix = false
        BeardLibEditor:log("Warning: pdmod fix not found, Some features will not be available.")
    else
        self._has_fix = true
    end
    unit:set_enabled(false)
    unit:set_slot(0)
end
function MapEditor:update_grid_size(menu, item)
    self._grid_size = tonumber(item:SelectedItem())
    for _, manager in pairs(self.managers) do
        if manager.update_grid_size then
            manager:update_grid_size()
        end
    end
end
function MapEditor:update_snap_rotation(menu, item)
    self._snap_rotation = tonumber(item:SelectedItem())
end
function MapEditor:grid_size()
    return ctrl() and 1 or self._grid_size
end
function MapEditor:snap_rotation()
    return ctrl() and 1 or self._snap_rotation
end
function MapEditor:cursor_pos()
    local x, y = managers.mouse_pointer._mouse:position()
    return Vector3(x / self._screen_borders.x * 2 - 1, y / self._screen_borders.y * 2 - 1, 0)
end
function MapEditor:get_cursor_look_point(dist)
    return self._camera_object:screen_to_world(self:cursor_pos() + Vector3(0, 0, dist))
end
function MapEditor:world_to_screen(pos)
    return self._camera_object:world_to_screen(pos)
end
function MapEditor:screen_to_world(pos, dist)
    return self._camera_object:screen_to_world(pos + Vector3(0, 0, dist))
end
function MapEditor:create_menu()
    self._menu = MenuUI:new({
        alpha = 0.4,
        text_color = Color.white,
        normal_color = Color("33476a"):with_alpha(0),
        highlight_color = Color("33476a"),
        background_color = Color(0.2, 0.2, 0.2),
        mousepressed = callback(self, self, "mouse_pressed"),
        mouserelease = callback(self, self, "mouse_released"),
        mousemoved = callback(self, self, "mouse_moved"),
        create_items = callback(self, self, "create_items"),
    })
end

function MapEditor:error_has_no_fix()
    QuickMenu:new( "Error", "In order for this feature to work you need to install the pdmod given in the download page of the mod.", {{text = "ok", is_cancel_button = true}}, true)    
end
 
function MapEditor:create_items(menu)
	self.managers.UnitEditor = UnitEditor:new(self, menu)
	self.managers.ElementEditor = ElementEditor:new(self, menu)
	self.managers.SpawnSearch = SpawnSearch:new(self, menu)
	self.managers.GameOptions = GameOptions:new(self, menu)
    self.managers.UpperMenu = UpperMenu:new(self, menu)
    self.managers.Console = EditorConsole:new(self, menu)
end

function MapEditor:reset_widget_values()
	self._using_move_widget = false
    self._using_rotate_widget = false
    self._move_widget:reset_values()
    self._rotate_widget:reset_values()
end
function MapEditor:use_widgets()
    self._move_widget:set_enabled(self._use_move_widget and self:enabled() and alive(self:widget_affect_object()))
    self._rotate_widget:set_enabled(self._use_rotation_widget and self:enabled() and alive(self:widget_affect_object()))
end

function MapEditor:mouse_moved( x, y )
    if self._mouse_hold then
        self.managers.UnitEditor:select_unit(true)
    end
end
function MapEditor:mouse_released( button, x, y )
    self._mouse_hold = false
    self:reset_widget_values()
end
function MapEditor:mouse_pressed( button, x, y )
    if button == Idstring("0") then
        self.managers.UnitEditor:use_grab_info()
        if not self.managers.UnitEditor:select_widget() then
            self.managers.UnitEditor:select_unit()
        end
    elseif button == Idstring("1") then            
        self.managers.UnitEditor:select_unit(true)
        self._mouse_hold = true
    end
end

function MapEditor:_select_unit(unit, no_reset)
    self.managers.UpperMenu:SwitchMenu(self._menu:GetItem("selected_unit"))    
    if not no_reset then
        self.managers.UnitEditor._selected_units = {}
    end
	table.insert(self.managers.UnitEditor._selected_units, unit)
    self.managers.UnitEditor:set_unit()
end

function MapEditor:_select_element(element, menu, item)
    self.managers.ElementEditor:set_element(element)
end

function MapEditor:add_element(element, menu, item)
    self.managers.ElementEditor:add_element(element)
end

function MapEditor:SpawnUnit( unit_path, unit_data, no_reset, respawn )
    local unit
    local cam = managers.viewport:get_current_camera()
    local pos = unit_data and unit_data.position or cam:position() + cam:rotation():y()
    local rot = unit_data and unit_data.rotation or Rotation(0,0,0)
    local split = string.split(unit_path, "/")

    if MassUnitManager:can_spawn_unit(Idstring(unit_path)) then
        unit = MassUnitManager:spawn_unit(Idstring(unit_path), pos , rot )
    else
        unit = CoreUnit.safe_spawn_unit(unit_path, pos, rot)
    end
    if not unit then
        BeardLibEditor:log("Something went wrong while spawning the unit..")
        return
    end
    if not unit.unit_data or not unit:unit_data()  then
        BeardLibEditor:log(unit_path .. " Has no unit data.")
		return
    elseif respawn then
        for k, v in pairs(unit_data) do
            unit:unit_data()[k] = v
        end
    else
		local unit_id = managers.worlddefinition:GetNewUnitID()
        unit:unit_data().unit_id = unit_id
        unit:unit_data().name = unit_path        
        unit:unit_data().name_id = managers.worlddefinition:get_name_id(unit, unit_data and unit_data.name_id)
        unit:unit_data().position = unit_data and unit_data.position or unit:position()
        unit:unit_data().rotation = unit_data and unit_data.rotation or unit:rotation()
		unit:unit_data().continent = unit_data and unit_data.continent or "world"
		unit:set_editor_id(unit_id)
    end
    managers.worlddefinition:add_unit(unit, unit:unit_data().continent)
    unit:set_editor_id(unit:unit_data().unit_id)
	self:_select_unit(unit, no_reset)
end

function MapEditor:_should_draw_body(body)
    if not body:enabled() then
        return false
    end
    if body:has_ray_type(Idstring("editor")) and not body:has_ray_type(Idstring("walk")) and not body:has_ray_type(Idstring("mover")) then
        return false
    end
    if body:has_ray_type(Idstring("widget")) then
        return false
    end
    return true
end

function MapEditor:load_continents(continents)
	local continent_items = {}
    for continent_name, _ in pairs(continents) do
        --[[self._menu:GetItem("save_options"):Toggle({
            name = "continent_" .. continent_name,
            text = "Save continent: " .. continent_name,
            help = "",
            index = 5,
            value = true,
        })]]
		table.insert(continent_items, continent_name)
    end
	self.managers.UnitEditor._continents = continent_items
end

function MapEditor:load_missions(missions)
    for mission_name, _ in pairs(missions) do
	   --[[ self._menu:GetItem("save_options"):Toggle({
	        name = "mission_" .. mission_name,
	        text = "Save mission: " .. mission_name,
	        help = "",
            index = 8,
	        value = true,
	    })]]
    end
end

function MapEditor:set_camera(pos, rot)
	if pos then
		self._camera_object:set_position((alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3()) + pos)
		self._camera_pos = pos
	end
	if rot then
		self._camera_object:set_rotation(rot)
		self._camera_rot = rot
	end
end

function MapEditor:disable()
    self._menu:disable()
	self._closed = true
	self._vp:set_active(false)
	if type(managers.enemy) == "table" then
		managers.enemy:set_gfx_lod_enabled(true)
	end
    if managers.hud then
        managers.hud:set_enabled()
    end

	for _, manager in pairs(self.managers) do
		if manager.disabled then
			manager:disabled()
		end
	end
end

function MapEditor:enable()
    self._menu:enable()
	local active_vp = managers.viewport:first_active_viewport()
	if active_vp then
		self._start_cam = active_vp:camera()
		if self._start_cam then
			local pos = self._start_cam:position() - (alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3())
			self:set_camera(pos, self._start_cam:rotation())
		end
	end
	self._closed = false
	self._vp:set_active(true)
	self._con:enable()
	if managers.enemy then
		managers.enemy:set_gfx_lod_enabled(false)
	end
    if managers.hud then
        managers.hud:set_disabled()
    end

	for _, manager in pairs(self.managers) do
		if manager.enabled then
			manager:enabled()
		end
	end
end
function MapEditor:widget_affect_object()
    return self.managers.UnitEditor._selected_units[1]
end

function MapEditor:widget_rot()
    return self:widget_affect_object():rotation()
end
function MapEditor:set_unit_positions(pos)
    local reference = self:widget_affect_object()
    for _, unit in ipairs(self.managers.UnitEditor._selected_units) do
        if unit ~= reference then
            self.managers.UnitEditor:set_position(unit, pos, reference:rotation(), true)
        end
    end
end
function MapEditor:use_widget_position(unit, pos)
    self.managers.UnitEditor:set_position(unit, pos, unit:rotation())
    self.managers.UnitEditor:update_positions()
end
function MapEditor:use_widget_rotation(unit, rot)
    self.managers.UnitEditor:set_position(unit, unit:position(), rot)
    self.managers.UnitEditor:update_positions()
end
function MapEditor:paused_update(t, dt)
    self:update(t, dt)
end
function MapEditor:update(t, dt)
    if self:enabled() then      
        for _, manager in pairs(self.managers) do
            if manager.update then
                manager:update(t, dt)
            end
        end
        self:update_camera(t, dt)
        self:update_widgets(t, dt)
    end

end

function MapEditor:update_widgets(t, dt)
   if not self._closed and alive(self:widget_affect_object()) then
        local x = 0
        local y = 0
        local z = 0
        local widget_pos 
        if #self.managers.UnitEditor._selected_units == 1 then
            widget_pos = self:world_to_screen(self:widget_affect_object():position())     
        else        
            for _, unit in pairs(self.managers.UnitEditor._selected_units) do
                x = x + unit:position().x
                y = y + unit:position().y
                z = z + unit:position().z
            end
            local count = #self.managers.UnitEditor._selected_units
            widget_pos = self:world_to_screen(Vector3(x / count, y / count, z / count))
        end
        if widget_pos.z > 100 then
            widget_pos = widget_pos:with_z(0)
            local widget_screen_pos = widget_pos
            widget_pos = self:screen_to_world(widget_pos, 1000)
            local widget_rot = self:widget_rot()
            if self._using_move_widget then
                if self._move_widget:enabled() then
                    for _, unit in pairs(self.managers.UnitEditor._selected_units) do
                        local result_pos = self._move_widget:calculate(unit, unit:rotation())
                        self:use_widget_position(unit, result_pos)
                    end
                end
            end
            if self._using_rotate_widget then
                if self._rotate_widget:enabled() then
                    for _, unit in pairs(self.managers.UnitEditor._selected_units) do
                        local result_rot = self._rotate_widget:calculate(unit, unit:rotation(), widget_pos, widget_screen_pos)
                        self:use_widget_rotation(unit, result_rot)
                    end
                end
            end
            if self._move_widget:enabled() then
                self._move_widget:set_position(widget_pos)
                self._move_widget:set_rotation(widget_rot)
                self._move_widget:update(t, dt)
            end
            if self._rotate_widget:enabled() then
                self._rotate_widget:set_position(widget_pos)
                self._rotate_widget:set_rotation(widget_rot)
                self._rotate_widget:update(t, dt)
            end
        end
    end
end
function MapEditor:update_camera(t, dt)
	if self._menu._highlighted or not shift() then
        managers.mouse_pointer._mouse:show()
        self._mouse_pos_x, self._mouse_pos_y = managers.mouse_pointer._mouse:world_position()
		return
	end
	local axis_move = self._con:get_input_axis("freeflight_axis_move")
	local axis_look = self._con:get_input_axis("freeflight_axis_look")
	local btn_move_up = self._con:get_input_float("freeflight_move_up")
	local btn_move_down = self._con:get_input_float("freeflight_move_down")
	local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
	move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
	local move_delta = move_dir * self._menu:GetItem("Map/CameraSpeed").value * MOVEMENT_SPEED_BASE * dt
	local pos_new = self._camera_pos + move_delta
	local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * self._turn_speed * TURN_SPEED_BASE
	local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * self._turn_speed * TURN_SPEED_BASE, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)
	local rot_new
	if Input:keyboard():down(Idstring("left shift")) then
		rot_new = Rotation(yaw_new, pitch_new, 0)
        managers.mouse_pointer._mouse:hide()
        managers.mouse_pointer:set_mouse_world_position(self._mouse_pos_x, self._mouse_pos_y)
	end
	if not CoreApp.arg_supplied("-vpslave") then
		self:set_camera(pos_new, rot_new)
	end
end

function MapEditor:destroy()
    self._vp:destroy()
end
function MapEditor:enabled()
	return not self._closed
end
