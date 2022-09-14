StatusMenu = StatusMenu or class()
function StatusMenu:init(parent, menu)
    self._menu = menu:Menu({
        name = "Status",
        auto_foreground = true,
        scrollbar = false,
        visible = true,
        align_method = gui_right and "grid_from_right", "grid",
        inherit_values = {
            background_color = BLE.Options:GetValue("BackgroundColor")
        },
        size = BLE.Options:GetValue("StatusMenuFontSize"),
        w = BLE.Options:GetValue("StatusMenuFontSize") * 16,
        auto_height = true,
    })

    self._text = self._menu:lbl("Text", {visible = false, size_by_text = true, color = true, offset = {4, 2}})
    
    local w = BLE.Options:GetValue("MapEditorPanelWidth")
    local gui_right = BLE.Options:GetValue("GUIOnRight")
    self._menu:SetPosition(gui_right and menu:W() - w - self._menu:W() or w)
    if BLE.Options:GetValue("ToolbarPosition") == 2 then
        self._menu:SetPosition(nil, BLE.Options:GetValue("QuickAccessToolbarSize"))
    end
end

function StatusMenu:StatusDialog(title, subtitle, buttons)
    local dialog = self._menu:holder(title, {border_left = true, inherit_values = {offset = 0}})
    dialog:lbl("Title", {text = title, size = self._menu.size * 1.1})
    dialog:lbl("Sub", {text = subtitle or ""})
    if buttons then
        local btns = dialog:holder(title, {align_method = "grid_from_right", position = "RightBottom"})
        for _, button in ipairs(buttons) do
            btns:button(button.name, button.callback, {size_by_text = true, offset = 0})
        end
    end
    dialog:SetIndex(1)

    return dialog
end

function StatusMenu:StatusMessage(message)
    if message then
        self._text:SetVisible(true)
        self._text:SetText(message)
        BeardLib:AddDelayedCall("BLEStatusMessage", 2, function()
            self._text:SetVisible(false)
        end)
    end
end

function StatusMenu:enabled() return true end