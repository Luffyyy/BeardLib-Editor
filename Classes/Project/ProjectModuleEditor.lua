---Parent class for module editors.
---@class ProjectModuleEditor
ProjectModuleEditor = ProjectModuleEditor or class()

--- @param parent ProjectEditor
--- @param data table
function ProjectModuleEditor:init(parent, data)
    self._data = data
    self._parent = parent
    self._menu = parent._menu:pan("Module")
    ItemExt:add_funcs(self)

    self:build_menu(self._menu, data)
end

--- Builds the menu of the module
--- @param menu Menu
--- @param data table
function ProjectModuleEditor:build_menu(menu, data) end

--- The callback function for all items for this menu.
function ProjectModuleEditor:set_data_callback()
end

--- Destroy function, destroys the menu.
function ProjectModuleEditor:destroy()
    self._menu:Destroy()
end