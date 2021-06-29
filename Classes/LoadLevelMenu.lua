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

function LoadLevelMenu:init(data)
	data = data or {}
	local menu = BLE.Menu
	self._menu = menu:make_page("Levels", nil, {scrollbar = false, index = 2})
	ItemExt:add_funcs(self)
	local filters = self:holder("Filters", {align_method = "grid", inherit_values = {size_by_text = true, offset = 0}})
	local w = filters:tickbox("Vanilla", ClassClbk(self, "load_levels"), data.vanilla).w
	w = w + filters:tickbox("Custom", ClassClbk(self, "load_levels"), NotNil(data.custom, true)).w
	w = w + filters:tickbox("Narratives", ClassClbk(self, "load_levels"), NotNil(data.narratives, true)).w
	filters:textbox("Search", ClassClbk(self, "search_levels"), nil, {w = filters:ItemsWidth() - w, index = 1, control_slice = 0.85, offset = 0})

	local load_options = self:pan("LoadOptions", {align_method = "grid", auto_height = true, inherit_values = {offset = 0}})
    local third_w = load_options:ItemsWidth() / 3
	load_options:combobox("Difficulty", nil, difficulty_loc, 1, {items_localized = true, items_pretty = true, w = third_w, offset = 0})
	load_options:numberbox("MissionFilter", nil, nil, {w = third_w, floats = 0, offset = 0, help = "Set a mission filter to be forced on the level, 0 uses the default filter."})
	load_options:tickbox("OneDown", nil, data.one_down, {w = third_w, offset = 0})
    load_options:tickbox("Safemode", nil, data.safemode, {w = third_w})
    load_options:tickbox("CheckLoadTime", nil, data.load_time, {w = third_w})
	load_options:tickbox("LogSpawnedUnits", nil, data.log_spawned, {w = third_w})

	self._levels = self:pan("LevelList", {auto_align = false, offset = 8, h = self._menu:ItemsHeight() - load_options:Bottom() - 16, auto_height = false})
	self:load_levels()
end

function LoadLevelMenu:Destroy()
	local filters = self:GetItem("Filters")
	local load_options = self:GetItem("LoadOptions")
	return {
		vanilla = filters:GetItemValue("Vanilla"),
		custom = filters:GetItemValue("Custom"),
		narratives = filters:GetItemValue("Narratives"),
		difficulty = load_options:GetItemValue("Difficulty"),
		one_down = load_options:GetItemValue("OneDown"),
		safemode = load_options:GetItemValue("Safemode"),
		load_time = load_options:GetItemValue("CheckLoadTime"),
		log_spawned = load_options:GetItemValue("LogSpawnedUnits")
	}
end

function LoadLevelMenu:search_levels(item)
	item = item or self:GetItem("Search")
	local search = item:Value():escape_special()
	local searching = search:len() > 0
	if self:GetItemValue("Narratives") then
		for _, menu in pairs(self._levels:Items()) do
			if menu.type_name == "Holder" then
				for _, item in pairs(menu:Items()) do
					if item.type_name == "Holder" then
						menu:SetVisible(false)
						if not searching or item.text:find(search) then
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
	else
		for _, btn in pairs(self._levels:Items()) do
			if not searching or btn.text:find(search) then
				btn:SetVisible(true)
			else
				btn:SetVisible(false)
			end
		end
	end
	self._levels:AlignItems(true)
end

local texture_ids = Idstring("texture")

function LoadLevelMenu:load_levels()
	if self:GetItemValue("Narratives") then
		self:do_load_narratives()
	else
		self:do_load_levels()
	end
end

function LoadLevelMenu:do_load_levels()
	local vanilla = self:GetItem("Vanilla"):Value()
	local custom = self:GetItem("Custom"):Value()
    local columns = BLE.Options:GetValue("LevelsColumns")
    local levels = self:GetItem("LevelList")
    local loc = managers.localization
	levels:ClearItems()

	for _, id in pairs(tweak_data.levels._level_index) do
		local level = tweak_data.levels[id]
		if level then
			levels:button(id, ClassClbk(self, "load_level"), {text = (level.name_id and loc:text(level.name_id) or "").."/"..id})
		end
	end

	for path, instance in pairs(BeardLib.managers.MapFramework._loaded_instances) do
		local id = instance._config.id
		levels:button("instances/mods/"..id, ClassClbk(self, "load_level"), {text = path, real_id = id, instance = true})
	end

	self:search_levels()
end

