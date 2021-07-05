SelectMenu = SelectMenu or class(EditorPart)
function SelectMenu:init(parent, menu)    
    SelectMenu.super.init(self, parent, menu, "Select Menu", {make_tabs = true, scrollbar = false})
    local unit_key = BLE.Options:GetValue("Input/SelectUnit")
    local element_key = BLE.Options:GetValue("Input/SelectElement")
    local instance_key = BLE.Options:GetValue("Input/SelectInstance")

    self._tabs:s_btn("Unit", ClassClbk(self, "open_tab"), {border_bottom = true, text = string.len(unit_key) > 0 and "Unit ("..unit_key..")" or nil})
    self._tabs:s_btn("Element", ClassClbk(self, "open_tab"), {text = string.len(element_key) > 0 and "Element ("..element_key ..")" or nil})
    self._tabs:s_btn("Instance", ClassClbk(self, "open_tab"), {text = string.len(instance_key) > 0 and "Instance ("..instance_key ..")" or nil})
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

function SelectMenu:set_selected_objects()
    for _, tab in pairs(self._tab_classes) do
        tab:set_selected_objects()
     end
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
    local name = item.name:lower()
    for n, tab in pairs(self._tab_classes) do
        tab:set_visible(n == name)
    end
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = tab == item})
    end
end

function SelectMenu:open_tab_by_name(name, switch_to_menu)
    for n, tab in pairs(self._tab_classes) do
        tab:set_visible(n == name)
    end
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = tab.name:lower() == name})
    end
    if switch_to_menu then
        self:Switch("select")
    end
end

function SelectMenu:enable()
    SelectMenu.super.enable(self)
    self:bind_opt("SelectUnit", ClassClbk(self, "open_tab_by_name", "unit", true))
    self:bind_opt("SelectElement", ClassClbk(self, "open_tab_by_name", "element", true))
end