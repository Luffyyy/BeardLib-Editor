StatusMenu = StatusMenu or class()
function StatusMenu:init(parent, menu)
    self._menu = menu:Menu({
        name = "Status",
        auto_foreground = true,
        scrollbar = false,
        visible = false,
        position = "RightTop",
        w = 200,
        h = 100
    })
    self._text = self._menu:divider({name = "Text", text = "", text_align = "right"})
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

function StatusMenu:enabled() return true end