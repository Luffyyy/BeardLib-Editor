SelectMenu = SelectMenu or class(EditorPart)
function SelectMenu:init(parent, menu)
    self.super.init(self, parent, menu, "Select Menu", {make_tabs = true, scrollbar = false})
    self._tabs:s_btn("Unit", ClassClbk(self, "open_tab"), {border_bottom = true})
    self._tabs:s_btn("Element", ClassClbk(self, "open_tab"))
    self._tabs:s_btn("Instance", ClassClbk(self, "open_tab"))
    self._tab_classes = {
        unit = UnitSelectList:new(self),
        element = ElementSelectList:new(self),
        instance = InstanceSelectList:new(self),
    }
    self._tab_classes.unit:set_visible(true)
end

function SelectMenu:get_menu(name)
    return self._tab_classes[name]
end

function SelectMenu:reload_menus()
    for _, tab in pairs(self._tab_classes) do
       tab:reload()
    end
end

function SelectMenu:reload_menu(name)
    local tab = self._tab_classes[name]
    if tab then
        tab:reload()
    end
end

function SelectMenu:open_tab(item)
    for name, tab in pairs(self._tab_classes) do
        tab:set_visible(name == item.name:lower())
    end
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = tab == item})
    end
end