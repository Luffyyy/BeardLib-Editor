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
    self._text = self._menu:Divider({name = "Text", text = "", text_align = "right"})
end

function StatusMenu:SetStatus(status)
    self._menu:SetVisible(not not status)
    if status then
        self._text:SetText(status)
    end
end