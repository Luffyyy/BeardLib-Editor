---Parent class for module editors.
---@class ProjectModuleEditor
ProjectModuleEditor = ProjectModuleEditor or class()
ProjectModuleEditor.HAS_ID = true

--- @param parent ProjectEditor
--- @param data table
function ProjectModuleEditor:init(parent, data)
    self._data = data
    self._parent = parent
    self._menu = parent._menu:pan("Module")
    ItemExt:add_funcs(self)

    self:small_button("Delete", ClassClbk(self, "_delete"))
    self:small_button("Close", ClassClbk(self._parent, "close_previous_module"))

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

--- Callback function for the delete button
function ProjectModuleEditor:_delete()
    self:delete()
    self._parent:delete_module(self._data)
end

--- Delete function for any class inherting this to replace and do its things if needed.
function ProjectModuleEditor:delete()
    
end

--- Creates a small side button.
function ProjectModuleEditor:small_button(name, clbk)
    self._menu:Parent():GetToolbar():tb_btn(name, clbk, {
        min_width = 100,
        text_offset = {8, 2},
        border_bottom = true,
    })
end