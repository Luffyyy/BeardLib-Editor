LoadLevelMenu = LoadLevelMenu or class()
function LoadLevelMenu:init()
	self._main_menu = MenuUI:new({
        text_color = Color.white,
        layer = 10,
        marker_highlight_color = BeardLibEditor.color,
		create_items = callback(self, self, "create_items"),
	})	
end

function LoadLevelMenu:create_items(menu)
	local EMenu = BeardLibEditor.managers.Menu
	self._menu = menu
	self._tabs = menu:NewMenu({
		name = "tabs",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
        size_by_text = true,
       	align = "center",
        offset = 0,       	
        visible = true,
        row_max = 1,
        items_size = 20,
        scrollbar = false,
        position = "TopCenter",
        w = w,
        h = 20,
	})
	EMenu:make_page("all", "Levels")
	EMenu:make_page("vanilla", "Levels")
	EMenu:make_page("custom", "Levels")	
	self._bottom_tabs = menu:NewMenu({
		name = "bottom_tabs",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
       	align = "center",
        offset = 0,       	
        visible = true,
        row_max = 1,
        items_size = 20,
        scrollbar = false,
        position = {EMenu._menus.all:Panel():leftbottom()},
        w = w,
        h = 20,
	})
	self._bottom_tabs:Button({
		name = "close_button",
		text = "Close",
		callback = callback(menu, menu, "disable")
	})
	local columns = 4
	for job_id, job in pairs(tweak_data.narrative.jobs) do
		for name, m in pairs(EMenu._menus) do
			if name == "all" or (name == "custom" and job.custom) or (name == "vanilla" and not job.custom) then
				m:Button({
					name = job_id,
		            w = m.w / columns,
					text = job_id,
					callback = callback(self, self, "load_level", job_id)
				})	
			end
		end
	end	
	for _, m in pairs(EMenu._menus) do
   		m:SetMaxRow(math.ceil(#m.items / columns))
	end
end

function LoadLevelMenu:load_level(level_id)
    QuickMenu:new("Load level?", "",
        {[1] = {text = "Yes", callback = function()
        	Global.editor_mode = true
			MenuCallbackHandler:play_single_player()
			MenuCallbackHandler:start_single_player_job({job_id = level_id, difficulty = "normal"})
			BeardLibEditor.managers.Menu:set_enabled(false)
        end
    },[2] = {text = "No", is_cancel_button = true}}, true)
end
 