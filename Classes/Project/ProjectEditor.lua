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
        text = "Currently Editing: "..data.name,
        h = parent:ItemsHeight() - btns:OuterHeight() - btns:OffsetY() * 2,
        w = 350,
        position = "Left",
        border_left = false,
        auto_height = false,
        private = {size = 24}
    })
    self._left_menu = menu
    menu:textbox("ProjectName", up, data.name)

    self._menu = parent:divgroup("CurrentModule", {
        private = {size = 24},
        text = "Current Module: None",
        w = parent:ItemsWidth() - 350,
        h = menu:Height(),
        auto_height = false,
        border_left = false,
        position = "Right"
    })
    ItemExt:add_funcs(self)
    self._modules = self._left_menu:divgroup("Modules")

    self:build_modules()
end

---List the modules
function ProjectEditor:build_modules()
    local modules = self._modules
    modules:ClearItems()
    for _, mod in pairs(self._data) do
        local meta = type(mod) == "table" and mod._meta
        if meta and ProjectEditor.EDITORS[meta] then
            local text = string.capitalize(meta)
            if ProjectEditor.EDITORS[meta].HAS_ID then
                text = text .. ": "..mod.id
            end
            local btn = modules:button(mod.id, ClassClbk(self, "open_module", mod), {text = text})
            if meta == "narrative" then
                self:open_module(mod, btn)
            end
        end
    end
end

--- Opens a module to edit.
function ProjectEditor:open_module(data, item)
    self:close_previous_module()
    item:SetBorder({left = true})
    self._current_module = ProjectEditor.EDITORS[data._meta]:new(self, data)
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
    for _, itm in pairs(self._left_menu:GetItem("Modules"):Items()) do
        itm:SetBorder({left = false})
    end
    self._menu:ClearItems()
end

function ProjectEditor:delete_module(data)
    table.delete_value(self._data, data)
    self:close_previous_module()
    self:build_modules()
end

--- Destroy function, destroys the menu.
function ProjectEditor:destroy()
    self._left_menu:Destroy()
    self._menu:Destroy()
end