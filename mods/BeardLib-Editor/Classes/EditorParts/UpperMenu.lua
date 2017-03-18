UpperMenu = UpperMenu or class()
function UpperMenu:init(parent, menu)
    self._parent = parent
    self._menu = menu:Menu({
        name = "upper_menu",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,       
        h = 42,
        w = 300,
        align_method = "grid",
        scrollbar = false,
        visible = true,
    })      
    local tabs = {
        {name = "static", rect = {256, 262, 115, 115}},
        {name = "wdata", rect = {135, 271, 115, 115}},
        {name = "spwsel", rect = {377, 267, 115, 115}},
        {name = "opt", rect = {385, 385, 115, 115}},
        {name = "save", rect = {260, 385, 115, 115}, callback = callback(self, self, "save")},
        {name = "move_widget_toggle", rect = {9, 377, 115, 115}, callback = callback(self, self, "toggle_move_widget"), enabled = self._parent._has_fix},
        {name = "rotation_widget_toggle", rect = {137, 383, 115, 115}, callback = callback(self, self, "toggle_rotation_widget"), enabled = self._parent._has_fix},
    }  
    for _, tab in pairs(tabs) do
        if tab.enabled ~= false then
            local s = self._menu.w / #tabs 
            self:Tab(tab.name, "textures/editor_icons_df", tab.rect, tab.callback, s)
        end
    end
end

function UpperMenu:Tab(name, texture, texture_rect, clbk, s)
    local menu = self._parent.managers[name]
    return self._menu:ImageButton({
        name = name,
        texture = texture,
        texture_rect = texture_rect,
        callback = clbk or callback(menu, menu, "Switch"),
        w = s - 4,
        h = s - 4,      
    })    
end

function UpperMenu:set_tabs_enabled(enabled)
    for manager in pairs(self._parent.managers) do
        local item = self._menu:GetItem(manager)
        if item then
            item:SetEnabled(enabled)
        end
    end
end

function UpperMenu:toggle_move_widget()
    self._parent._use_move_widget = not self._parent._use_move_widget
    self._parent:use_widgets()
end

function UpperMenu:toggle_rotation_widget()
    self._parent._use_rotation_widget = not self._parent._use_rotation_widget
    self._parent:use_widgets()
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
 