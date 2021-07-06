EditorMenu = EditorMenu or class()
function EditorMenu:init(load)
    self._menus = {}
    local accent_color = BLE.Options:GetValue("AccentColor")
	self._main_menu = MenuUI:new({
        name = "Editor",
        layer = 1500,
        auto_foreground = true,
        highlight_image = true,
        accent_color = accent_color,
        full_bg_color = BLE.Options:GetValue("BackgroundColor"),
        highlight_color = BLE.Options:GetValue("ItemsHighlight"),
        background_color = BLE.Options:GetValue("BackgroundColor"),
        border_color = BLE.Options:GetValue("AccentColor"),
        context_background_color = BLE.Options:GetValue("ContextMenusBackgroundColor"),
		create_items = ClassClbk(self, "create_items"),
        scroll_speed = BLE.Options:GetValue("Scrollspeed"),
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
    else
        self:select_page("Projects")
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
    local name_lower = name:lower()
    self._menus[name_lower] = self._menus[name_lower] or self._menu:Menu(table.merge({
        name = name,
        visible = false,
        private = {offset = {8, 4}},
        inherit_values = {
            full_bg_color = BLE.Options:GetValue("BoxesBackgroundColor"),
        },
        h = self._main_menu._panel:h() - 40,
    }, opt or {}))
    self:s_btn(name_lower, clbk or ClassClbk(self, "select_page", name), {index = index, text = name, highlight_color = self._menus[name_lower].highlight_color, offset = 6})

    return self._menus[name_lower]
end

function EditorMenu:create_items(menu)
    self._main_menu = menu
    self._menu = self._main_menu:Holder({
        name = "Holder"
    })
	self._tabs = self._menu:Holder({
        name = "tabs",
        index = 1,
        private = {offset = {8, 0}},
        align_method = "grid",
        h = 32
	})
	ItemExt:add_funcs(self, self._tabs)
    self:tb_imgbtn("Close", ClassClbk(self, "set_enabled", false), nil, BLE.Utils.EditorIcons.cross, {position = "RightOffsety"})
end

function EditorMenu:should_close()
    return self._main_menu:ShouldClose()
end

function EditorMenu:hide()
    self:set_enabled(false)
    return true
end

function EditorMenu:set_enabled(enabled)
    if BLE._disabled then
        BLE:AskToDownloadData()
        return
    end
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
    page = page:lower()
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