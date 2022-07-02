GeneralToolEditor = GeneralToolEditor or class(ToolEditor)

local difficulty_ids = {"normal", "hard", "overkill", "overkill_145", "easy_wish", "overkill_290", "sm_wish"}
local difficulty_loc = {
	"menu_difficulty_normal",
	"menu_difficulty_hard",
	"menu_difficulty_very_hard",
	"menu_difficulty_overkill",
	"menu_difficulty_easy_wish",
	"menu_difficulty_apocalypse",
	"menu_difficulty_sm_wish"
}

local GenTool = GeneralToolEditor
function GenTool:init(parent)
	GenTool.super.init(self, parent, "GeneralToolEditor")
end

function GenTool:build_menu()
    self._holder:ClearItems()
    local groups_opt = {align_method = "grid", control_slice = 0.5}
    local opt = self:GetPart("opt")

    local editors = self._holder:divgroup("Editors")
    editors:button("EffectEditor", ClassClbk(self, "open_effect_editor"))

    local game = self._holder:group("Game", groups_opt)
    game:slider("GameSpeed", ClassClbk(self, "set_game_speed"), 1, {max = 10, min = 0.1, step = 0.3, floats = 1, wheel_control = true, help = "High settings can have a negative effect on game logic, use with caution"})
    game:combobox("Difficulty", ClassClbk(self, "set_difficulty"), difficulty_loc, table.get_key(difficulty_ids, Global.game_settings.difficulty), {items_localized = true, items_pretty = true})
    game:numberbox("MissionFilter", ClassClbk(self, "set_mission_filter"), Global.current_mission_filter or 0, {floats = 0, min = 0, max = 5, help = "Set a mission filter to be forced on the level, 0 uses the default filter."})
    game:tickbox("PauseGame", ClassClbk(self, "pause_game"), false, {size_by_text = true})
    game:tickbox("MuteMusic", ClassClbk(self, "mute_music"), false, {size_by_text = true})
    game:button("FlushMemory", ClassClbk(Application, "apply_render_settings"), {size_by_text = true, help = "Clears unused textures from memory (has a small chance to break things)"})

    local other = self._holder:group("Other", groups_opt)
    other:s_btn("LogPosition", ClassClbk(self, "position_debug"))
    if BeardLib.current_level then
        other:s_btn("OpenMapInExplorer", ClassClbk(self, "open_in_explorer"))
    end
    other:s_btn("OpenLevelInExplorer", ClassClbk(self, "open_in_explorer", true))
    other:tickbox("UseLight", ClassClbk(opt, "toggle_light"), false, {text = "Head Light", help = "Turn head light on / off"})

    self._breakdown = self._holder:group("LevelBreakdown", groups_opt)
    self:build_level_breakdown()

    self._built = true
end

function GenTool:set_visible(visible)
    GenTool.super.set_visible(self, visible)
    if visible then
        self:build_level_breakdown()
    end
end

function GenTool:open_effect_editor()
    managers.editor._particle_editor_active = true
    managers.editor:set_enabled()
end

function GenTool:pause_game(item) 
    local paused = item:Value()
    Application:set_pause(paused) 
    SoundDevice:set_rtpc("ingame_sound", paused and 0 or 1)
end

function GenTool:set_mission_filter(item) 
    local filter = item:Value()
    Global.current_mission_filter = filter > 0 and filter or nil
    managers.mission:set_mission_filter({Global.current_mission_filter})
end

function GenTool:mute_music(item) 
    local mute = item:Value()

	if mute then
        SoundDevice:set_rtpc("option_music_volume", 0)
	else
        SoundDevice:set_rtpc("option_music_volume", Global.music_manager.volume * 100)
	end
end

function GenTool:set_game_speed(item) 
    local value = item:Value()
	TimerManager:pausable():set_multiplier(value)
	TimerManager:game_animation():set_multiplier(value)
end

function GenTool:set_difficulty(item) 
    local difficulty = item:Value()
    Global.game_settings.difficulty = difficulty_ids[difficulty] or "normal"
    tweak_data.character:init(tweak_data)
    tweak_data:set_difficulty()
end

