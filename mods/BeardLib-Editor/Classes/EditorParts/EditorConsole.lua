EditorConsole = EditorConsole or class()
function EditorConsole:init(parent, menu)
    self._parent = parent
    self._options_menu = menu:NewMenu({
        name = "console_options",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,        
        w = 600,
        h = 20,
        padding = 0,
        size_by_text = true,
        row_max = 1,
        visible = true,
    })       
    self._menu = menu:NewMenu({
        name = "console_output",
        position = "Center|Bottom",    
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,         
        override_size_limit = true,  
        size_by_text = true,
        w = 600,
        should_scroll_down = true,
        h = 100,
        visible = true,
    })      
    self._options_menu:Panel():set_leftbottom(self._menu:Panel():lefttop())    
    self._options_menu:Button({
        name ="hide_console",
        text = "Console ",
        w = w,
        color = Color.white,
        callback = callback(self, self, "ToggleConsole"),
    })
    self._options_menu:Button({
        name ="cleat_button",
        text = "Clear",
        color = Color.white,
        callback = callback(self, self, "Clear"),
    })
    self._show_info = self._options_menu:Toggle({
        name ="show_info",
        text = "Info",
        value = true,
        color = Color.white,
        callback = callback(self, self, "FilterConsole"),
    }) 
    self._show_mission = self._options_menu:Toggle({
        name ="show_mission",
        text = "Mission",
        value = true,        
        color = Color.yellow,
        callback = callback(self, self, "FilterConsole"),
    })
    self._show_errors = self._options_menu:Toggle({
        name ="show_errors",
        text = "Errors",
        value = true,        
        color = Color.red,
        callback = callback(self, self, "FilterConsole"),
    })

    self:Clear()
    self:ToggleConsole()
end

function EditorConsole:Log(msg, ...)
    msg = string.format(msg, ...)
    local date = Application:date("%X")    
    table.insert(self._messages, {message = tostring(msg), date = date, typ = "info"})
    if self._show_info.value then
        self._menu:Divider({
            text = date .. ": " .. tostring(msg),
            color = Color.white,
        })
    end
end
function EditorConsole:LogMission(msg)
    local date = Application:date("%X")    
    table.insert(self._messages, {message = tostring(msg), date = date,  typ = "mission"})
    if self._show_mission.value then
        self._menu:Divider({
            text = date .. ": " .. tostring(msg),
            color = Color.yellow,
        })
    end
end
function EditorConsole:Error(msg, ...)
    msg = string.format(msg, ...)
    local date = Application:date("%X")
    table.insert(self._messages, {message = tostring(msg), date = date, typ = "error"})
    if self._show_errors.value then
        self._menu:Divider({
            text = date .. ": " .. tostring(msg),
            color = Color.red,
        })
    end
end

function EditorConsole:ToggleConsole()    
    self.closed = not self.closed
    if self.closed then
        self._options_menu:AnimatePosition("bottom")
    else
        self._options_menu:AnimatePosition("bottom", self._menu:Panel():top())
    end
    self._menu:SetVisible(not self.closed)
end
function EditorConsole:Clear()
    self._messages = {}
    self:FilterConsole()    
end

function EditorConsole:FilterConsole()
    self._menu:ClearItems()
    for _, msg in pairs(self._messages) do
        if (msg.typ == "info" and self._show_info.value) or (msg.typ == "mission" and self._show_mission.value) or (msg.typ == "error" and self._show_errors.value) then
            self._menu:Divider({
                text = msg.date .. ": " .. tostring(msg.message),
                color = msg.typ == "info" and Color.white or msg.typ == "mission" and Color.yellow or Color.red,
            })
        end
    end
end
