EditorMenu = EditorMenu or class() --Replace the current menu
function EditorMenu:init()
	self._main_menu = MenuUI:new({
        text_color = Color.white,
        marker_highlight_color = BeardLibEditor.color,
		create_items = callback(self, self, "create_items"),
	})	
	MenuCallbackHandler.BeardLibEditorMenu = callback(self._main_menu, self._main_menu, "enable")
    --[[MenuHelperPlus:AddButton({
        id = "BeardLibEditorMenu",
        title = "BeardLibEditorMenu",
        node_name = "options",
        position = managers.menu._is_start_menu and 9 or 7,
        callback = "BeardLibEditorMenu",
    })]]
end

function EditorMenu:tab(name)
	self._menu = menu:NewMenu({
		name = name,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
        visible = true,    
        items_size = 20,
        h = self._main_menu._panel:h(),
        position = "Right",
        w = 750,
	})	

end

function EditorMenu:create_items(menu)
	self._main_menu = menu

	self._tabs = menu:NewMenu({
		name = "tabs",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
        visible = true,    
        items_size = 24,
        h = self._main_menu._panel:h(),
        position = "Left",
        w = 200,
	})	
 
	MenuUtils:new(self)
end