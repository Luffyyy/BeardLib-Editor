ElementEditor = ElementEditor or class()
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
    dofile(path .. "MissionScriptEditor.lua")
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

function ElementEditor:set_element(element, add)
    local element_editor_class = rawget(_G, element.class:gsub("Element", "Editor"))
    if element_editor_class then
        local new = element_editor_class:new(element.id and element or nil)    
        if add then 
            self._parent:_select_unit(new:add_to_mission())
        end
        new:_build_panel()
        self._current_script = new
        if self._parent:selected_unit() then
            local executors = managers.mission:get_links(self._parent:selected_unit().mission_element)        
            local executors_group = new._elements_menu:ItemsGroup({
                name = "links",
                text = "links",
            })
            for _, element in pairs(executors) do
                new._elements_menu:Button({
                    name = element.editor_name,
                    text = element.editor_name .. " [" .. (element.class or "") .."]",
                    group = executors_group,
                    callback = callback(self, self, "set_element", element)
                })
            end 
        else
            self._current_script = nil
        end

    else
        if element and element.class then
            BeardLibEditor:log("[ERROR] Element class %s has no editor class!", element.class)
        end
    end
end

function ElementEditor:add_element(name)
    self:set_element({class = name}, true)    
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