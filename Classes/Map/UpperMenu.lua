UpperMenu = UpperMenu or class(EditorPart)
function UpperMenu:get_menu_h() return self._menu:Panel():parent():h() - self._menu.h - 1 end
function UpperMenu:init(parent, menu)
    self._parent = parent
    local normal = not Global.editor_safe_mode
    self._tabs = {
        {name = "world", rect = {0, 448, 64, 64}},
        {name = "static", rect = {192, 448, 64, 64}, enabled = normal},
        {name = "spawn", rect = {64, 448, 64, 64}, enabled = normal},
        {name = "select", rect = {128, 448, 64, 64}, enabled = normal},
        {name = "env", rect = {256, 448, 64, 64}},
        {name = "opt", rect = {320, 448, 64, 64}},
        {name = "save", rect = {383, 448, 64, 64}, callback = ClassClbk(self, "save"), enabled = normal},
    }
    local w = BLE.Options:GetValue("MapEditorPanelWidth")
    self._menu = menu:Menu({
        name = "upper_menu",
        background_color = BLE.Options:GetValue("BackgroundColor"),
        accent_color = BLE.Options:GetValue("AccentColor"),
        w = w,
        position = BLE.Options:GetValue("GUIOnRight") and "Right" or nil,
        h = 300 / #self._tabs - 4,
        auto_foreground = true,
        offset = 0,
        align_method = "centered_grid",
        scrollbar = false,
        visible = true,
    })
    self._tab_size = self._menu:ItemsWidth(#self._tabs)
    ItemExt:add_funcs(self)
end

function UpperMenu:build_tabs()
    for _, tab in pairs(self._tabs) do
        local s = self._menu:H()
        local t = self:Tab(tab.name, "textures/editor_icons_df", tab.rect, tab.callback, s, tab.enabled)
        if tab.name:match("_widget_toggle") then
            self:update_toggle(t)
        end
    end
end

function UpperMenu:Tab(name, texture, texture_rect, clbk, s, enabled)
    return self._menu:ImageButton({
        name = name,
        texture = texture,
        texture_rect = texture_rect,
        is_page = not clbk,
        enabled = enabled,
        cannot_be_enabled = enabled == false,
        on_callback = ClassClbk(self, "select_tab", clbk or false),
        disabled_alpha = 0.2,
        w = self._tab_size,
        h = self._menu:H(),
        icon_w = s - 12,
        icon_h = s - 12,
    })
end

function UpperMenu:select_tab(clbk, item)
    if clbk then
        clbk(item)
    else
        self:Switch(BLE.Utils:GetPart(item.name))
    end
end

function UpperMenu:is_tab_enabled(manager)
    local item = self:GetItem(manager)
    if item then
        return item:Enabled()
    end
    return true
end

function UpperMenu:set_tabs_enabled(enabled)
    for manager in pairs(self._parent.parts) do
        local item = self:GetItem(manager)
        if item and not item.cannot_be_enabled then
            item:SetEnabled(enabled)
        end
    end
end

function UpperMenu:Switch(manager, no_anim)
    local item = self:GetItem(manager.manager_name)
    local menu = manager._menu

    if self._parent._current_menu then
        self._parent._current_menu:SetVisible(false)
    end
    self._parent._current_menu = menu
    self._parent._current_menu_name = item.name
    menu:SetVisible(true)
    for _, it in pairs(self._menu:Items()) do
        it:SetBorder({bottom = it == item})
    end
end

function UpperMenu:save()
    self._parent:Log("Saving Map..")
    BLE.Utils:GetPart("opt"):save()
end