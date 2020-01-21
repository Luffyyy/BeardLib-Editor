---Editor for BeardLib level module.
---@class ProjectLevelEditor : ProjectModuleEditor
ProjectLevelEditor = ProjectLevelEditor or class(ProjectModuleEditor)
ProjectEditor.EDITORS.level = ProjectLevelEditor

--- @param menu Menu
--- @param data table
function ProjectLevelEditor:build_menu(menu, data)
    local up = ClassClbk(self, "set_data_callback")

    data.orig_id = data.orig_id or data.id
    menu:textbox("LevelID", up, data.id)
    menu:textbox("BriefingDialog", up, data.briefing_dialog)
    data.intro_event = type(data.intro_event) == "table" and data.intro_event[1] or data.intro_event
    data.outro_event = type(data.outro_event) == "table" and data.outro_event or {data.outro_event}

    menu:textbox("IntroEvent", up, data.intro_event)
    menu:textbox("OutroEvent", up, table.concat(data.outro_event, ","))
    menu:numberbox("GhostBonus", up, data.data or 0, {max = 1, min = 0, step = 0.1})
    menu:numberbox("MaxBags", up, data.max_bags, {max = 999, min = 0, floats = 0})

    local aitype = table.map_keys(LevelsTweakData.LevelType)
    menu:combobox("AiGroupType", up, aitype, table.get_key(aitype, data.ai_group_type) or 1)

    local styles = table.map_keys(tweak_data.scene_poses.player_style)
    menu:combobox("PlayerStyle", up, styles, table.get_key(styles, data.player_style or "generic"), {
        help = "Set the player style for the map, make sure the packages for the suits are loaded!"
    })
    menu:tickbox("TeamAiOff", up, data.team_ai_off)
    menu:tickbox("RetainBags", up, data.repossess_bags)
    menu:tickbox("PlayerInvulnerable", up, data.player_invulnerable)
    menu:button("ManageMissionAssets", ClassClbk(self, "set_mission_assets_dialog"))

    if data.ghost_bonus == 0 then
        data.ghost_bonus = nil
    end
end

--- Opens a dialog for editing the mission assets of a level
function ProjectLevelEditor:set_mission_assets_dialog()
    local data = self._data
	local selected_assets = {}
	data.assets = data.assets or {_meta = "assets"}
    for _, asset in pairs(data.assets) do
        if type(asset) == "table" and asset._meta == "asset" then
            table.insert(selected_assets, {name = asset.name, value = asset.exclude == true})
        end
    end
    local assets = {}
	for _, asset in pairs(table.map_keys(tweak_data.assets)) do
		if asset.stages ~= "all" then
			table.insert(assets, {name = asset, value = false})
		end
    end
	BLE.SelectDialogValue:Show({
		selected_list = selected_assets,
		list = assets,
		values_name = "Exclude",
        values_list_width = 100,
		callback = function(list)
            local new_assets = {}
            for _, asset in pairs(list) do
                table.insert(new_assets, {_meta = "asset", name = asset.name, exclude = asset.value == true and true or nil})
            end
            data.assets = new_assets
        end
	})
end

--- The callback function for all items for this menu.
function ProjectLevelEditor:set_data_callback()
    local data = self._data

    local name_item = self:GetItem("LevelID")
    local new_name = name_item:Value()
    local title = "Level ID"
    if data.id ~= new_name then
        local exists = false
        for _, mod in pairs(self._parent:get_modules("level")) do
            if mod.id == new_name then
                exists = true
            end
        end
        if exists or new_name == "" or (data.orig_id ~= new_name and tweak_data.levels[new_name]) then
            title = title .. "[Invalid]"
        else
            for _, mod in pairs(self._parent:get_modules()) do
                if mod._meta == "narrative" then
                    if mod.chain then
                        for _, level in ipairs(mod.chain) do
                            if level.level_id == data.id then
                                level.level_id = new_name
                                break
                            else
                                for i, inner_level in pairs(level) do
                                    if inner_level.level_id == data.id then
                                        inner_level.level_id = new_name
                                    end
                                end
                            end
                        end
                    end
                end
            end
            data.id = new_name
        end
    end
    name_item:SetText(title)

    data.ai_group_type = self:GetItem("AiGroupType"):SelectedItem()
    data.player_style = self:GetItem("PlayerStyle"):SelectedItem()
    data.briefing_dialog = self:GetItem("BriefingDialog"):Value()
    data.ghost_bonus = self:GetItem("GhostBonus"):Value()
    if data.ghost_bonus == 0 then
        data.ghost_bonus = nil
    end
    data.max_bags = self:GetItem("MaxBags"):Value()
    data.team_ai_off = self:GetItem("TeamAiOff"):Value()
    data.intro_event = self:GetItem("IntroEvent"):Value()
    data.repossess_bags = self:GetItem("RetainBags"):Value()
    data.player_invulnerable = self:GetItem("PlayerInvulnerable"):Value()
    local outro = self:GetItem("OutroEvent"):Value()
    data.outro_event = outro:match(",") and string.split(outro, ",") or {outro}
end

function ProjectLevelEditor:delete()
    local id = self._data.id
    for _, mod in pairs(self._parent:get_modules("narrative")) do
        if mod.chain then
            for _, level in ipairs(mod.chain) do
                if level.level_id == id then
                    table.delete_value(mod.chain, level)
                    break
                else
                    for i, inner_level in pairs(level) do
                        if inner_level.level_id == id then
                            table.delete_value(level, inner_level)
                        end
                    end
                end
            end
        end
    end
end