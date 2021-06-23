---Editor for BeardLib projects. Only usable for map related projects at the moment.
---In the future we may expand to others. The code here shouldn't focus too hard on specific modules.
---That's why some buttons like "Actions" are affected by other classes.
---@class ProjectEditor
ProjectEditor = ProjectEditor or class()
ProjectEditor.EDITORS = ProjectEditor.EDITORS or {}
ProjectEditor.ACTIONS = ProjectEditor.ACTIONS or {}

local XML = BeardLib.Utils.XML
local CXML = "custom_xml"

--- @param parent Menu
--- @param mod ModCore
function ProjectEditor:init(parent, mod, previous_project_data)
    local data = BLE.MapProject:get_clean_config(mod, true)
    self._mod = mod
    self._data = data

    self._loaded_in_editor = mod == BLE.MapProject:current_mod()

    BLE.MapProject:set_edit_title(data.name)
    local menu = parent:pan("CurrEditing", {
        w = 350,
        position = "Left",
        border_left = false,
        private = {size = 24}
    })
    self._left_menu = menu

    data.orig_id = data.orig_id or data.name

    local up = ClassClbk(self, "set_data_callback")
    if self._loaded_in_editor then
        menu:divider("Attention: we detected that this project is currently loaded. To avoid breaking the project/map, some options are disabled.")
    end
    menu:textbox("ProjectName", up, data.name, {forbidden_chars = {':','*','?','"','<','>','|'}, enabled = not self._loaded_in_editor})

    self._menu = parent:divgroup("CurrentModule", {
        private = {size = 24},
        text = "Module Properties",
        w = parent:ItemsWidth() - 350,
        h = parent:ItemsHeight(),
        auto_height = false,
        scrollbar = true,
        border_left = false,
        position = "RightOffset-X"
    })
    ItemExt:add_funcs(self)
    self._modules_list = self._left_menu:divgroup("Modules", {max_height = 400})

    self._left_menu:button("Create", ClassClbk(self, "open_create_dialog"))

    local actions = self._left_menu:divgroup("Actions")
    for id, action in pairs(self.ACTIONS) do
        actions:button(id, function()
            action(self)
        end)
    end

    self._modules = {}
    for _, modl in pairs(self._data) do
        local meta = type(modl) == "table" and modl._meta
        if meta and ProjectEditor.EDITORS[meta] then
            table.insert(self._modules, ProjectEditor.EDITORS[meta]:new(self, modl))
        end
    end

    self._save_btn = self._left_menu:button("SaveChanges", ClassClbk(self, "save_data_callback"))
    self._left_menu:button("OpenInFileExplorer", ClassClbk(self, 'open_in_file_explorer'))
    self._left_menu:button("Close", ClassClbk(BLE.MapProject, "close_current_project"))
    self:build_modules()
    if previous_project_data and previous_project_data._current_module_index and self._modules[previous_project_data._current_module_index] then
        self:open_module(self._modules[previous_project_data._current_module_index])
    elseif #self._modules > 0 then
        self:open_module(self._modules[#self._modules])
    end
end

---List the modules
function ProjectEditor:build_modules()
    local modules = self._modules_list
    modules:ClearItems()
    for _, mod in pairs(self._modules) do
        local meta = mod._meta
        local text = string.capitalize(meta)
        if ProjectEditor.EDITORS[meta].HAS_ID then
            text = text .. ": "..mod._data.id
        end
        mod._btn = modules:button(mod.id, ClassClbk(self, "open_module", mod), {text = text})
    end
end

--- Searches a module by ID and meta, used to find levels from a narrative chain at the moment.
--- @param id string
--- @param meta string
--- @return table
function ProjectEditor:get_module(id, meta)
    for _, mod in pairs(self._modules) do
        local data = mod._data
        if data._meta == meta and data.id == id then
            return mod
        end
    end
end

--- Searches a module meta, used to find levels from a narrative chain at the moment.
--- @param meta string
--- @return table
function ProjectEditor:get_module_by_meta(meta)
    for _, mod in pairs(self._modules) do
        local data = mod._data
        if data._meta == meta then
            return mod
        end
    end
end

--- Inserts a module into the data, forces a save.(if no_reload is not equals to true)
--- @param data table
--- @param no_reload boolean
function ProjectEditor:add_module(data, no_reload)
    XML:InsertNode(self._data, data)
    if not no_reload then
        self:save_data_callback()
    end
end

--- Packs all modules into a table
--- @param meta string
--- @return table
function ProjectEditor:get_modules(meta)
    local list = {}
    for _, mod in pairs(self._data) do
        local _meta = type(mod) == "table" and mod._meta
        if _meta and (not meta or _meta == meta) then
            table.insert(list, mod)
        end
    end
    return list
end

--- Opens a module to edit.
function ProjectEditor:open_module(editor)
    self:close_previous_module()

    if alive(editor._btn) then
        editor._btn:SetBorder({left = true})
    end

    self._current_module = editor
    self._current_module_index = table.get_key(self._modules, editor)
    editor:do_build_menu()

    self:small_button("Delete", ClassClbk(self, "delete_current_module"), {enabled = editor._deletable})
    self:small_button("Close", ClassClbk(self, "close_previous_module"))
end

--- The callback function for all items for this menu.
function ProjectEditor:set_data_callback()
    local data = self._data

    local name_item = self._left_menu:GetItem("ProjectName")
    local new_name = name_item:Value()
    local title = "Project Name"
    if data.id ~= new_name then
        if new_name == "" or (data.orig_id ~= new_name and BeardLib.managers.MapFramework._loaded_mods[new_name]) then
            title = title .. "[!]"
        else
            data.name = new_name
        end
    end
    name_item:SetText(title)
end

function ProjectEditor:get_dir()
    return Path:Combine(BeardLib.config.maps_dir, self._data.orig_id or self._data.name)
end

--- Saves the project data.
function ProjectEditor:save_data_callback()
    local data = self._data
    for _, mod in pairs(self._modules) do
        local new_data = mod:save_data()
        if new_data and new_data ~= mod._original_data then
            self._data[table.get_key(self._data, mod._original_data)] = new_data
            mod._original_data = new_data
        end
    end

    local id = data.orig_id or data.name
    local dir = self:get_dir()
    data.orig_id = nil

    FileIO:WriteTo(Path:Combine(dir, "main.xml"), FileIO:ConvertToScriptData(data, CXML, true)) -- Update main.xml

    if id ~= data.name then -- Project name has been changed, let's move the map folder.
        FileIO:MoveTo(dir, Path:CombineDir(BeardLib.config.maps_dir, data.name))
    end

    self:reload_mod(id, data.name)
end

--- Reloads the mod by loading it again after it was saved.
--- @param old_name string
--- @param new_name string
function ProjectEditor:reload_mod(old_name, new_name)
    old_name = old_name or self._data.orig_id
    new_name = new_name or self._data.orig_id

    BLE.MapProject:reload_mod(old_name)
    BLE.MapProject:select_project(BeardLib.managers.MapFramework._loaded_mods[new_name])
end

--- Closes the previous module, if open.
function ProjectEditor:close_previous_module()
    if self._current_module then
        self._current_module:destroy_menu()
        self._current_module = nil
    end
    for _, itm in pairs(self._left_menu:GetItem("Modules"):Items()) do
        itm:SetBorder({left = false})
    end
    self._menu:ClearItems()
end

---Deletes a module from the data.
--- @param mod table
function ProjectEditor:delete_module(mod)
    BLE.Utils:YesNoQuestion("This will delete the module. Any data related to that module will be lost and cannot retrieved.", function()
        table.delete_value(self._data, mod._data)
        table.delete_value(self._modules, mod)
        self:save_data_callback()
    end)
end

function ProjectEditor:open_create_dialog()
    local opts = {}
    for name, editor in pairs(self.EDITORS) do
        table.insert(opts, {name = name, editor = editor})
    end
    BLE.ListDialog:Show({
        list = opts,
        callback = function(selection)
            selection.editor:new(self)
            BLE.ListDialog:hide()
        end
    })
end

--- Destroy function, destroys the menu.
function ProjectEditor:destroy()
    self._left_menu:Destroy()
    self._menu:Destroy()
end

--- Deletes current open module
function ProjectEditor:delete_current_module()
    if not self._current_module then
        return
    end
    self._current_module:delete()
    self:delete_module(self._current_module)
end

--- Creates a small side button
function ProjectEditor:small_button(name, clbk, opt)
    self._menu:GetToolbar():tb_btn(name, clbk, table.merge({
        min_width = 100,
        text_offset = {8, 2},
        border_bottom = true,
    }, opt))
end

--- Opens current project in the file explorer
function ProjectEditor:open_in_file_explorer()
    Application:shell_explore_to_folder(string.gsub(self._mod.ModPath, "/", "\\"))
end

--- Returns whether this project is loaded in the editor to avoid causing issues
function ProjectEditor:loaded_in_editor()
    return self._loaded_in_editor
end

--- Returns the data of the project (main.xml)
function ProjectEditor:data()
    return self._data
end