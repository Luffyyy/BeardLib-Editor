---Parent class for module editors.
---@class ProjectModuleEditor
ProjectModuleEditor = ProjectModuleEditor or class()
ProjectModuleEditor.HAS_ID = true

--- @param parent ProjectEditor
--- @param data table
function ProjectModuleEditor:init(parent, data, create_data)
    self._parent = parent

    create_data = create_data or {}

    if not data then
        data = self:create(create_data)
        if not data then
            return
        end
        self:finalize_creation(data, create_data)
        return
    end

    self._meta = data._meta

    self._main_xml_data = data

    if data.file ~= nil then
        local mod = self._parent._mod
        self._file_path = mod:GetRealFilePath(Path:Combine(mod.ModPath, data.file))
        self._file_type = data.file_type or "custom_xml"
        data = FileIO:ReadScriptData(self._file_path, self._file_type, true)
    end
    
    self._data = data
    self._original_data = data

    self._menu = parent._menu
    ItemExt:add_funcs(self)
    self:Init(self._data)
end

function ProjectModuleEditor:Init() end

function ProjectModuleEditor:do_build_menu()
    self:build_menu(self._menu, self._data)
end

--- For cases where the creation isn't straightforward and requires additional dialogs for example.
--- @param data table
function ProjectModuleEditor:finalize_creation(data, create_data)
    self._data = data
    self._original_data = data
    self._parent:add_module(data, create_data.no_reload)
    if create_data.final_callback then
        create_data.final_callback(true, data)
    end
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
    if self._file_path then
        -- Saves the module separately, useful for packages/add files
        FileIO:WriteScriptData(self._file_path, self._data, self._file_type, true)
    else
        return self._data
    end
end

--- Destroy function.
function ProjectModuleEditor:destroy_menu()
end

--- Delete function for any class inherting this to replace and do its things if needed.
function ProjectModuleEditor:delete()
end