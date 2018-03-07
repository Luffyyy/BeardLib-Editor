LoadLevelMenu = LoadLevelMenu or class()
function LoadLevelMenu:init()
	local menu = BeardLibEditor.Menu
	self._menu = menu:make_page("Levels", nil, {scrollbar = false})
	MenuUtils:new(self)
	local tabs = self:Menu("Tabs", {align_method = "grid", offset = 0, auto_height = true})
	local opt = {size_by_text = true, group = tabs, offset = 0}
	local w = self:Toggle("Vanilla", callback(self, self, "load_levels"), false, opt).w
	w = w + self:Toggle("Custom", callback(self, self, "load_levels"), true, opt).w
	local search = self:TextBox("Search", callback(self, self, "load_levels"), nil, {w = tabs.w - w, group = tabs, index = 1, control_slice = 0.85, offset = 0})
    local load_options = self:Menu("LoadOptions", {align_method = "grid", h = search:Panel():h(), auto_height = false})
    local half_w = load_options:ItemsWidth() / 3
    self:Toggle("Safemode", nil, false, {group = load_options, w = half_w, offset = 0})
    self:Toggle("CheckLoadTime", nil, false, {group = load_options, w = half_w, offset = 0})
    self:Toggle("LogSpawnedUnits", nil, false, {group = load_options, w = half_w, offset = 0})
	self:Menu("Levels", {align_method = "grid", auto_align = false, offset = 8, h = self._menu:ItemsHeight() - load_options:Bottom() - 16, auto_height = false})
	self:load_levels()
end

local texture_ids = Idstring("texture")
function LoadLevelMenu:load_levels()
	local searching = self:GetItem("Search"):Value()
	local vanilla = self:GetItem("Vanilla"):Value()
	local custom = self:GetItem("Custom"):Value()
    local columns = BeardLibEditor.Options:GetValue("LevelsColumns")
    local loc = self:GetItem("Localized")
    local levels = self:GetItem("Levels")
    levels:ClearItems()
    local loc = managers.localization
    for id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.hidden and narr.contract_visuals and ((narr.custom and custom) or (not narr.custom and vanilla)) then
            local txt = loc:text(narr.name_id or "heist_"..id:gsub("_prof", ""):gsub("_night", "")) .." / " .. id

            local data = narr.contract_visuals.preview_image or {}
            local texture, rect = nil
    
            if data.id then
                texture = "guis/dlcs/" .. (data.folder or "bro") .. "/textures/pd2/crimenet/" .. data.id
                rect = data.rect
            elseif data.icon then
                texture, rect = tweak_data.hud_icons:get_icon_data(data.icon)
            end

            if not texture or not DB:has(texture_ids, texture:id()) then
                texture, rect = nil, nil
            end
            
            local img_size = 100
            local img = levels:Create(texture and "Image" or "Divider", {
                text = "No preview image",
                texture = texture,
                texture_rect = rect,
                background_color = levels.highlight_color or nil,
                text_align = "center",
                text_vertical = "bottom",
                offset_y = 6,
                w = img_size * 1.7777,
                h = img_size
            })

            local narrative = levels:DivGroup({
                foreground = levels.accent_color,
                auto_foreground = false,
                border_bottom = true,
                border_position_below_title = true,
                text = txt,
                w = levels:ItemsWidth() - img:OuterWidth() - 8,
                min_h = 250,
            })

            local has_items
            for _, level in pairs(narr.chain) do
                local id = level.level_id
                if id then
                    local level_t = tweak_data.levels[id]
                    if level_t.world_name then
                        local txt = loc:text(level_t.name_id) .." / " .. id
                        local visible = not searching or searching == "" or txt:match(searching) ~= nil
                        narrative:Button({
                            name = id,
                            auto_foreground = true,
                            background_color = false,
                            vanilla = not level_t.custom,
                            offset = {12, 4},
                            text = txt,
                            visible = visible,
                            callback = callback(self, self, "load_level"),
                            label = "levels",
                        })
                        has_items = has_items or visible
                    end
                end
            end
            if not has_items then
                narrative:Destroy()
                img:Destroy()
            end
        end
    end
    levels:AlignItems(true)
end

function LoadLevelMenu:load_level(menu, item)
    local level_id = item.name
    local safe_mode = self:GetItem("Safemode"):Value()
    local check_load = self:GetItem("CheckLoadTime"):Value()
    local log_on_spawn = self:GetItem("LogSpawnedUnits"):Value()

    local function load()
        Global.editor_mode = true
        Global.editor_safe_mode = safe_mode == true
        Global.check_load_time = check_load == true
        Global.editor_log_on_spawn = log_on_spawn == true
        BeardLib.current_level = nil
        MenuCallbackHandler:play_single_player()
        Global.game_settings.level_id = level_id
        Global.game_settings.mission = "none"
        Global.game_settings.difficulty = "norLogSpawnedUnitsmal"
        Global.game_settings.world_setting = nil
        MenuCallbackHandler:start_the_game()    
        BeardLibEditor.Menu:set_enabled(false)
    end

    local load_tbl = {{"Yes", load}}
    if item.vanilla then
        BeardLibEditor.Utils:QuickDialog({title = "Preview level '" .. tostring(level_id).."'?", message = "Since this is a vanilla heist you can only preview it, clone the heist if you wish to edit the heist!"}, load_tbl)
    elseif safe_mode then
        BeardLibEditor.Utils:QuickDialog({title = "Test level '" .. tostring(level_id).."'?", message = "Safemode is used to access the assets manager when the units fail to load by not spawning them"}, load_tbl)        
    else
        BeardLibEditor.Utils:QuickDialog({title = "Edit level '" .. tostring(level_id).."'?", message = "This will load the level in the editor and will allow you to edit it"}, load_tbl)
    end
end