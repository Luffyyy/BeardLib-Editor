---Editor for BeardLib narrative module.
---@class ProjectNarrativeEditor : ProjectModuleEditor
ProjectNarrativeEditor = ProjectNarrativeEditor or class(ProjectModuleEditor)
ProjectEditor.EDITORS.narrative = ProjectNarrativeEditor
ProjectEditor.ACTIONS["CloneHeist"] = function(parent, create_data)
    local levels = {}
    for id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.custom and not narr.hidden then
            --dunno why the name_id is nil for some of them..
            table.insert(levels, {name = id.." / " .. managers.localization:text((narr.name_id or ("heist_"..id)):gsub("_prof", ""):gsub("_night", "")), id = id})
        end
    end
    BLE.ListDialog:Show({
        list = levels,
        callback = function(selection)
            BLE.ListDialog:hide()
            ProjectNarrativeEditor:new(parent, nil, table.merge({clone_id = selection.id}, create_data))
        end
    })
end

local EU = BLE.Utils
local XML = BeardLib.Utils.XML
local DIFFS = {"Normal", "Hard", "Very Hard", "Overkill", "Mayhem", "Death Wish", "Death Sentence"}

--- @param menu ProjectEditor
--- @param data table
function ProjectNarrativeEditor:build_menu(menu, data)
    local up = ClassClbk(self, "set_data_callback")

    data.orig_id = data.orig_id or data.id
    menu:textbox("NarrativeID", up, data.id)

    local divgroup_opt = {border_position_below_title = true, private = {size = 22}}
    local contacts = table.map_keys(tweak_data.narrative.contacts)
    menu:combobox("Contact", up, contacts, table.get_key(contacts, data.contact or "custom"))
    menu:textbox("BriefingEvent", up, data.briefing_event)
    data.crimenet_callouts = type(data.crimenet_callouts) == "table" and data.crimenet_callouts or {data.crimenet_callouts}
    data.debrief_event = type(data.debrief_event) == "table" and data.debrief_event or {data.debrief_event}

    menu:textbox("DebriefEvent", up, table.concat(data.debrief_event, ","))
    menu:textbox("CrimenetCallouts", up, table.concat(data.crimenet_callouts, ","))
    menu:button("SetCrimenetVideos", ClassClbk(self, "set_crimenet_videos_dialog"))
    menu:tickbox("HideFromCrimenet", up, data.hide_from_crimenet)

    local icon_group = menu:divgroup("Icon", divgroup_opt)
    icon_group:button("SelectIconFromDisk", ClassClbk(self, "SelectIconFromDisk"))
    icon_group:pathbox("Icon", up, data.icon, "texture", {text = "Icon Path"})
    icon_group:divider("IconHelp", {
        text = "If no icon is defined, the icon is automatically loaded assets/guis/textures/mods/icons ([ID].png or [ID].texture)"
        ..". Use the button on top to easily select the icon from disk."
    })

    local chain = menu:divgroup("Chain", divgroup_opt)
    chain:button("AddExistingLevel", ClassClbk(self, "add_exisiting_level_dialog"))
    chain:button("AddNewLevel", function()
        ProjectEditor.EDITORS.level:new(self._parent, nil, {chain = data.chain})
    end)
    chain:button("CloneLevel", function()
        ProjectEditor.ACTIONS["CloneSingleLevel"](self._parent, {chain = data.chain})
    end)
    self._levels = chain:divgroup("Levels")
    self:build_levels(data)

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

function ProjectNarrativeEditor:SelectIconFromDisk()
    local base_path = Path:Normalize(Application:base_path())

    BLE.FBD:Show({
        where = base_path,
        extensions = {"texture", "png"},
        file_click = function(path)
            local af = self._parent:get_module_by_meta("AddFiles")
            local icon = Path:Combine(self._parent:get_dir(), af and af.directory or "assets", "guis/textures/mods/icons", "narr_"..self._data.id)
            FileIO:Delete(icon..".png")
            FileIO:Delete(icon..".texture")
            FileIO:CopyFile(path, icon..'.'..Path:GetFileExtension(path))
            self._data.icon = nil
            self._parent:save_data_callback()
            BLE.FBD:Hide()
        end
    })
end

