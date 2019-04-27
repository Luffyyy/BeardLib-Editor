EditorConsole = EditorConsole or class(EditorPart)
function EditorConsole:init(parent, menu)
    self._parent = parent
    self._options_menu = menu:Menu({
        name = "console_options",
        background_color = BeardLibEditor.Options:GetValue("BackgroundColor"),
        auto_height = true,
        offset = 0,
        layer = 999,
        items_size = 18,
        position = "TopLeft",
        scrollbar = false,
        visible = false,
        align_method = "grid",
    })
    self._menu = menu:Menu({
        name = "console_output",
        h = 400,
        layer = 999,
        size_by_text = true,
        override_size_limit = true,
        should_scroll_down = true,
        visible = false,
        position = function(item)
            item:Panel():set_position(self._options_menu:Panel():leftbottom())    
        end,
        background_color = BeardLibEditor.Options:GetValue("BackgroundColor"),
    })
    MenuUtils:new(self, self._options_menu)
    local opt = {border_bottom = true, text_align = "center", border_size = 1, border_color = BeardLibEditor.Options:GetValue("AccentColor"), w = self._options_menu.w / 5}
    self:Button("Close", ClassClbk(self, "ToggleConsole"), opt)
    self:Button("Clear", ClassClbk(self, "Clear"), table.merge(opt, {border_color = Color("ffc300")}))
    self.info = self:Toggle("Info", ClassClbk(self, "FilterConsole"), true, table.merge(opt, {border_color = Color.yellow}))
    self.mission = self:Toggle("Mission", ClassClbk(self, "FilterConsole"), false, table.merge(opt, {border_color = Color.green}))
    self.error = self:Toggle("Errors", ClassClbk(self, "FilterConsole"), true, table.merge(opt, {border_color = Color.red}))
    MenuUtils:new(self)
    self:Clear()
    self.closed = true
    self._triggers = {}
end

function EditorConsole:ToggleConsole()
    self.closed = not self.closed
    self._options_menu:SetVisible(not self.closed)
    self._menu:SetVisible(not self.closed)
end

function EditorConsole:PrintMessage(type, message, ...)
    message = string.format(message, ...)
    local date = Application:date("%X")  
    self:Divider(date .. ": " .. tostring(message), {type = type, visible = self[type]:Value(), border_color = type == "mission" and Color.green or type == "error" and Color.red or Color.yellow})
    
    if #self._menu._my_items > 100 then --hardcoded for now
        self:RemoveItem(self._menu._my_items[1])
    end

    if self._menu.items_panel:h() > self._menu.panel:h() and not self._menu._grabbed_scroll_bar then
        self._menu.items_panel:set_bottom(self._menu.items_panel:parent():h())
        self._menu:CheckItems()
        self._menu._scroll:_check_scroll_indicator_states()
    end
end

function EditorConsole:FilterConsole(item)
    for _, item in pairs(self._menu._my_items) do
        item:SetVisible(self[item.type]:Value())
    end
end

function EditorConsole:Log(msg, ...) self:PrintMessage("info", msg, ...) end 
function EditorConsole:LogMission(msg, ...) self:PrintMessage("mission", msg, ...) end
function EditorConsole:Error(msg, ...) self:PrintMessage("error", msg, ...) end
function EditorConsole:Clear() self:ClearItems() end


function EditorConsole:disable()
    EditorConsole.super.disable(self)
    self._enabled = false
end

function EditorConsole:enable()
    EditorConsole.super.enable(self)
    self:bind_opt("ToggleConsole", ClassClbk(self, "ToggleConsole"))
    self._enabled = true
end