function GenTool:position_debug()
    BLE:log("Camera Position: %s", tostring(managers.editor._camera_pos))
	BLE:log("Camera Rotation: %s", tostring(managers.editor._camera_rot))
end

function GenTool:open_in_explorer(world_path)
    local opt = self:GetPart("opt")
    Application:shell_explore_to_folder(string.gsub(world_path == true and opt:map_world_path() or opt:map_path(), "/", "\\"))
end

function GenTool:build_level_breakdown()
    local icons = BLE.Utils.EditorIcons
    local opt = {size = self._holder.size * 0.9, inherit_values = {size = self._holder.size * 0.9, border_color = Color.green}, private = {full_bg_color = false, background_color = false}}

    self._breakdown:ClearItems()
    local tb =  self._breakdown:GetToolbar()
    tb:tb_imgbtn("Refresh", ClassClbk(self, "build_level_breakdown"), nil, icons.reset_settings, {help = "Recalculate List"})

    local units_group = self._breakdown:divgroup("TotalUnits", opt)
    tb = units_group:GetToolbar()
    tb:tb_imgbtn("UnitSummary", ClassClbk(self, "create_level_summary"), nil, icons.list, {help = "Create Unit Summary"})
    local elements_group = self._breakdown:divgroup("TotalElements", opt)
    tb = elements_group:GetToolbar()
    tb:tb_imgbtn("ElementSummary", ClassClbk(self, "create_level_summary"), nil, icons.list, {help = "Create Element Summary"})
    local instances_group = self._breakdown:divgroup("TotalInstances", opt)
    tb = instances_group:GetToolbar()
    tb:tb_imgbtn("InstanceSummary", ClassClbk(self, "create_level_summary"), nil, icons.list, {help = "Create Instance Summary"})

    local total_units = 0
    local total_elements = 0
    local total_instances = 0

    local cont_id = managers.worlddefinition._start_id
    local continents = managers.worlddefinition._continent_definitions
    for _, continent in ipairs(managers.editor._continents) do
        if continents[continent] then
            local statics = continents[continent].statics and #continents[continent].statics or 0
            units_group:divider(continent, {text = continent..": "..statics.." / "..cont_id})
            total_units = total_units + statics

            for name, data in pairs(managers.mission._missions[continent]) do
                local elements = data.elements and #data.elements or 0
                local instances = data.instances and #data.instances or 0
    
                elements_group:divider(name, {text = name..": "..elements})
                total_elements = total_elements + elements
                total_instances = total_instances + instances
            end
        end
    end
    units_group:SetText("Total Units: "..total_units)
    elements_group:SetText("Total Elements: "..total_elements)
    instances_group:SetText("Total Instances: "..total_instances)
end

function GenTool:create_level_summary(item)
    local entries = {}
    local function add_entry(name, group)
        group = group or ""
        if entries[group] and entries[group][name] then
            entries[group][name] = entries[group][name] + 1
        else
            entries[group] = entries[group] or {}
            entries[group][name] = 1
        end
    end

    local type = item:Name()
    if type == "UnitSummary" then
        for _, unit in pairs(World:find_units_quick("disabled", "all")) do
            local ud = unit:unit_data()
            if ud and ud.name then
                add_entry(ud.name, ud.continent)
            end
        end
    elseif type == "ElementSummary" then
        for _, element in ipairs(self:GetPart("mission"):units()) do
            local mission = element:mission_element()
            if mission then
                add_entry(mission.element.class, mission.element.script)
            end
        end
    elseif type == "InstanceSummary" then
        for _, name in pairs(managers.world_instance:instance_names()) do
            local data = managers.world_instance:get_instance_data_by_name(name)
            add_entry(data.folder, data.continent.." - "..data.script)
        end
    end

    local list = {}
    for group_name, group in pairs(entries) do
        for name, times in pairs(group) do
            if type == "ElementSummary" then name = string.pretty2(name:gsub("Element", ""):gsub("Editor", "")) end
            table.insert(list, {name = string.format("%s (%d)", name, times), create_group = group_name, times = times})
        end
    end
    table.sort(list, function(a, b)
        return a.times > b.times
    end)
    BLE.ListDialog:Show({
		list = list,
        sort = false
	})
end