function ProjectNarrativeEditor:create(create_data)
    BLE.InputDialog:Show({
        title = "Enter a name for the narrative",
        yes = "Create",
        text = create_data.name or "",
        check_value = function(name)
            local warn
            for k in pairs(tweak_data.narrative.jobs) do
                if string.lower(k) == name:lower() then
                    warn = string.format("A narrative with the id %s already exists! Please use a unique id", k)
                end
            end
            if name == "" then
                warn = string.format("Id cannot be empty!", name)
            elseif string.begins(name, " ") then
                warn = "Invalid ID!"
            end
            if warn then
                BLE.Utils:Notify("Error", warn)
            end
            return warn == nil
        end,
        no_callback = function()
            if create_data.final_callback then
                create_data.final_callback(false)
            end
        end,
        callback = function(name)
            local template
            template = deep_clone(BLE.MapProject._narr_module_template)
            template.id = name

            if create_data.clone_id then
                table.merge(template, deep_clone(tweak_data.narrative.jobs[create_data.clone_id]))
                local cv = template.contract_visuals
                local preview = cv.preview_image
                if preview.icon then
                    local icon = tweak_data.hud_icons[preview.icon]
                    if icon then
                        template.icon = icon.texture
                    end
                elseif preview.id then
                    template.icon = "guis/dlcs/" .. (preview.folder or "bro") .. "/textures/pd2/crimenet/" .. preview.id
                end
                template.max_mission_xp = cv and cv.max_mission_xp or template.max_mission_xp
                template.min_mission_xp = cv and cv.min_mission_xp or template.min_mission_xp
                template.contract_visuals = nil
                template.name_id = nil
                template.briefing_id = nil
                template.package = nil --packages should only be in levels.

                local already_cloned = {}
                local taken_names = {}
                local function clone_level(chain_level, last)
                    local id = chain_level.level_id

                    --If we already cloned it then just update the ID, if it's last then finalize creation.
                    if already_cloned[id] then
                        chain_level[id].level_id = already_cloned[id].level_id
                        if last then
                            self:finalize_creation(template, create_data)
                        end
                        return
                    end
                    --We try to clone each level, final_callback will call regardless if the user decided to cancel the input dialog or not. So the last one should at least call.
                    --We disable reloading so we can clone all levels without issues. Plus only reload it once after we're done entirely.
                    ProjectLevelEditor:new(self._parent, nil, {clone_id = id, chain_level = chain_level, taken_names = taken_names, no_reload = true, final_callback = last and function(success)
                        if success then
                            already_cloned[id] = chain_level
                        end
                        self:finalize_creation(template, create_data)
                    end})
                end
                if #template.chain > 0 then
                    for i, level_in_chain in pairs(template.chain) do
                        local last = i == #template.chain
                        if type(level_in_chain) == "table" then
                            if #level_in_chain > 0 then
                                for ii, inner_level in pairs(level_in_chain) do
                                    clone_level(inner_level, last and ii == #level_in_chain)
                                end
                            else
                                clone_level(level_in_chain, last)
                            end
                        end
                    end
                else
                    self:finalize_creation(template, create_data)
                end
            else
                self:finalize_creation(template, create_data)
            end
        end
    })
end

---Builds buttons for all levels in the chain
function ProjectNarrativeEditor:build_levels()
    local levels_group = self._levels
    local data = self._data
    local current_id = (BeardLib.current_level and BeardLib.current_level._config.id or nil)
    levels_group:ClearItems()
    local function build_level_ctrls(level_in_chain, chain_group, btn, level)
        local narr_chain = chain_group or data.chain
        local my_index = table.get_key(narr_chain, level_in_chain)

        local tx = "textures/editor_icons_df"
        local toolbar = btn
        if level_in_chain.level_id then
            local is_current = current_id == level_in_chain.level_id
            if is_current then
                self._deletable = false
                self._menu:GetItem("NarrativeID"):SetEnabled(false)
            end
            btn:tb_imgbtn(level_in_chain.level_id, ClassClbk(self, "delete_chain_level_dialog", level_in_chain), tx, EU.EditorIcons["cross"], {highlight_color = Color.red, enabled = not is_current})
            if chain_group then
                btn:tb_imgbtn("Ungroup", ClassClbk(self, "ungroup_level", level_in_chain, chain_group), tx, EU.EditorIcons["minus"], {help = "Group level", highlight_color = Color.red})
            else
                btn:tb_imgbtn("Group", ClassClbk(self, "group_level", level_in_chain), tx, EU.EditorIcons["plus"], {help = "Ungroup level", highlight_color = Color.red})
            end
        else
            toolbar = btn:GetToolbar()
        end
        toolbar:tb_imgbtn("MoveDown", ClassClbk(self, "set_chain_index", narr_chain, level_in_chain, my_index + 1), tx, EU.EditorIcons["arrow_down"], {highlight_color = Color.red, enabled = my_index < #narr_chain})
        toolbar:tb_imgbtn("MoveUp", ClassClbk(self, "set_chain_index", narr_chain, level_in_chain, my_index - 1), tx, EU.EditorIcons["arrow_up"], {highlight_color = Color.red, enabled = my_index > 1})
    end
    local function build_level_button(level_in_chain, chain_group, group)
        local level_id = level_in_chain.level_id
        local mod = self._parent:get_module(level_id, "level")
        local parent = (group or levels_group)
        local btn = parent:button(level_id, mod and ClassClbk(self._parent, "open_module", mod), {text = level_id, divider_type = mod == nil})
        return btn, level_id
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

--- Deletes a level from a chain
--- @param level_in_chain table
function ProjectNarrativeEditor:delete_chain_level_dialog(level_in_chain)
    EU:YesNoQuestion("Delete level from chain?", function()
        local chain = self._data.chain
        local success
        for k, v in ipairs(chain) do
            if success then
                break
            end
            if v == level_in_chain then
                table.remove(chain, k)
                break
            else
                for i, level in pairs(v) do
                    if level == level_in_chain then
                        table.remove(v, i)
                        success = true
                        break
                    end
                end
            end
        end
        self:build_levels()
    end)
end

--- Removes a level from a group
--- @param level_in_chain table
--- @param chain_group table
function ProjectNarrativeEditor:ungroup_level(level_in_chain, chain_group)
    table.delete_value(chain_group, level_in_chain)
    if #chain_group == 1 then
        self._data.chain[table.get_key(self._data.chain, chain_group)] = chain_group[1]
    end
    table.insert(self._data.chain, level_in_chain)
end

--- Opens a dialog to choose levels to group with.
--- @param level_in_chain table
function ProjectNarrativeEditor:group_level(level_in_chain)
    local chain = {}
    local data = self._data
    for i, v in ipairs(data.chain) do
        if v ~= level_in_chain then
            table.insert(chain, {name = v.level_id or ("Day "..tostring(i).."[Grouped]"), value = v})
        end
    end
    BLE.ListDialog:Show({
        list = chain,
        callback = function(selection)
            table.delete_value(data.chain, level_in_chain)
            local key = table.get_key(data.chain, selection.value)
            local chain_group = selection.value
            if chain_group.level_id then
                data.chain[key] = {chain_group}
            end
            table.insert(data.chain[key], level_in_chain)
            BLE.ListDialog:hide()
            self:build_levels()
        end
    })
end

--- Sets the index of a level in a narrative chain
--- @param chain table
--- @param level_in_chain table
--- @param index number
function ProjectNarrativeEditor:set_chain_index(chain, level_in_chain, index)
    local key = table.get_key(chain, level_in_chain)

    table.remove(chain, tonumber(key))
    table.insert(chain, tonumber(index), level_in_chain)

    self:build_levels()
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
            self:build_levels(self._data)
        end
    })
end

--- Open a dialog to select crimenet videos for the narrative
function ProjectNarrativeEditor:set_crimenet_videos_dialog()
    BLE.SelectDialog:Show({
        selected_list = self._data.crimenet_videos,
        list = EU:GetEntries({type = "movie", check = function(entry)
            return entry:match("movies/")
        end}),
        callback = function(list) self._data.crimenet_videos = list end
    })
end

--- The callback function for all items for this menu.
function ProjectNarrativeEditor:set_data_callback()
    local data = self._data

    local name_item = self:GetItem("NarrativeID")
    local new_name = name_item:Value()
    local title = "Narrative ID"
    if data.id ~= new_name then
        local exists = false
        for _, mod in pairs(self._parent:get_modules("narrative")) do
            if mod.id == new_name then
                exists = true
            end
        end
        if exists or new_name == "" or (data.orig_id ~= new_name and tweak_data.narrative.jobs[new_name]) then
            title = title .. "[Invalid]"
        else
            data.id = new_name
        end
    end

    name_item:SetText(title)

    for i in pairs(DIFFS) do
        data.contract_cost[i] = self._contract_costs[i]:Value()
        data.experience_mul[i] = self._experience_multipliers[i]:Value()
        data.max_mission_xp[i] = self._max_mission_xps[i]:Value()
        data.min_mission_xp[i] = self._min_mission_xps[i]:Value()
        data.payout[i] = self._payouts[i]:Value()
    end

    data.crimenet_callouts = data.crimenet_callouts or {}
    data.debrief_event = data.debrief_event or {}
    local callouts = self:GetItemValue("CrimenetCallouts")
    local events = self:GetItemValue("DebriefEvent")
    data.crimenet_callouts = callouts:match(",") and string.split(callouts, ",") or {callouts}
    data.debrief_event = events:match(",") and string.split(events, ",") or {events}
    data.briefing_event = self:GetItemValue("BriefingEvent")
    data.contact = self:GetItem("Contact"):SelectedItem()
    data.icon = self:GetItem("Icon"):Value()
    if data.icon == "" then
        data.icon = nil
    end
    data.hide_from_crimenet = self:GetItemValue("HideFromCrimenet")
end

function ProjectNarrativeEditor:save_data()
    local narr = self._data
    local orig_id = narr.orig_id or narr.id -- Narrative ID has been changed, let's delete the old ID.
    if orig_id ~= narr.id then
        tweak_data.narrative.jobs[orig_id] = nil
        table.delete(tweak_data.narrative._jobs_index, orig_id)

        local af = self._parent:get_module_by_meta("AddFiles")
        local icon = Path:Combine(self._parent:get_dir(), af and af.directory or "assets", "guis/textures/mods/icons", "narr_")

        -- Move old icon
        FileIO:MoveTo(icon .. orig_id..".png", icon .. narr.id..".png")
        FileIO:MoveTo(icon .. orig_id..".texture", icon .. narr.id..".texture")
    end
    narr.orig_id = nil
    return ProjectNarrativeEditor.super.save_data(self)
end