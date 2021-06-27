---Editor for BeardLib Localization module.
---@class ProjectLocalization : ProjectModuleEditor
ProjectLocalization = ProjectLocalization or class(ProjectModuleEditor)
ProjectLocalization.HAS_ID = false
ProjectEditor.EDITORS.Localization = ProjectLocalization

local XML = BeardLib.Utils.XML

function ProjectLocalization:Init(data)
    self._deleted = {}
    self._languages = {}
    self._languages_to_save = {}
    self._languages_to_delete = {}
    for _, tbl in ipairs(data) do
        if tbl._meta == "localization" or tbl._meta == "loc" then
            self._languages[tbl.language] = tbl.file
        end
    end
    self._dir = data.directory or "loc"
    if #self._languages == 0 and data.default then
        self._languages[data.default:split("%.")[1]] = data.default
    end
    if #self._languages == 0 then
        data = self:create()
        self._languages.english = data.default
    end
end

--- @param menu Menu
--- @param data table
function ProjectLocalization:build_menu(menu, data)
    local actions = self:pan("Actions", {align_method = "grid"})
    local langs = table.map_keys(self._languages)
    local lang = actions:combobox("Language", ClassClbk(self, "open_lang_clbk"), langs)
    actions.inherit_values = {w = actions:ItemsWidth() / 4 - actions:OffsetX() * 2, text_align = "center"}
    actions:button("AddString", ClassClbk(self, "insert_string_item", "", ""), {enabled = false})
    actions:button("AddLanguage", ClassClbk(self, "add_lang"))
    actions:button("RemoveLanguage", ClassClbk(self, "remove_lang"))
    actions:button("MakeDefault", ClassClbk(self, "make_lang_default"))
    self._strings_panel = self:pan("Strings", {max_height = self._menu:ItemsHeight() - actions:OuterHeight() - self._menu:OffsetY() - 10, auto_align = false})
    lang:SetSelectedItem(table.get_key(self._languages, data.default) or langs[1], true)
end

function ProjectLocalization:make_lang_default()
    self._data.default = self._current_lang_name
end

function ProjectLocalization:add_lang()
    BLE.InputDialog:Show({
        title = "Language name",
        message = "Make sure the language is supported in the game.",
        yes = "Create",
        text = "",
        check_value = function(name)
            local warn

            if FileIO:Exists(Path:Combine(self._parent:get_dir(), self._dir, name..".txt")) then
                warn = string.format("A file with the name %s already exists! Please use a unique name", name)
            elseif name == "" then
                warn = string.format("Id cannot be empty!", name)
            elseif string.begins(name, " ") then
                warn = "Invalid ID!"
            end

            if warn then
                BLE.Utils:Notify("Error", warn)
            end
            return warn == nil
        end,
        callback = function(name)
            local file = name..".txt"
            self._languages[name] = file
            self._languages_to_save[file] = {}
            self:GetItem("Language"):SetItems(table.map_keys(self._languages))
        end
    })
end

function ProjectLocalization:remove_lang()
    local to_delete = self._current_lang_name
    if self._data.default == to_delete then
        BLE.Utils:Notify("Error", "Cannot delete the default language.")
    else
        self._languages_to_delete[to_delete] = true
        self._languages_to_save[to_delete] = nil
        table.delete_value(self._languages, to_delete)
        local lang = self:GetItem("Language")
        lang:SetItems(table.map_keys(self._languages))
        lang:SetValue(1, true)
    end
end

function ProjectLocalization:open_lang_clbk(item)
    self:open_lang(self._languages[item:SelectedItem()])
end

function ProjectLocalization:open_lang(file)
    if not file then
        BLE:log("No language file for %s", tostring(file))
        self:GetItem("AddString"):SetEnabled(false)
        return
    end
    self:GetItem("AddString"):SetEnabled(true)

    local path = Path:Combine(self._parent:get_dir(), self._dir, file)
    self._current_lang = self._languages_to_save[file] or (FileIO:Exists(path) and FileIO:ReadScriptData(path, "json") or {})
    self._current_lang_name = file
    self._languages_to_save[file] = self._current_lang
    self._strings_panel:ClearItems()
    for key, str in pairs(self._current_lang) do
        self:insert_string_item(key, str)
    end
    self._strings_panel:AlignItems(true)
    self:GetItem("MakeDefault"):SetEnabled(self._data.default ~= file)
    self:GetItem("RemoveLanguage"):SetEnabled(self._data.default ~= file)
end

function ProjectLocalization:insert_string_item(key, str)
    local strings_pan = self._strings_panel
    local keypan = strings_pan:pan(key, {orig_id = key, background_color = self._menu.background_color:contrast():with_alpha(0.05), align_method = "grid"})
    local opt = {w = keypan:ItemsWidth() / 2 - 15, control_slice = 0.85, offset = 0}
    keypan:textbox("Key", ClassClbk(self, "set_loc_id"), key, opt)
    keypan:textbox("String", ClassClbk(self, "set_loc_value"), str, opt)
    keypan:tb_imgbtn("Remove", ClassClbk(self, "remove_loc"), nil, {97, 1, 30, 30}, {highlight_color = Color.red, position = "RightTopOffset-y", size = 25})
end

function ProjectLocalization:create()
    local path = Path:Combine(self._parent:get_dir(), "loc/english.txt")
    if not FileIO:Exists(path) then
        FileIO:WriteTo(path, "{\n}")
    end
    return {_meta = "Localization", default = "english.txt", directory = "loc"}
end

--- Sets localization ID of the localization string. Callback to the items.
--- @param item Item
function ProjectLocalization:set_loc_id(item)
    local lang = self._current_lang
    local orig_id = item.parent.orig_id
    local new_id = item:Value()
    local val = lang[orig_id]
    if new_id ~= orig_id and lang[new_id] then
        item:SetText("Key[!]")
        item:SetHelp("The key already exists! The localization ID will not be saved.")
    else
        item:SetText("Key")
        item:SetHelp()
        lang[orig_id] = nil
        lang[new_id] = val
        item.parent.orig_id = new_id
    end
end

--- Sets localization value of the localization string. Callback to the items.
--- @param item Item
function ProjectLocalization:set_loc_value(item)
    self._current_lang[item.parent.orig_id] = item:Value()
end

--- Removes a localization ID Callback to the delete button.
--- @param item Item
function ProjectLocalization:remove_loc(item)
    local parent = item.parent
    local lang = self._current_lang
    local orig_id = parent.orig_id
    if lang[orig_id] then
        self._deleted[orig_id] = lang[orig_id]
        lang[orig_id] = nil
    else
        lang[orig_id] = self._deleted[orig_id]
        self._deleted[orig_id] = nil
    end
    parent:GetItem("Key"):SetEnabled(not parent:GetItem("Key"):Enabled())
    parent:GetItem("String"):SetEnabled(not parent:GetItem("String"):Enabled())
end

function ProjectLocalization:save_data()
    local dir = self._parent:get_dir()
    for file in pairs(self._languages_to_delete) do
        FileIO:Delete(Path:Combine(dir, self._dir, file))
    end
    for file, data in pairs(self._languages_to_save) do
        FileIO:WriteScriptData(Path:Combine(dir, self._dir, file), data, "json")
    end
    local loc = true
    while loc do
        loc = XML:GetNode(self._data, "loc")
        table.delete_value(self._data, loc)
    end
    for language, file in pairs(self._languages) do
        table.insert(self._data, {_meta = "loc", language = language, file = file})
    end

    self._languages_to_save = {}
    self._languages_to_delete = {}
    return ProjectLocalization.super.save_data(self)
end
