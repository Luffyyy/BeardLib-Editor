StatusMenu = StatusMenu or class()
function StatusMenu:init(parent, menu)
    self._menu = menu:Menu({
        name = "Status",
        auto_foreground = true,
        scrollbar = false,
        visible = false,
        w = 200,
        h = 100
    })
    local w = BLE.Options:GetValue("MapEditorPanelWidth")
    self._text = self._menu:divider({name = "Text", text = "", text_align = "right"})
    self._menu:SetPosition( BLE.Options:GetValue("GUIOnRight") and menu:W() - w - 200 or w, 0)
end

function StatusMenu:SetVisible(visible)
    self._menu:SetVisible(visible)
end

function StatusMenu:SetStatus(status)
    if not status then
        self:SetVisible(false)
    end
    if status then
        self._text:SetText(status)
    end
end

function StatusMenu:ShowKeybindMessage(message)
    if message then
        self:SetVisible(true)
        self._text:SetText(message)
        BeardLib:AddDelayedCall("BLEStatusKeybindMessage", 2, function()
            self:SetVisible(false)
        end)
    end
end

function StatusMenu:enabled() return true end