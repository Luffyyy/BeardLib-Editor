UpperMenu = UpperMenu or class()
function UpperMenu:get_menu_h() return self._menu:Panel():parent():h() - self._menu.h - 1 end
function UpperMenu:init(parent, menu)
    self._parent = parent
    local normal = not Global.editor_safe_mode
    self._tabs = {
        {name = "static", rect = {256, 262, 115, 115}, enabled = normal},
        {name = "wdata", rect = {135, 271, 115, 115}, enabled = normal},
        {name = "utils", rect = {377, 267, 115, 115}},
        {name = "env", rect = {15, 267, 115, 115}},
        {name = "opt", rect = {385, 385, 115, 115}},
        {name = "save", rect = {260, 385, 115, 115}, callback = callback(self, self, "save"), enabled = normal},
        {name = "move_widget_toggle", rect = {9, 377, 115, 115}, callback = callback(self, self, "toggle_widget", "move"), enabled = normal and self._parent._has_fix},
        {name = "rotation_widget_toggle", rect = {137, 383, 115, 115}, callback = callback(self, self, "toggle_widget", "rotation"), enabled = normal and self._parent._has_fix},
    }
    local w = 300
    self._menu = menu:Menu({
        name = "upper_menu",
        background_color = BeardLibEditor.Options:GetValue("BackgroundColor"),
        marker_highlight_color = BeardLibEditor.Options:GetValue("AccentColor"),
        w = w,
        h = w / #self._tabs,
        offset = 0,
        align_method = "grid",
        scrollbar = false,
        visible = true,
    })
    MenuUtils:new(self)
end

function UpperMenu:build_tabs()
    for _, tab in pairs(self._tabs) do
        local s = self._menu.w / #self._tabs
        self:Tab(tab.name, "textures/editor_icons_df", tab.rect, tab.callback, s, tab.enabled)
    end
end

function UpperMenu:Tab(name, texture, texture_rect, clbk, s, enabled)
    local menu = self._parent.managers[name]
    return self._menu:ImageButton({
        name = name,
        texture = texture,
        texture_rect = texture_rect,
        is_page = not clbk,
        enabled = enabled,
        cannot_be_enabled = enabled == false,
        marker_highlight_color = self._menu.marker_color,
        callback = callback(self, self, "select_tab", clbk or false),
        w = s,
        h = s,
        icon_w = s - 10,
        icon_h = s - 10,      
    })    
end

function UpperMenu:select_tab(clbk, menu, item)
    if clbk then
        clbk(menu, item)
    else
        self:Switch(self._parent.managers[item.name])
    end
end

function UpperMenu:set_tabs_enabled(enabled)
    for manager in pairs(self._parent.managers) do
        local item = self:GetItem(manager)
        if item and not item.cannot_be_enabled then
            item:SetEnabled(enabled)
        end
    end
end

function UpperMenu:toggle_widget(name, menu, item)
    item = item or self:GetItem(name.."_widget_toggle")
    menu = menu or item.parent
    if not item.enabled then return end
    
    self._parent["toggle_"..name.."_widget"](self._parent)
    self._parent:use_widgets(self._parent:selected_unit() ~= nil)
    self:animate_bottom(item, self._parent[name.."_widget_enabled"](self._parent))
end

function UpperMenu:Switch(manager)
    local item = self:GetItem(manager.manager_name)
    local menu = manager._menu

    if self._parent._current_menu then
        self._parent._current_menu:SetVisible(false)
    end
    self._parent._current_menu = menu
    menu:SetVisible(true)
    for manager in pairs(self._parent.managers) do
        local mitem = self:GetItem(manager)
        if mitem and mitem.is_page then
            self:animate_bottom(mitem, false)
        end
    end
    self:animate_bottom(item, true)
end

function UpperMenu:animate_bottom(item, show)
    if alive(item) then
        local bottom
        if show then
            item:SetBorder({bottom = true})
            bottom = item:Panel():child("bottom")
            if alive(bottom) then
                local h = bottom:parent():h()
                bottom:set_h(h)
                bottom:set_alpha(0)
                QuickAnim:Work(bottom, "speed", 10, "h", 2, "alpha", 1, "sticky_bottom", h)
            end
        else
            if item.border_bottom then
                bottom = item:Panel():child("bottom")
                if alive(bottom) then
                    QuickAnim:Work(bottom, "speed", 10, "alpha", 0, "callback", function()
                        item:SetBorder({bottom = false})
                    end)
                end
            end
        end
    end
end

function UpperMenu:save()
    self._parent:Log("Saving Map..")
    self._parent.managers.opt:save()
end