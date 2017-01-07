UpperMenu = UpperMenu or class()
function UpperMenu:init(parent, menu)
    self._parent = parent
    self._menu = menu:NewMenu({
        name = "upper_menu",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,       
        h = 42,
        w = 300,
        row_max = 1,
        visible = true,
    })        
    self:Tab("StaticEditor", "textures/editor_icons_df", {256, 262, 115, 115})
    self:Tab("WorldDataEditor", "textures/editor_icons_df", {135, 271, 115, 115})
    self:Tab("SpawnSelect", "textures/editor_icons_df", {377, 267, 115, 115})
    self:Tab("GameOptions", "textures/editor_icons_df", {385, 385, 115, 115})
    self:Tab("Save", "textures/editor_icons_df", {260, 385, 115, 115}, callback(self, self, "save"))
    if self._parent._has_fix then 
        self:Tab("move_widget_enable", "textures/editor_icons_df", {9, 377, 115, 115}, callback(self, self, "toggle_move_widget"), 30, 30)
        self:Tab("rotation_widget_enable", "textures/editor_icons_df", {137, 383, 115, 115}, callback(self, self, "toggle_rotation_widget"), 30, 30)   
    end
end

function UpperMenu:Tab(name, texture, texture_rect, clbk, w, h)
    local menu = self._parent.managers[name]
    return self._menu:ImageButton({
        name = name,
        texture = texture,
        texture_rect = texture_rect,
        callback = clbk or callback(menu, menu, "Switch"),
        w = 36 or w,
        h = 36 or h,      
    })    
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
    self._parent.managers.GameOptions:save()
end
 