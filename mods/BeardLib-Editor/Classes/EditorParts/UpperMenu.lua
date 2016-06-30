UpperMenu = UpperMenu or class()
function UpperMenu:init(parent, menu)
    self._parent = parent
    self._menu = menu:NewMenu({
        name = "upper_menu",
        help = "",
        h = 42,
        w = 250,
        row_max = 1,
        visible = true,
    })        
    self._menu:ImageButton({
        name = "units",
        texture = "core/textures/editor_icons_df",
        texture_rect = {113, 125, 115, 115},
        callback = callback(self, self, "SwitchMenu", menu:GetItem("selected_unit")),
        w = 36,
        h = 36,
    })       
    self._menu:ImageButton({
        name = "mission_elements",
        texture = "core/textures/editor_icons_df",
        texture_rect = {241, 121, 115, 115},
        callback = callback(self, self, "SwitchMenu", menu:GetItem("selected_element")),
        w = 36,
        h = 36,      
    })  
    self._menu:ImageButton({
        name = "options",
        texture = "core/textures/editor_icons_df",
        texture_rect = {376, 254, 115, 115},
        callback = callback(self, self, "SwitchMenu", menu:GetItem("game_options")),
        w = 36,
        h = 36,      
    })        
    self._menu:ImageButton({
        name = "save",
        texture = "core/textures/editor_icons_df",
        texture_rect = {249, 251, 115, 115},
        callback = callback(self, self, "save"),
        w = 36,
        h = 36,      
    })      
    self._menu:Divider({
        name = "empty",
        w = 32,     
        color = Color(0,0,0,0),  
    })   
    if self._parent._has_fix then 
        self._menu:ImageButton({
            name = "move_widget_enable",
            texture = "core/textures/editor_icons_df",
            texture_rect = {9, 377, 115, 115},
            callback = callback(self, self, "toggle_move_widget"),
            w = 26,
            h = 26,      
        })       
        self._menu:ImageButton({
            name = "rotation_widget_enable",
            texture = "core/textures/editor_icons_df",
            texture_rect = {13, 236, 115, 115},
            callback = callback(self, self, "toggle_rotation_widget"),
            w = 26,
            h = 26,      
        })    
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
function UpperMenu:enable()
    self._menu:enable()
end
function UpperMenu:SwitchMenu(menu)
    self._parent._current_menu:SetVisible(false)
    self._parent._current_menu = menu
    menu:SetVisible(true)
end

function UpperMenu:save()
    BeardLibEditor:log("Saving Map..")
    self._parent.managers.GameOptions:save()
end

function UpperMenu:disable()
    self._menu:disable()
end
