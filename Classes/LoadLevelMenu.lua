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
local edit_tag = "[Currently editing] "
local view_tag = "[Currently viewing] "
local favorite_levels = BLE.Options:GetValue("FavoriteLevels")

function LoadLevelMenu:init(data)
	data = data or {}
	local menu = BLE.Menu
	self._menu = menu:make_page("Levels", nil, {scrollbar = false, index = 2, auto_align = false})
	ItemExt:add_funcs(self)
	local page = self._menu
	local gap = 10
	local gap2 = gap / 2
	local sidebar_width = 350
	local sb_off = {offset = {4, 0}}
	local main_width = page:W() - sidebar_width - gap
	local sidebar = self:holder("sidebar", {
		align_method = "normal",
		w = sidebar_width,
		h = page:H(),
		offset = {0, 0},
		auto_align = true,
	})
	local main = self:holder("main", {
		w = main_width,
		h = page:H(),
		offset = {0, 0},
		position = {sidebar:Right() + gap, sidebar:Top()}
	})
	
	local filters = sidebar:group("Filters", {
		align_method = "normal",
		offset = 0,
		inherit_values = sb_off
	})
	filters:textbox("Search", ClassClbk(self, "search_levels"), nil, {control_slice = 0.75})
	filters:tickbox("Vanilla", ClassClbk(self, "load_levels"), data.vanilla)
	filters:tickbox("Custom", ClassClbk(self, "load_levels"), NotNil(data.custom, true))
	filters:tickbox("Narratives", ClassClbk(self, "load_levels"), NotNil(data.narratives, true))

	local load_options = sidebar:group("LoadOptions", {
		align_method = "normal",
		offset = {0, gap2},
		inherit_values = sb_off
	})
	load_options:combobox("Difficulty", nil, difficulty_loc, 1, {items_localized = true, items_pretty = true})
	load_options:numberbox("MissionFilter", nil, nil, {floats = 0, help = "Set a mission filter to be forced on the level, 0 uses the default filter."})
	load_options:tickbox("OneDown", nil, data.one_down)
    load_options:tickbox("Safemode", nil, data.safemode)
    load_options:tickbox("CheckLoadTime", nil, data.load_time)
	load_options:tickbox("LogSpawnedUnits", nil, data.log_spawned)

	local quick_access = sidebar:group("QuickAccess", {
		align_method = "normal",
		offset = {0, gap2},
		inherit_values = sb_off
	})
	local last_loaded = BLE.Options:GetValue("LastLoaded").name or "none"
	local last_loaded_exist = tweak_data.levels[last_loaded] and true or false
	local last_loaded_button = quick_access:button(last_loaded, ClassClbk(self, "load_level"), {
		text = "Last Loaded Level: " .. last_loaded
	})
	last_loaded_button:SetEnabled(last_loaded_exist)
	
	local favorites = sidebar:group("Favorites", {
		align_method = "normal",
		offset = {0, gap2},
		inherit_values = sb_off,
		h = page:H() - filters:H() - load_options:H() - quick_access:H() - gap2 * 3,
		auto_height = false
	})
	self:fill_favorites()

	self._levels = main:pan("LevelList", {
		auto_align = false, 
		offset = 0, 
		h = main:H(), 
		auto_height = false
	})
	self:load_levels()

	filters:AlignItems()
	main:AlignItems()
	load_options:AlignItems()
	self._levels:AlignItems()
	self:AlignItems()
end

function LoadLevelMenu:fill_favorites()
	local favorites = self:GetItem("Favorites")
	favorites:ClearItems()

	for i, id in pairs(favorite_levels) do
		local level_exists = tweak_data.levels[id] and true or false
		local load_level = level_exists and ClassClbk(self, "load_level") or nil
		local o = {
			items = {
				{text = "Remove from favorites", on_callback = ClassClbk(self, "remove_favorite", id) },
			}
		}
		if not level_exists then
			o.enabled_alpha = 0.5
			o.help = "This level does not exist and can't be loaded.\nYou can still remove it from the favorites."
		end
		favorites:button(id, load_level, o)
	end
end

function LoadLevelMenu:add_favorite(id)
	if table.contains(favorite_levels, id) then
		log("[BeardLib-Editor] " .. id .. " is already favorited")
		return
	end
	table.insert(favorite_levels, id)
	self:fill_favorites()
end

function LoadLevelMenu:remove_favorite(id)
	for i, level in pairs(favorite_levels) do
		if level == id then
			table.remove(favorite_levels, i)
		end
	end
	BLE.Options:SetValue("FavoriteLevels", favorite_levels)
	self:fill_favorites()
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
	local search = item:Value():escape_special():lower()
	local searching = search:len() > 0
	if self:GetItemValue("Narratives") then
		for _, menu in pairs(self._levels:Items()) do
			if menu.type_name == "Holder" then
				for _, item in pairs(menu:Items()) do
					if item.type_name == "Holder" then
						menu:SetVisible(false)
						if not searching or item.text:lower():find(search) then
							menu:SetVisible(true)
						else
							for _, _item in pairs(item:Items()) do
								if _item.text:lower():find(search) then
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
			if not searching or btn.text:lower():find(search) then
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
	if Global.editor_mode then
		local current_level = Global.level_data and Global.level_data.level_id or "none"
		log("[BeardLib-Editor] Currently editing level: " .. current_level)
	end
	
	if self:GetItemValue("Narratives") then
		self:do_load_narratives()
	else
		self:do_load_levels()
	end
