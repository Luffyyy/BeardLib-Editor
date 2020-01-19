---Editor for BeardLib projects. Only usable for map related projects at the moment.
---@class ProjectEditor
ProjectEditor = ProjectEditor or class()
ProjectEditor.EDITORS = {}

--- @param parent Menu
--- @param data table
function ProjectEditor:init(parent, data)
    self._data = data

    local btns = parent:GetItem("QuickActions")
    local menu = parent:divgroup("CurrEditing", {
        private = {size = 24},
        w = 350,
        position = "Left",
        text = "Currently Editing: "..data.name,
        border_left = false,
        auto_height = false, h = parent:ItemsHeight() - btns:OuterHeight() - btns:OffsetY() * 2
    })
    self._left_menu = menu
    menu:textbox("ProjectName", up, data.name)

    --List the instances
    local modules = menu:divgroup("Modules")
    for _, mod in pairs(data) do
        local meta = type(mod) == "table" and mod._meta
        if meta and ProjectEditor.EDITORS[meta] then
            modules:button(mod.id, ClassClbk(self, "open_module", mod), {text = string.capitalize(meta)..": "..mod.id})
        end
    end

    self._menu = parent:divgroup("CurrentModule", {
        private = {size = 24},
        text = "Current Module: None",
        w = parent:ItemsWidth() - 350,
        border_left = false,
        position = "Right"
    })

    ItemExt:add_funcs(self)
end

--- Opens a module to edit.
function ProjectEditor:open_module(data, item)
    self:close_previous_module()
    self._current_module = ProjectEditor.EDITORS[data._meta]:new(self, data)
    for _, itm in pairs(item:Parent():Items()) do
        itm:SetBorder({left = itm == item})
    end
end

--- The callback function for all items for this menu.
function ProjectEditor:set_data_callback()
    local data = self._data
    data.name = self:GetItemValue("ProjectName")
end
--- Saves the project data.
function ProjectEditor:save_data()

end

--- Closes the previous module, if open.
function ProjectEditor:close_previous_module()
    if self._current_module then
        self._current_module:destroy()
        self._current_module = nil
    end
end

--- Destroy function, destroys the menu.
function ProjectEditor:destroy()
    self._left_menu:Destroy()
    self._menu:Destroy()
end