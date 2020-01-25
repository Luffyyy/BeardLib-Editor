---Parent class for module editors.
---@class ProjectModuleEditor
ProjectModuleEditor = ProjectModuleEditor or class()
ProjectModuleEditor.HAS_ID = true

--- @param parent ProjectEditor
--- @param data table
function ProjectModuleEditor:init(parent, data, create_data)
    self._parent = parent

    if not data then
        data = self:create(create_data or {})
        if not data then
            return
        end
        self:finalize_creation(data)
        return
    end

    self._data = data

    self._menu = parent._menu
    ItemExt:add_funcs(self)
end

function ProjectModuleEditor:do_build_menu()
    self:build_menu(self._menu, self._data)
end

--- For cases where the creation isn't straightforward and requires additional dialogs for example.
--- @param data table
function ProjectModuleEditor:finalize_creation(data, no_reload)
    self._parent:add_module(data, no_reload)
end

--- Creates the module based on create_data which contains information about the module that should be created.
--- @param create_data table
function ProjectModuleEditor:create(create_data)
end

--- Builds the menu of the module
--- @param menu Menu
--- @param data table
function ProjectModuleEditor:build_menu(menu, data) end

--- The callback function for all items for this menu.
function ProjectModuleEditor:set_data_callback()
end

--- Save function for the data. This deals with things like filesystem and what not. Called from ProjectEditor.
function ProjectModuleEditor:save_data()
end

--- Destroy function.
function ProjectModuleEditor:destroy_menu()
end

--- Delete function for any class inherting this to replace and do its things if needed.
function ProjectModuleEditor:delete()
end