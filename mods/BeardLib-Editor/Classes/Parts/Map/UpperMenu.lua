UpperMenu = UpperMenu or class()
function UpperMenu:init(parent, menu)
    self._parent = parent 
    self._tabs = {
        {name = "static", rect = {256, 262, 115, 115}},
        {name = "wdata", rect = {135, 271, 115, 115}},
        {name = "spwsel", rect = {377, 267, 115, 115}},
        {name = "env", rect = {15, 267, 115, 115}},
        {name = "opt", rect = {385, 385, 115, 115}},
        {name = "save", rect = {260, 385, 115, 115}, callback = callback(self, self, "save")},
        {name = "move_widget_toggle", rect = {9, 377, 115, 115}, callback = callback(self, self, "toggle_widget", "move"), enabled = self._parent._has_fix},
        {name = "rotation_widget_toggle", rect = {137, 383, 115, 115}, callback = callback(self, self, "toggle_widget", "rotation"), enabled = self._parent._has_fix},
    }
    local w = 300
    self._menu = menu:Menu({
        name = "upper_menu",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,       
        w = w,
        h = w / #self._tabs,
        offset = 0,
        align_method = "grid",
        scrollbar = false,
        visible = true,
    })
end

function UpperMenu:build_tabs()
    for _, tab in pairs(self._tabs) do
        local s = self._menu.w / #self._tabs
        self:Tab(tab.name, "textures/editor_icons_df", tab.rect, tab.callback, s, tab.enabled)
    end
end

function UpperMenu:get_menu_h()
    return self._menu:Panel():parent():h() - self._menu.h - 1
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
        self._parent.managers[item.name]:Switch()
        for manager in pairs(self._parent.managers) do
            local mitem = self._menu:GetItem(manager)
            if mitem and mitem.is_page then
                mitem.marker_color = menu.marker_color
                mitem.marker_highlight_color = mitem.marker_color
                mitem:UnHighlight()
            end
        end
        item.marker_color = menu.marker_highlight_color
        item.marker_highlight_color = item.marker_color
        item:UnHighlight()
    end
end

function UpperMenu:set_tabs_enabled(enabled)
    for manager in pairs(self._parent.managers) do
        local item = self._menu:GetItem(manager)
        if item and not item.cannot_be_enabled then
            item:SetEnabled(enabled)
        end
    end
end

function UpperMenu:toggle_widget(name, menu, item)
    item = item or self._menu:GetItem(name.."_widget_toggle")   
    if not item.enabled then
        return
    end
    menu = menu or item.parent
    self._parent["_use_"..name.."_widget"] = not self._parent["_use_"..name.."_widget"]
    self._parent:use_widgets()
    item.marker_color = self._parent["_use_"..name.."_widget"] and menu.marker_highlight_color or menu.marker_color
    item.marker_highlight_color = item.marker_color
    item:UnHighlight()
end

function UpperMenu:SwitchMenu(menu)
    if self._parent._current_menu then
        self._parent._current_menu:SetVisible(false)
    end
    self._parent._current_menu = menu
    menu:SetVisible(true)
end

function UpperMenu:save()
    self._parent:Log("Saving Map..")
    self._parent.managers.opt:save()
end
 