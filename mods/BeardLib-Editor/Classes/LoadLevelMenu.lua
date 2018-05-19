LoadLevelMenu = LoadLevelMenu or class()

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

function LoadLevelMenu:init()
	local menu = BeardLibEditor.Menu
	self._menu = menu:make_page("Levels", nil, {scrollbar = false})
	MenuUtils:new(self)
	local tabs = self:Menu("Tabs", {align_method = "grid", offset = 0, auto_height = true})
	local opt = {size_by_text = true, group = tabs, offset = 0}
	local w = self:Toggle("Vanilla", ClassClbk(self, "load_levels"), false, opt).w
	w = w + self:Toggle("Custom", ClassClbk(self, "load_levels"), true, opt).w
	local search = self:TextBox("Search", ClassClbk(self, "search_levels"), nil, {w = tabs.w - w, group = tabs, index = 1, control_slice = 0.85, offset = 0})
    local load_options = self:Menu("LoadOptions", {align_method = "grid", auto_height = true, inherit_values = {offset = 0}})
    local half_w = load_options:ItemsWidth() / 2
    local third_w = load_options:ItemsWidth() / 3
	self:ComboBox("Difficulty", nil, difficulty_loc, 1, {group = load_options, items_localized = true, items_pretty = true, w = half_w, offset = 0})
	self:Toggle("OneDown", nil, false, {group = load_options, w = half_w, offset = 0})
    self:Toggle("Safemode", nil, false, {group = load_options, w = third_w})
    self:Toggle("CheckLoadTime", nil, false, {group = load_options, w = third_w})
	self:Toggle("LogSpawnedUnits", nil, false, {group = load_options, w = third_w})
	self._levels = self:Menu("Levels", {auto_align = false, offset = 8, h = self._menu:ItemsHeight() - load_options:Bottom() - 16, auto_height = false})
	self:load_levels()
end

function LoadLevelMenu:search_levels(item)
	item = item or self:GetItem("Search")
	local search = item:Value()
	for _, menu in pairs(self._levels:Items()) do
		if menu.type_name == "Menu" then
			for _, item in pairs(menu:Items()) do
				if item.type_name == "Group" then
					menu:SetVisible(false)
					if item.text:find(search) then
						menu:SetVisible(true)
					else
						for _, _item in pairs(item:Items()) do
							if _item.text:find(search) then
								menu:SetVisible(true)
								break
							end
						end
					end
				end
			end
		end
	end
	self._levels:AlignItems(true)
end

local texture_ids = Idstring("texture")
function LoadLevelMenu:load_levels()
	local vanilla = self:GetItem("Vanilla"):Value()
	local custom = self:GetItem("Custom"):Value()
    local columns = BeardLibEditor.Options:GetValue("LevelsColumns")
    local loc = self:GetItem("Localized")
    local levels = self:GetItem("Levels")
    levels:ClearItems()
    local loc = managers.localization
    local img_size = 100
    local img_w, img_h = img_size * 1.7777, img_size
    for narr_id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.hidden and narr.contract_visuals and ((narr.custom and custom) or (not narr.custom and vanilla)) then
            local txt = loc:text(narr.name_id or "heist_"..narr_id:gsub("_prof", ""):gsub("_night", "")) .." / " .. narr_id

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
			
			local holder = levels:Menu({
				name = narr_id.."_holder",
				auto_height = true,
				offset = 4,
				visible = false,
				auto_foreground = false,
				align_method = "grid",
				auto_align = false,
                min_h = 250,
			})
			
            local img_size = 100
            local img = holder:Create(texture and "Image" or "Divider", {
                text = "No preview image",
                texture = texture,
                texture_rect = rect,
                background_color = levels.highlight_color or nil,
                text_align = "center",
                text_vertical = "bottom",
                offset_y = 6,
                w = img_w,
                h = img_h
            })

            local narrative = holder:DivGroup({
                foreground = levels.accent_color,
                auto_align = false,
				border_bottom = true,
				auto_foreground = true,
                border_position_below_title = true,
                text = txt,
                w = holder:ItemsWidth() - img:OuterWidth() - holder:OffsetX(),
                min_h = 250,
            })

            local has_items
			local function level_button(id, day)
				local level_t = tweak_data.levels[id]
				if level_t and level_t.world_name then
					self:Button(id, ClassClbk(self, "load_level"), {
						text = loc:text(level_t.name_id) .." / " .. id,
						name = id,
						narr_id = narr_id,
						vanilla = not level_t.custom,
						offset = {12, 4},
						group = day or narrative,
						label = "levels",
					})
					has_items = true
				end
			end
			for i, level in pairs(narr.chain) do
				if type(level) == "table" then
					local id = level.level_id
					if id then
						level_button(id)
					elseif #level > 0 then
						local day = self:DivGroup("Day #"..tostring(i), {group = narrative})
						for _, grouped_level in pairs(level) do
							id = grouped_level.level_id
							if id then
								level_button(id, day)
							end
						end
					end
				end
            end
            if not has_items then
                narrative:Destroy()
                img:Destroy()
            end
        end
    end
	self:search_levels()
end

function LoadLevelMenu:load_level(item)
	local level_id = item.name
	local narr_id = item.narr_id
    local safe_mode = self:GetItem("Safemode"):Value()
    local check_load = self:GetItem("CheckLoadTime"):Value()
    local log_on_spawn = self:GetItem("LogSpawnedUnits"):Value()
    local one_down = self:GetItem("OneDown"):Value()
    local difficulty = self:GetItem("Difficulty"):Value()

    local function load()
        Global.editor_mode = true
        Global.editor_safe_mode = safe_mode == true
        Global.check_load_time = check_load == true
        Global.editor_log_on_spawn = log_on_spawn == true
        BeardLib.current_level = nil
		MenuCallbackHandler:play_single_player()
		--if narr_id then
		--	managers.job:activate_job(narr_id)
		--end
        Global.game_settings.level_id = level_id
        Global.game_settings.mission = "none"
		Global.game_settings.difficulty = difficulty_ids[difficulty] or "normal"
		Global.game_settings.one_down = one_down
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