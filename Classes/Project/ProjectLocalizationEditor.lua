---Editor for BeardLib Localization module.
---@class ProjectLocalization : ProjectModuleEditor
ProjectLocalization = ProjectLocalization or class(ProjectModuleEditor)
ProjectLocalization.HAS_ID = false
ProjectEditor.EDITORS.Localization = ProjectLocalization

local XML = BeardLib.Utils.XML

--- @param menu Menu
--- @param data table
function ProjectLocalization:build_menu(menu, data)
    self._deleted = {}
    self._languages = {}
    self._languages_to_save = {}
    for _, tbl in ipairs(data) do
        if tbl._meta == "localization" or tbl._meta == "loc" then
            table.insert(self._languages, tbl.file)
        end
    end
    self._dir = data.directory or "loc"
    if #self._languages == 0 and data.default then
        table.insert(self._languages, data.default)
    end
    if #self._languages == 0 then
        data = self:create()
        table.insert(self._languages, data.default)
    end

    local actions = self:pan("Actions", {align_method = "grid"})
    local default = data.default or self._languages[1]
    actions:combobox("Language", ClassClbk(self, "open_lang_clbk"), self._languages, table.get_key(self._languages, default))
    local opt = {w = actions:ItemsWidth() / 3 - actions:OffsetX() * 2, text_align = "center"}
    actions:button("AddString", ClassClbk(self, "insert_string_item", "", ""), opt)
    actions:button("AddLanguage", nil, opt)
    actions:button("RemoveLanguage", nil, opt)
    self._strings_panel = self:pan("Strings", {max_height = self._menu:ItemsHeight() - actions:OuterHeight() - self._menu:OffsetY() - 10})
    self:open_lang(default)
end

function ProjectLocalization:open_lang_clbk(item)
    self:open_lang(item:SelectedItem())
end

function ProjectLocalization:open_lang(file)
    local path = Path:Combine(self._parent:get_dir(), self._dir, file)
    self._current_lang = self._languages_to_save[file] or (FileIO:Exists(path) and FileIO:ReadScriptData(path, "json") or {})
    self._languages_to_save[file] = self._current_lang
    self._strings_panel:ClearItems()
    for key, str in pairs(self._current_lang) do
        self:insert_string_item(key, str)
    end
end

function ProjectLocalization:insert_string_item(key, str)
    local strings_pan = self._strings_panel
    local keypan = strings_pan:pan(key, {orig_id = key, background_color = self._menu.background_color:contrast():with_alpha(0.05), align_method = "grid"})
    local opt = {w = keypan:ItemsWidth() / 2 - 15, control_slice = 0.85, offset = 0}
    keypan:textbox("Key", ClassClbk(self, "set_loc_id"), key, opt)
    keypan:textbox("String", ClassClbk(self, "set_loc_value"), str, opt)
    keypan:tb_imgbtn("Remove", ClassClbk(self, "remove_loc"), nil, {184, 2, 48, 48}, {highlight_color = Color.red, position = "RightCenteryOffset-x", size = 25})
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
    for file, data in pairs(self._languages_to_save) do
        FileIO:WriteScriptData(Path:Combine(self._parent:get_dir(), self._dir, file), data, "json")
    end
end