function LoadLevelMenu:do_load_narratives()
	local vanilla = self:GetItem("Vanilla"):Value()
	local custom = self:GetItem("Custom"):Value()
    local columns = BLE.Options:GetValue("LevelsColumns")
    local levels = self:GetItem("LevelList")
    levels:ClearItems()
    local loc = managers.localization
    local img_size = 100
	local img_w, img_h = img_size * 1.7777, img_size
	local load_level = ClassClbk(self, "load_level")
	local w
	local function create_narr(id, txt, texture, rect)
		local holder = levels:Holder({
			name = id.."_holder",
			auto_height = true,
			offset = 4,
			 auto_foreground = false,
			align_method = "grid",
			min_h = 250,
		})

		local img = holder:Create(texture and "Image" or "Divider", {
			text = "No preview image",
			texture = texture,
			texture_rect = rect,
			background_color = levels.highlight_color or nil,
			text_align = "center",
			text_vertical = "center",
			offset_y = 6,
			w = img_w,
			h = img_h
		})

		w = w or holder:ItemsWidth() - img:OuterWidth() - holder:OffsetX() * 2

		local narrative = holder:tholder(txt, {
			foreground = levels.accent_color,
			auto_foreground = true,
			auto_height = true,
			w = w,
		})
		return holder, narrative
	end
	local function level_button(id, narr_id, menu)
		local level_t = tweak_data.levels[id]
		if level_t and level_t.world_name then
			menu:button(id, load_level, {
				text = loc:text(level_t.name_id) .." / " .. id,
				name = id,
				narr_id = narr_id,
				vanilla = not level_t.custom,
				offset = {12, 4},
				label = "LevelList",
			})
		end
	end
	for narr_id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.hidden and ((narr.custom and custom) or (not narr.custom and vanilla)) then
            local txt = loc:text((narr.name_id or ("heist_"..narr_id:gsub("_prof", ""):gsub("_night", ""))) .." / " .. narr_id)
            local texture, rect = nil, nil

			if narr.contract_visuals and narr.contract_visuals.preview_image then
				local data = narr.contract_visuals.preview_image
				if data.id then
					texture = "guis/dlcs/" .. (data.folder or "bro") .. "/textures/pd2/crimenet/" .. data.id
					rect = data.rect
				elseif data.icon then
					texture, rect = tweak_data.hud_icons:get_icon_data(data.icon)
				end
			end

            if not texture or not DB:has(texture_ids, texture:id()) then
                texture, rect = nil, nil
            end

			local holder, narrative = create_narr(narr_id, txt, texture, rect)

            local has_items

			for i, level in pairs(narr.chain) do
				if type(level) == "table" then
					local id = level.level_id
					if id then
						level_button(id, narr_id, narrative)
						has_items = true
					elseif #level > 0 then
						local day = narrative:tholder("Day #"..tostring(i))
						for _, grouped_level in pairs(level) do
							id = grouped_level.level_id
							if id then
								level_button(id, narr_id, day)
								has_items = true
							end
						end
					end
				end
            end
            if not has_items then
                holder:Destroy()
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
	local filter = self:GetItem("MissionFilter"):Value()

	local function load()
		Global.editor_mode = true
		Global.current_mission_filter = filter == 0 and nil or filter
		Global.editor_loaded_instance = item.instance and true or false
        Global.editor_safe_mode = safe_mode == true
        Global.check_load_time = check_load == true
        Global.editor_log_on_spawn = log_on_spawn == true
        BeardLib.current_level = nil
		MenuCallbackHandler:play_single_player()
		if narr_id then
			managers.job:activate_job(narr_id)
		end
        Global.game_settings.level_id = level_id
        Global.current_level_id = item.real_id or level_id
        Global.game_settings.mission = "none"
		Global.game_settings.difficulty = difficulty_ids[difficulty] or "normal"
		Global.game_settings.one_down = one_down
        Global.game_settings.world_setting = nil
        self:start_the_game()
        BLE.Menu:set_enabled(false)

	--Saving the last loaded heist to file for the restart button
	BLE.Options:SetValue("LastLoaded", {name = item.name, narr_id = item.narr_id, instance = item.instance or nil, real_id = item.real_id or nil, vanilla = item.vanilla})
    end

    local load_tbl = {{"Yes", load}}
    if item.vanilla then
        BLE.Utils:QuickDialog({title = "Preview level '" .. tostring(level_id).."'?", message = "Since this is a vanilla heist you can only preview it, clone the heist if you wish to edit the heist!"}, load_tbl)
    elseif safe_mode then
        BLE.Utils:QuickDialog({title = "Test level '" .. tostring(level_id).."'?", message = "Safemode is used to access the assets manager when the units fail to load by not spawning them"}, load_tbl)        
    else
        BLE.Utils:QuickDialog({title = "Edit level '" .. tostring(level_id).."'?", message = "This will load the level in the editor and will allow you to edit it"}, load_tbl)
    end
end

function LoadLevelMenu:start_the_game()
	local mutators_manager = managers.mutators

	if mutators_manager and mutators_manager:should_delay_game_start() then
		if not mutators_manager:_check_all_peers_are_ready() then
			mutators_manager:use_start_the_game_initial_delay()
		end

		mutators_manager:send_mutators_notification_to_clients(mutators_manager:delay_lobby_time())
		managers.menu:open_node("start_the_game_countdown")

		return
	end

	if MenuCallbackHandler._game_started then
		return
	end

	MenuCallbackHandler._game_started = true
	local level_id = Global.game_settings.level_id

	local level_name
	if Global.editor_loaded_instance then
		level_name = level_id
	else
		level_name = level_id and tweak_data.levels[level_id].world_name
	end

	if Global.boot_invite then
		Global.boot_invite.used = true
		Global.boot_invite.pending = false
	end

	local mission = Global.game_settings.mission ~= "none" and Global.game_settings.mission or nil
	local world_setting = Global.game_settings.world_setting

	managers.network:session():load_level(level_name, mission, world_setting, nil, level_id)
end
