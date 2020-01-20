---Editor for BeardLib narrative module.
---@class ProjectNarrativeEditor : ProjectModuleEditor
ProjectNarrativeEditor = ProjectNarrativeEditor or class(ProjectModuleEditor)
ProjectEditor.EDITORS.narrative = ProjectNarrativeEditor

local EU = BLE.Utils
local XML = BeardLib.Utils.XML
local DIFFS = {"Normal", "Hard", "Very Hard", "Overkill", "Mayhem", "Death Wish", "Death Sentence"}

--- @param menu ProjectEditor
--- @param data table
function ProjectNarrativeEditor:build_menu(menu, data)
    menu:textbox("NarrName", up, data.id)

    local narr = XML:GetNode(data, "narrative")
    local levels = XML:GetNodes(data, "level")

    local divgroup_opt = {border_position_below_title = true, private = {size = 22}}
    local up = ClassClbk(self, "set_data_callback")
    local contacts = table.map_keys(tweak_data.narrative.contacts)
    menu:combobox("Contact", up, contacts, table.get_key(contacts, data.contact or "custom"))
    menu:textbox("BriefingEvent", up, data.briefing_event)
    data.crimenet_callouts = type(data.crimenet_callouts) == "table" and data.crimenet_callouts or {data.crimenet_callouts}
    data.debrief_event = type(data.debrief_event) == "table" and data.debrief_event or {data.debrief_event}

    menu:textbox("DebriefEvent", up, table.concat(data.debrief_event, ","))
    menu:textbox("CrimenetCallouts", up, table.concat(data.crimenet_callouts, ","))
    menu:button("SetCrimenetVideos", ClassClbk(self, "set_crimenet_videos_dialog"))
    menu:tickbox("HideFromCrimenet", up, data.hide_from_crimenet)

    local chain = menu:divgroup("Chain", divgroup_opt)
    chain:button("AddExistingLevel", ClassClbk(self, "add_exisiting_level_dialog"))
    chain:button("AddNewLevel", ClassClbk(self, "new_level_dialog", ""))
    chain:button("CreateInstance", ClassClbk(self, "new_instance_dialog", ""))
    chain:button("CloneLevel", ClassClbk(self, "new_level_dialog", ""))
    self._levels = chain:divgroup("Levels", {last_y_offset = 6})
    self:build_levels(data, self._levels)

    self._contract_costs = {}
    self._experience_multipliers = {}
    self._max_mission_xps = {}
    self._min_mission_xps = {}
    self._payouts = {}
    local function convertnumber(n)
        local t = {}
        for i=1, #DIFFS do table.insert(t, n) end
        return t
    end
    data.contract_cost = type(data.contract_cost) == "table" and data.contract_cost or convertnumber(data.contract_cost)
    data.experience_mul = type(data.experience_mul) == "table" and data.experience_mul or convertnumber(data.experience_mul)
    data.max_mission_xp = type(data.max_mission_xp) == "table" and data.max_mission_xp or convertnumber(data.max_mission_xp)
    data.min_mission_xp = type(data.min_mission_xp) == "table" and data.min_mission_xp or convertnumber(data.min_mission_xp)
    data.payout = type(data.payout) == "table" and data.payout or convertnumber(data.payout)
    local diff_settings = menu:divgroup("DifficultySettings", divgroup_opt)
    local diff_settings_holder = diff_settings:pan("DifficultySettingsHolder", {
        text_offset_y = 0, align_method = "grid", offset = {diff_settings.offset[1], 0}})

    local diff_settings_opt = {w = diff_settings_holder:ItemsWidth() / (#DIFFS + 1) - 2, offset = {2, 4}, size = 18}
    local diff_settings_texts = diff_settings_holder:divgroup("Setting", diff_settings_opt)

    diff_settings_opt.border_left = false 

    local div_texts_opt = {size_by_text = true, border_left = true, offset = {0, diff_settings_texts.offset[2]}}
    diff_settings_texts:lbl("Contract Cost", div_texts_opt)
    diff_settings_texts:lbl("Payout", div_texts_opt)
    diff_settings_texts:lbl("Maximum XP", div_texts_opt)
    diff_settings_texts:lbl("Minimum XP", div_texts_opt)
    diff_settings_texts:lbl("Stealth XP bonus", div_texts_opt)

    for i, diff in pairs(DIFFS) do
        local group = diff_settings_holder:divgroup(diff, diff_settings_opt)
        local opt = {max = 10000000, min = 0, size_by_text = true, text = "", control_slice = 1, offset = 2}
        self._contract_costs[i] = group:numberbox("ContractCost"..i, up, data.contract_cost[i] or 0, opt)
        self._payouts[i] = group:numberbox("Payout"..i, up, data.payout[i] or 0, opt)
        self._max_mission_xps[i] = group:numberbox("MaxMissionXp"..i, up, data.max_mission_xp[i] or 0, opt)
        self._min_mission_xps[i] = group:numberbox("MinMissionXp"..i, up, data.min_mission_xp[i] or 0, opt)
        opt.max = 5
        self._experience_multipliers[i] = group:numberbox("ExperienceMul"..i, up, data.experience_mul[i] or 0, opt)
    end
end

---Builds buttons for all levels in the chain
function ProjectNarrativeEditor:build_levels(data, levels_group)
    levels_group:ClearItems()
    local function build_level_ctrls(level_in_chain, chain_group, btn, level)
        local narr_chain = chain_group or data.chain
        local my_index = table.get_key(narr_chain, level_in_chain)

        local tx = "textures/editor_icons_df"
        local toolbar = btn
        if level_in_chain.level_id then
            btn:tb_imgbtn(level_in_chain.level_id, ClassClbk(self, "delete_level_dialog", level and level or level_in_chain.level_id), tx, EU.EditorIcons["cross"], {highlight_color = Color.red})
            if chain_group then
                btn:tb_imgbtn("Ungroup", ClassClbk(self, "ungroup_level", narr, level_in_chain, chain_group), tx, EU.EditorIcons["minus"], {highlight_color = Color.red})
            else
                btn:tb_imgbtn("Group", ClassClbk(self, "group_level", narr, level_in_chain), tx, EU.EditorIcons["plus"], {highlight_color = Color.red})
            end
        else
            toolbar = btn:GetToolbar()
        end
        toolbar:tb_imgbtn("MoveDown", ClassClbk(self, "set_chain_index", narr_chain, level_in_chain, my_index + 1), tx, EU.EditorIcons["arrow_down"], {highlight_color = Color.red, enabled = my_index < #narr_chain})
        toolbar:tb_imgbtn("MoveUp", ClassClbk(self, "set_chain_index", narr_chain, level_in_chain, my_index - 1), tx, EU.EditorIcons["arrow_up"], {highlight_color = Color.red, enabled = my_index > 1})
    end
    local function build_level_button(level_in_chain, chain_group, group)
        local level_id = level_in_chain.level_id
        --local level = get_level(level_id)
        local btn = (group or levels_group):button(level_id, level and ClassClbk(self, "edit_main_xml_level", data, level, level_in_chain, chain_group, save_clbk), {
            text = level_id
        })
        return btn, level
    end
    for i, v in ipairs(data.chain) do
        if type(v) == "table" then
            if v.level_id then
                local btn, actual_level = build_level_button(v, false)
                build_level_ctrls(v, false, btn, actual_level)
            else
                local grouped = levels_group:divgroup("Day "..tostring(i).."[Grouped]")
                build_level_ctrls(v, nil, grouped)
                for k, level in pairs(v) do
                    local btn, actual_level = build_level_button(level, v, grouped, k == 1)
                    build_level_ctrls(level, v, btn, actual_level)
                end
            end
        end
    end
    if #levels_group._my_items == 0 then
        levels_group:divider("NoLevelsNotice", {text = "No levels found, sadly."})
    end
end

--- The callback function for all items for this menu.
function ProjectNarrativeEditor:set_data_callback()
    local data = self._data
    data.name = self:GetItemValue("NarrName")
end

---Opens a dialog of all levels in the game to add to the level chain.
function ProjectNarrativeEditor:add_exisiting_level_dialog()
    local levels = {}
    for k, level in pairs(tweak_data.levels) do
        if type(level) == "table" and level.world_name and not string.begins(level.world_name, "wip/") then
            table.insert(levels, {name = k .. " / " .. managers.localization:text(level.name_id or k), id = k})
        end
    end
    BLE.ListDialog:Show({
        list = levels,
        callback = function(seleciton)
            local chain = self._data.chain
            table.insert(chain, {level_id = seleciton.id, type = "d", type_id = "heist_type_assault"})
            BLE.ListDialog:hide()
            self:build_levels(self._data, self._levels)
        end
    })
end