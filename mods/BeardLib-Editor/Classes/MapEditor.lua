MapEditor = MapEditor or class()

local MOVEMENT_SPEED_BASE = 1000
local FAR_RANGE_MAX = 250000
local TURN_SPEED_BASE = 1
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
function MapEditor:init()
	self._camera_object = World:create_camera()
	self._camera_object:set_far_range(FAR_RANGE_MAX)
	self._camera_object:set_fov(75)
	self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()
	self._closed = true
    self._editor_all = World:make_slot_mask(1, 2, 3, 10, 11, 12, 15, 19, 29, 33, 34, 35, 36, 37, 38, 39)
	self._con =  managers.controller:create_controller("MapEditor", nil, true, 10)
	self._turn_speed = 5
	local keyboard = Input:keyboard()
	local key = Idstring("f10")
	if keyboard and keyboard:has_button(key) then
		self._show_con = Input:create_virtual_controller()
		self._show_con:connect(keyboard, key, Idstring("btn_toggle"))
		self._show_con:add_trigger(Idstring("btn_toggle"), callback(self, self, "show_key_pressed"))
	end
    self._mission_elements = { 
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
        "ElementEnvironmentOperator",
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
	self.managers = {}

    self:create_menu()
end

function MapEditor:create_menu()
	self._menu = MenuUI:new({
		w = 325,
        tabs = true,
        background_color = Color(0.8, 0.8, 0.8),
        mousepressed = callback(self, self, "mouse_pressed"),
		create_items = callback(self, self, "create_items"),
	})
    self._hide_panel = self._menu._fullscreen_ws_pnl:panel({
        name = "hide_panel",
        w = 16,
        h = 16,
        y = 64,
        layer = 25
    })
    self._hide_panel:rect({
        name = "bg",
        halign="grow",
        valign="grow",
        color = Color(0.8, 0.8, 0.8),
        alpha = 0.8,
    })
    self._hide_panel:text({
        name = "text",
        text = "<",
        layer = 20,
        w = 16,
        h = 16,
        align = "center",
        color = Color.black,
        font = "fonts/font_medium_mf",
        font_size = 16
    })
    self._menu._fullscreen_ws_pnl:rect({
        name = "crosshair_vertical",
        w = 2,
        h = 6,
        alpha = 0.8,
        layer = 999
    }):set_center(self._menu._fullscreen_ws_pnl:center())
    self._menu._fullscreen_ws_pnl:rect({
        name = "crosshair_horizontal",
        w = 6,
        h = 2,
        alpha = 0.8,
        layer = 999
    }):set_center(self._menu._fullscreen_ws_pnl:center())
    self._hide_panel:set_left(self._menu._panel:right())
end

function MapEditor:create_items(menu)
	self.managers.UnitEditor = UnitEditor:new(self, menu)
	self.managers.ElementEditor = ElementEditor:new(self, menu)
	self.managers.SpawnSearch = SpawnSearch:new(self, menu)
	self.managers.GameOptions = GameOptions:new(self, menu)
	self.managers.SaveOptions = SaveOptions:new(self, menu)

    local prefabs = menu:NewMenu({
        name = "prefabs",
        text = "Prefabs",
        help = "",
    })
end

function MapEditor:mouse_pressed( button, x, y )
    if self._hide_panel:inside(x,y) then
        self._hide_panel:child("text"):set_text(self._hidden and "<" or ">")
        self._menu._panel:set_right(self._hidden and self._menu._panel:w() or 0  )
        self._hidden = not self._hidden
        self._hide_panel:set_left(self._menu._panel:right())
        return
    end
    if not self._menu._panel:inside(x, y) then
        if button == Idstring("0") then
            self.managers.UnitEditor:select_unit()
        elseif button == Idstring("1") then
            self.managers.UnitEditor:select_unit(true)
        end
    end
end

function MapEditor:_select_unit(unit, no_reset)
    self._menu:SwitchMenu(self._menu:GetItem("selected_unit"))
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

function MapEditor:SpawnUnit( unit_path, unit_data, no_reset )
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
        BeardLibEditor:log(unit_path .. " has no unit data...")
		return
    else
		local unit_id = managers.worlddefinition:GetNewUnitID()
        unit:unit_data().name_id = unit_data and unit_data.name_id and unit_data.name_id  .."_".. unit_id  or split[#split] .."_".. unit_id
        unit:unit_data().unit_id = unit_id
        unit:unit_data().name = unit_path
        unit:unit_data().position = unit_data and unit_data.position or unit:position()
        unit:unit_data().rotation = unit_data and unit_data.rotation or unit:rotation()
		unit:unit_data().continent = unit_data and unit_data.continent or "world"
		unit:set_editor_id(unit_id)
    end

    managers.worlddefinition:add_unit(unit, unit:unit_data().continent)
	self:_select_unit(unit, no_reset)
end

function MapEditor:load_continents(continents)
	local continent_items = {}
    for continent_name, _ in pairs(continents) do
        self._menu:GetItem("save_options"):Toggle({
            name = "continent_" .. continent_name,
            text = "Save continent: " .. continent_name,
            help = "",
            index = 5,
            value = true,
        })
		table.insert(continent_items, continent_name)
    end
	self.managers.UnitEditor._menu:GetItem("unit_continent"):SetItems(continent_items)
end

function MapEditor:load_missions(missions)
    for mission_name, _ in pairs(missions) do
	    self._menu:GetItem("save_options"):Toggle({
	        name = "mission_" .. mission_name,
	        text = "Save mission: " .. mission_name,
	        help = "",
            index = 8,
	        value = true,
	    })
    end
end

function MapEditor:show_key_pressed()
	if self._closed then
		self:enable()
		self._menu:enable()
	else
		self:disable()
		self._menu:disable()
	end
	self._closed = not self._closed
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
	self._closed = false
	self._con:disable()
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
	local active_vp = managers.viewport:first_active_viewport()
	if active_vp then
		self._start_cam = active_vp:camera()
		if self._start_cam then
			local pos = self._start_cam:position() - (alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3())
			self:set_camera(pos, self._start_cam:rotation())
		end
	end
	self._closed = true
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

function MapEditor:paused_update(t, dt)
    self:update(t, dt)
end

function MapEditor:update(t, dt)
	for _, manager in pairs(self.managers) do
		if manager.update then
			manager:update(t, dt)
		end
	end

	local brush = Draw:brush(Color(0, 0.5, 0.85))

	if self:enabled() then
		self:update_camera(t, dt)
	end
end

function MapEditor:update_camera(t, dt)
	if self._menu._highlighted or not Input:keyboard():down(Idstring("left shift")) then
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
	local move_delta = move_dir * self._menu:GetItem("camera_speed").value * MOVEMENT_SPEED_BASE * dt
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

function MapEditor:enabled()
	return not self._closed
end
