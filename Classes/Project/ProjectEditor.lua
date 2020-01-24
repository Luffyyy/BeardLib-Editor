---Editor for BeardLib projects. Only usable for map related projects at the moment.
---@class ProjectEditor
ProjectEditor = ProjectEditor or class()
ProjectEditor.EDITORS = {}

local XML = BeardLib.Utils.XML
local CXML = "custom_xml"

--- @param parent Menu
--- @param mod ModCore
function ProjectEditor:init(parent, mod)
    local data = BLE.MapProject:get_clean_config(mod, true)
    self._mod = mod
    self._data = data
    self._to_delete = {}

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

    data.orig_id = data.orig_id or data.name

    local up = ClassClbk(self, "set_data_callback")
    menu:textbox("ProjectName", up, data.name, {forbidden_chars = {':','*','?','"','<','>','|'}})

    self._menu = parent:divgroup("CurrentModule", {
        private = {size = 24},
        text = "Module Properties",
        w = parent:ItemsWidth() - 350,
        h = menu:Height(),
        auto_height = false,
        border_left = false,
        position = "Right"
    })
    ItemExt:add_funcs(self)
    self._modules = self._left_menu:divgroup("Modules")

    self._left_menu:button("Create", ClassClbk(self, "open_create_dialog"))
    self._save_btn = self._left_menu:button("SaveChanges", ClassClbk(self, "save_data_callback"))
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
            local btn = modules:button(mod.id, ClassClbk(self, "open_module", mod), {text = text, module = mod})
            if meta == "narrative" then
                self:open_module(mod)
            end
        end
    end
end

--- Searches a module by ID and meta, used to find levels from a narrative chain at the moment.
--- @param id string
--- @param meta string
--- @return table
function ProjectEditor:get_module(id, meta)
    for _, mod in pairs(self._data) do
        local _meta = type(mod) == "table" and mod._meta
        if _meta and _meta == meta and mod.id == id then
            return mod
        end
    end
end

--- Inserts a module into the data, forces a save.
--- @param data table
function ProjectEditor:add_module(data)
    XML:InsertNode(self._data, data)
    self:save_data_callback()
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
--- @param data table
function ProjectEditor:open_module(data)
    self:close_previous_module()
    for _, item in pairs(self._modules:Items()) do
        if item.module == data then
            item:SetBorder({left = true})
        end
    end
    self._current_module = ProjectEditor.EDITORS[data._meta]:new(self, data)
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

    local id = data.orig_id or data.name
    local map_path = self:get_dir()

    for _, delete in pairs(self._to_delete) do
        if delete._meta == "level" then
            FileIO:Delete(Path:Combine(map_path, "levels", delete.orig_id or delete.id))
        end
    end
    self._to_delete = {}

    for _, level in pairs(XML:GetNodes(data, "level")) do
        local level_id = level.id
        local orig_id = level.orig_id or level_id
        if orig_id ~= level_id then -- Level ID has been changed, let's delete the old ID to let the new ID replace it and move the folder.
            local include_dir = Path:Combine("levels", level_id)
            level.include.directory = include_dir
            if level.add.file then
                level.add.file = Path:Combine(include_dir, "add.xml")
            end
            FileIO:MoveTo(Path:Combine(map_path, "levels", orig_id), Path:Combine(map_path, include_dir))
            tweak_data.levels[orig_id] = nil
            table.delete(tweak_data.levels._level_index, orig_id)
        end
        level.orig_id = nil
    end
    for _, narr in pairs(XML:GetNodes(data, "narrative")) do
        local orig_id = narr.orig_id or narr.id -- Narrative ID has been changed, let's delete the old ID.
        if orig_id ~= narr.id then
            tweak_data.narrative.jobs[orig_id] = nil
            table.delete(tweak_data.narrative._jobs_index, orig_id)
        end
        narr.orig_id = nil
    end

    data.orig_id = nil

    FileIO:WriteTo(Path:Combine(map_path, "main.xml"), FileIO:ConvertToScriptData(data, CXML, true)) -- Update main.xml

    if id ~= data.name then -- Project name has been changed, let's move the map folder.
        FileIO:MoveTo(map_path, Path:Combine(BeardLib.config.maps_dir, data.name))
    end

    self:reload_mod(id, data.name)
end

--- Reloads the mod by loading it again after it was saved.
--- @param old_name string
--- @param new_name string
function ProjectEditor:reload_mod(old_name, new_name)
    local mod = self._mod
    if mod._modules then
        for _, module in pairs(mod._modules) do
            module.Registered = false
        end
    end
    BLE.MapProject:reload_mod(old_name)
    BLE.MapProject:_select_project(BeardLib.managers.MapFramework._loaded_mods[new_name])
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

---Deletes a module from the data.
--- @param data table
function ProjectEditor:delete_module(data)
    table.insert(self._to_delete, data)
    table.delete_value(self._data, data)
    self:close_previous_module()
    self:build_modules()
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