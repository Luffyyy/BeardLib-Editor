EditorMenu = EditorMenu or class() 
function EditorMenu:init()
    self._menus = {}
	self._main_menu = MenuUI:new({
        text_color = Color.white,
        layer = 10,
        marker_highlight_color = BeardLibEditor.color,
		create_items = callback(self, self, "create_items"),
	})	    
    self._list_dia = ListDialog:new({w = self._main_menu._panel:w() - 250, h = self._main_menu._panel:h(), position = "RightBottom"})
	MenuCallbackHandler.BeardLibEditorMenu = callback(self._main_menu, self._main_menu, "enable")
    MenuHelperPlus:AddButton({
        id = "BeardLibEditorMenu",
        title = "BeardLibEditorMenu",
        node_name = "options",
        position = managers.menu._is_start_menu and 9 or 7,
        callback = "BeardLibEditorMenu",
    })
end

function EditorMenu:make_page(name, group_name, clbk)
    local menu_name = clbk and group_name or name
    self._menus[menu_name] = self._menus[menu_name] or self._main_menu:NewMenu({
        name = name,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,        
        items_size = 20,
        position = "RightBottom",
        w = self._main_menu._panel:w() - 250,
    })
    local group = group_name and (self:GetItem(group_name) or self:Group(group_name))
    self:Button(name, clbk or callback(self, self, "select_page", name), {text = string.pretty(name), group = group, offset = {4, 2}})
    return self._menus[name]
end


function EditorMenu:create_items(menu)
	self._main_menu = menu
	self._tabs = menu:NewMenu({
		name = "tabs",
        scrollbar = false,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
        visible = true,
        items_size = 24,        
        w = 200,
        h = self._main_menu._panel:h(),
        position = "Left",
	})	
	MenuUtils:new(self, self._tabs)   
    local div = self:Divider("BeardLib-Editor")
    self:SmallButton("X", callback(self._tabs.menu, self._tabs.menu, "disable"), div)
end

function EditorMenu:set_enabled(enabled)
    if enabled then
        self._main_menu:enable()
    else
        self._main_menu:disable()
    end
end

function EditorMenu:select_page(page, menu, item)
    for name, m in pairs(self._menus) do
        local tab = self._tabs:GetItem(name)
        tab.marker_highlight_color = self._tabs.marker_color
        tab.marker_color = self._tabs.marker_color
        tab:Panel():child("bg"):set_color(tab.marker_color)
        m:SetVisible(false)
    end 
    if not page or self._current_page == page then
        self._current_page = nil
        return
    end
    self._current_page = page
    item.marker_highlight_color = self._tabs.marker_highlight_color / 1.5
    item.marker_color = item.marker_highlight_color
    item:Panel():child("bg"):set_color(item.marker_color)
    self._menus[page]:SetVisible(true)
end