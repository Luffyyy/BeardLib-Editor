ElementEditor = ElementEditor or class(EditorPart)
ElementEditor._mission_elements = {   
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

function ElementEditor:init(parent, menu)
    local path = BeardLibEditor.ModPath .. "Classes/EditorParts/Elements/"
    for _, file in pairs(file.GetFiles(path)) do
        dofile(path .. file)
    end    
    self._parent = parent
    self._trigger_ids = {}
end
function ElementEditor:select_exisiting_elmenet()
    self._parent.managers.SpawnSearch:load_all_mission_elements()
end
function ElementEditor:create_new_elmenet()
    self._parent.managers.SpawnSearch:show_elements_list()
end
function ElementEditor:enabled()
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("g"), callback(self, self, "KeyGPressed")))
end

function ElementEditor:disabled()
    for _, id in pairs(self._trigger_ids) do
        Input:keyboard():remove_trigger(id)
    end

    self._trigger_ids = {}
end 

function ElementEditor:get_editor_class(class)
    return rawget(_G, class:gsub("Element", "Editor"))
end

function ElementEditor:set_element(element)
    if element then
        local clss = self:get_editor_class(element.class) 
        if clss then
            local script = clss:new(element)    
            script:work()
            self._current_script = script
            if not self._parent:selected_unit() then
                self._current_script = nil
            end
        else
            if element.class then
                BeardLibEditor:log("[ERROR] Element class %s has no editor class(Report this)", element.class)
            end
        end
    else
        BeardLibEditor:log("[ERROR] Nil element!")
    end
end

function ElementEditor:add_element(name)
    local clss = self:get_editor_class(name) 
    if clss then
        self:Manager("StaticEditor"):set_selected_unit(clss:init())    
    else
        BeardLibEditor:log("[ERROR] Element class %s has no editor class(Report this)", name)
    end
end
 
function ElementEditor:update(t, dt)
    if self._parent:selected_unit() and self._parent:selected_unit().mission_element and self._current_script and self._current_script.update then
        self._current_script:update(t, dt)
    end   
end
 
function ElementEditor:KeyGPressed(button_index, button_name, controller_index, controller, trigger_id)
    if not self._parent._menu._highlighted and Input:keyboard():down(Idstring("left ctrl")) then
        if self._parent._selected_element then
            self._parent:set_camera(self._parent._selected_element.values.position)
        end
    end
end