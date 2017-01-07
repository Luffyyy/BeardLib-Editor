LoadLevelMenu = LoadLevelMenu or class()
function LoadLevelMenu:init()
	self._menus = {}	
	self._main_menu = MenuUI:new({
        text_color = Color.white,
        marker_highlight_color = BeardLibEditor.color,
		create_items = callback(self, self, "create_items"),
	})	
end

function LoadLevelMenu:create_items(menu)
	local w = 750
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
        position = "TopCenter",
        w = w,
        h = 20,
	})
	self:make_page("all")
	self:make_page("vanilla")
	self:make_page("custom")	
	self._bottom_tabs = menu:NewMenu({
		name = "bottom_tabs",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
       	align = "center",
        offset = 0,       	
        visible = true,
        row_max = 1,
        items_size = 20,
        position = {self._menus.all:Panel():leftbottom()},
        w = w,
        h = 20,
	})
	self._bottom_tabs:Button({
		name = "close_button",
		text = "Close",
		callback = callback(menu, menu, "disable")
	})
	local columns = 3
	for job_id, job in pairs(tweak_data.narrative.jobs) do
		for name, m in pairs(self._menus) do
			if name == "all" or (name == "custom" and job.custom) or (name == "vanilla" and not job.custom) then
				m:Button({
					name = job_id,
		            w = w / columns,
					text = job_id,
					callback = callback(self, self, "load_level", job_id)
				})	
			end
		end
	end	
	self:select_page("all")

	for _, m in pairs(self._menus) do
   		m:SetMaxRow(math.ceil(#m.items / columns))
	end
end

function LoadLevelMenu:make_page(name)
	self._menus[name] = self._menu:NewMenu({
		name = name,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,        
        items_size = 20,
        h = self._menu._panel:h() - 40,
        position = {self._tabs:Panel():leftbottom()},
        w = 750,
	})
	self._tabs:Button({
		name = name,
		text = string.pretty(name),
		callback = callback(self, self, "select_page", name)
	})
	return self._menus[name]
end

function LoadLevelMenu:select_page(page)
	for name, m in pairs(self._menus) do
		local tab = self._tabs:GetItem(name)
		tab.marker_color = self._tabs.marker_color
		tab:Panel():child("bg"):set_color(tab.marker_color)
		m:SetVisible(false)
	end 
	local tab = self._tabs:GetItem(page)
	tab.marker_color = tab.marker_highlight_color
	tab:Panel():child("bg"):set_color(tab.marker_color)
	self._menus[page]:SetVisible(true)
end

function LoadLevelMenu:load_level(level_id)
    QuickMenu:new( "Load level?", "",
        {[1] = {text = "Yes", callback = function()
        	Global.editor_mode = true
			MenuCallbackHandler:play_single_player()
			MenuCallbackHandler:start_single_player_job({job_id = level_id, difficulty = "normal"})            
        end
    },[2] = {text = "No", is_cancel_button = true}}, true)
end

function LoadLevelMenu:BuildNode(main_node)
	MenuCallbackHandler.BeardLibMpaEditorMenuOpen = function(this, item)
      	self._main_menu:enable()
	end
    MenuHelperPlus:AddButton({
        id = "BeardLibEditorLoadLevel",
        title = "BeardLibEditorLoadLevel_title",
        node = main_node,
        callback = "BeardLibMpaEditorMenuOpen"
    })
end
 