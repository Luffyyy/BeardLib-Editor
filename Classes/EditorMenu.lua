EditorMenu = EditorMenu or class() 
function EditorMenu:init(load)
    self._menus = {}
    local accent_color = BeardLibEditor.Options:GetValue("AccentColor")
	self._main_menu = MenuUI:new({
        name = "Editor",
        layer = 1500,
        background_blur = true,
        auto_foreground = true,
        accent_color = accent_color,
        highlight_color = accent_color,
        background_color = BeardLibEditor.Options:GetValue("BackgroundColor"),
        border_color = BeardLibEditor.Options:GetValue("AccentColor"),
		create_items = ClassClbk(self, "create_items"),
	})
    MenuCallbackHandler.BeardLibEditorMenu = ClassClbk(self, "set_enabled", true)
    local node = MenuHelperPlus:GetNode(nil, "options")
    if not node:item("BeardLibEditorMenu") then
        MenuHelperPlus:AddButton({
            id = "BeardLibEditorMenu",
            title = "BeardLibEditorMenu",
            node = node,
            position = managers.menu._is_start_menu and 9 or 7,
            callback = "BeardLibEditorMenu",
        })
    end
end

function EditorMenu:Load(data)
    if data then
        if data.last_page then
            self:select_page(data.last_page)
        end
        if data.opened then
            self:set_enabled(true)
        end
    end
end

function EditorMenu:Destroy()
    self._main_menu:Destroy()
    return {last_page = self._current_page, opened = self._enabled}
end

function EditorMenu:make_page(name, clbk, opt)
    local index = opt and opt.index or nil
    if opt then
        opt.index = nil
    end
    self._menus[name] = self._menus[name] or self._menu:Menu(table.merge({
        name = name,
        items_size = 20,
        visible = false,
        private = {offset = {16, 4}},
        h = self._main_menu._panel:h() - 60,
    }, opt or {}))
    self._menus[name].highlight_color = self._menus[name].foreground:with_alpha(0.1)
    self:s_btn(name, clbk or ClassClbk(self, "select_page", name), {index = index, highlight_color = self._menus[name].highlight_color})

    return self._menus[name]
end

function EditorMenu:create_items(menu)
    self._main_menu = menu
    self._menu = self._main_menu:Holder({
        name = "Holder"
    })
	self._tabs = self._menu:Holder({
        name = "tabs",
        size = 24,
        index = 1,
        private = {offset = {16, 2}},
        align_method = "grid",
        h = 30
	})
	ItemExt:add_funcs(self, self._tabs)
    local s = self._tabs.items_size - 2
    self:tb_imgbtn("Close", ClassClbk(self, "set_enabled", false), "guis/textures/menu_ui_icons", {84, 89, 36, 36}, {
        highlight_color = false, w = s, h = s, position = "Right"
    })
end

function EditorMenu:should_close()
    return self._main_menu:ShouldClose()
end

function EditorMenu:hide()
    self:set_enabled(false)
    return true
end

function EditorMenu:set_enabled(enabled)
    local in_editor = managers.editor and game_state_machine:current_state_name() == "editor"
    local opened = BeardLib.managers.dialog:DialogOpened(self)
    if enabled then
        if not opened then
            BeardLib.managers.dialog:ShowDialog(self)
            self._main_menu:Enable()
            if in_editor then
                managers.editor._enabled = false
            end
        end
        self._enabled = true
    elseif opened then
        BeardLib.managers.dialog:CloseDialog(self)
        self._main_menu:Disable()
        if in_editor then
            managers.editor._enabled = true
        end
        self._enabled = false
    end
end

function EditorMenu:select_page(page)
    for name, m in pairs(self._menus) do
        self._tabs:GetItem(name):SetBorder({bottom = false})
        m:SetVisible(false)
    end 
    if not page or self._current_page == page then
        self._current_page = nil
        return
    end
    self._current_page = page
    self._tabs:GetItem(page):SetBorder({bottom = true})
    self._menus[page]:SetVisible(true)
end