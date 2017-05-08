EditorMenu = EditorMenu or class() 
function EditorMenu:init()
    self._menus = {}
	self._main_menu = MenuUI:new({
        text_color = Color.white,
        layer = 400,
        marker_highlight_color = BeardLibEditor.Options:GetValue("AccentColor"),
		create_items = callback(self, self, "create_items"),
	})	    
	MenuCallbackHandler.BeardLibEditorMenu = callback(self._main_menu, self._main_menu, "enable")
    MenuHelperPlus:AddButton({
        id = "BeardLibEditorMenu",
        title = "BeardLibEditorMenu",
        node_name = "options",
        position = managers.menu._is_start_menu and 9 or 7,
        callback = "BeardLibEditorMenu",
    })
end

function EditorMenu:make_page(name, clbk, opt)
    self._menus[name] = self._menus[name] or self._main_menu:Menu(table.merge({
        name = name,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,        
        items_size = 20,
        visible = false,
        position = "RightBottom",
        w = self._main_menu._panel:w() - 250,
    }, opt or {}))
    self:Button(name, clbk or callback(self, self, "select_page", name), {offset = 4, marker_highlight_color = self._tabs.marker_color})
    return self._menus[name]
end


function EditorMenu:create_items(menu)
	self._main_menu = menu
	self._tabs = menu:Menu({
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
    local div = self:Divider("BeardLib-Editor", {items_size = 24, offset = 0, marker_color = self._tabs.marker_highlight_color}) 
    self:SmallButton("x", callback(self._tabs.menu, self._tabs.menu, "disable"), div, {
        marker_highlight_color = Color.black:with_alpha(0.25),
        w = self._tabs.items_size, h = self._tabs.items_size,
        text_align = "center", size_by_text = false
    })
    local info = self:DivGroup("Info", {text =  "BeardLib-Editor Revision "..BeardLibEditor.Version, border_lock_height = false, align_method = "grid", offset = 0, items_size = 16, position = function(item)
        item:Panel():set_world_bottom(item.parent_panel:world_bottom() - 1)
    end})
    local function link_button(name, url)
        self:Button(name, callback(nil, os, "execute", 'start "" "'..url..'"'), {group = info, text = name, text_align = "center", size_by_text = true})
    end
    link_button("GitHub", "https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor")
    link_button("ModWorkshop", "https://modworkshop.net/mydownloads.php?action=view_down&did=16837")
    link_button("Guides", "https://modworkshop.net/wiki.php?action=categories&cid=5")
    link_button("Issues", "https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues")
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
        self._tabs:GetItem(name):SetColor(self._tabs.marker_color)
        m:SetVisible(false)
    end 
    if not page or self._current_page == page then
        self._current_page = nil
        return
    end
    self._current_page = page
    item:SetColor(self._tabs.marker_highlight_color)
    self._menus[page]:SetVisible(true)
end