end

function LoadLevelMenu:is_editing(level)
	local current_level = Global.level_data and Global.level_data.level_id
	local match = false
	if current_level == level then
		match = true
	end
	return match
end

function LoadLevelMenu:do_load_levels()
    local levels = self:GetItem("LevelList")
	local vanilla = self:GetItem("Vanilla"):Value()
	local custom = self:GetItem("Custom"):Value()
    local loc = managers.localization
	levels:ClearItems()

	for _, id in pairs(tweak_data.levels._level_index) do
		local level = tweak_data.levels[id]
		if level then
			if (level.custom and custom) or (not level.custom and vanilla) then
				local o = {
					text = (level.name_id and loc:text(level.name_id) or "").."  /  "..id, 
					vanilla = not level.custom,
					items = {
						{text = "Add to favorites", on_callback = ClassClbk(self, "add_favorite", id) } 
					}
				}
				if self:is_editing(id) then
					if o.vanilla then
						o.text = view_tag .. o.text
					else
						o.text = edit_tag .. o.text
					end
					o.background_color = Color.green:with_alpha(0.1)
					o.border_left = true
					o.border_size = 2
					o.border_color = Color.green
					o.index = 1
				end
				levels:button(id, ClassClbk(self, "load_level"), o)
			end
		end
	end

	if custom then
		for path, instance in pairs(BeardLib.managers.MapFramework._loaded_instances) do
			local id = instance._config.id
			path = path:gsub("levels/", ""):gsub("/world", "")
			local o = {
				text = path,
				instance = true
			}
			if self:is_editing(path) then
				o.text = edit_tag .. o.text
				o.background_color = Color.green:with_alpha(0.1)
				o.border_left = true
				o.border_size = 2
				o.border_color = Color.green
				o.index = 1
			end
			levels:button(path, ClassClbk(self, "load_level"), o)
		end
	end

	if self:GetItem("Vanilla"):Value() then
		for _, path in pairs(BLE.Utils:GetEntries({type = "world"})) do
			if path:match("levels/instances") then
				path = path:gsub("levels/", ""):gsub("/world", "")
				local o = {
					text = path,
					vanilla = true,
					instance = true
				}
				if self:is_editing(path) then
					o.text = view_tag .. o.text
					o.background_color = Color.green:with_alpha(0.1)
					o.border_left = true
					o.border_size = 2
					o.border_color = Color.green
					o.index = 1
				end
				levels:button(path, ClassClbk(self, "load_level"), o)
			end
		end
	end

	self:search_levels()
end

function LoadLevelMenu:do_load_narratives()
	local vanilla = self:GetItem("Vanilla"):Value()
	local custom = self:GetItem("Custom"):Value()
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
			local o = {
				text = loc:text(level_t.name_id) .." / " .. id,
				name = id,
				narr_id = narr_id,
				vanilla = not level_t.custom,
				offset = {12, 4},
				label = "LevelList",
				items = {
					{text = "Add to favorite", on_callback = ClassClbk(self, "add_favorite", id) } 
				}
			}
			if self:is_editing(id) then
				if o.vanilla then
					o.text = view_tag .. o.text
				else
					o.text = edit_tag .. o.text
				end
				o.background_color = Color.green:with_alpha(0.1)
				o.border_left = true
				o.border_size = 2
				o.border_color = Color.green
				self:GetItem(o.narr_id.."_holder"):SetIndex(1)
			end
			menu:button(id, load_level, o)
		end
	end
	for narr_id, narr in pairs(tweak_data.narrative.jobs) do
        if not narr.hidden and ((narr.custom and custom) or (not narr.custom and vanilla)) then
            local txt = loc:text((narr.name_id or ("heist_"..narr_id:gsub("_prof", ""):gsub("_night", "")))) .." / " .. narr_id
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
		Global.editor_loaded_instance = item.instance and item.instance or false
		Global.editor_return_bookmark = item.return_bookmark
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
	BLE.Options:SetValue("LastLoaded", {name = item.name, narr_id = item.narr_id, instance = item.instance and true or nil, real_id = item.real_id or nil, vanilla = item.vanilla})
    end

    local load_tbl = {{"Yes", load}}
	local unsaved_warning = Global.editor_mode and "\n\nAll unsaved progress on the current level will be lost!" or ""
	if item.vanilla then
		local level_type = item.instance and "instance" or "heist"
       	BLE.Utils:QuickDialog({title = "Preview level '" .. tostring(level_id).."'?", message = "Since this is a vanilla " ..level_type.. " you can only preview it, clone the " ..level_type.. " if you wish to edit it!"..unsaved_warning}, load_tbl)
    elseif safe_mode then
        BLE.Utils:QuickDialog({title = "Test level '" .. tostring(level_id).."'?", message = "Safemode is used to access the assets manager when the units fail to load by not spawning them"..unsaved_warning}, load_tbl)        
    else
        BLE.Utils:QuickDialog({title = "Edit level '" .. tostring(level_id).."'?", message = "This will load the level in the editor and will allow you to edit it"..unsaved_warning}, load_tbl)
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
