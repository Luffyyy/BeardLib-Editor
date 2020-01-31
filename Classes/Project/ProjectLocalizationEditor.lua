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
    self._current_lang = FileIO:ReadScriptData(Path:Combine(self._parent:get_dir(), "loc/english.txt"), "json")
    self:button("Add", ClassClbk(self, "insert_string_item", "", ""))
    self._strings_panel = self:pan("Strings")
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
    FileIO:WriteTo(Path:Combine(self._parent:get_dir(), "loc/english.txt"), "{\n}")
    return {_meta = "Localization", default = "english.txt", directory = "loc"}
end

--- Sets localization ID of the localization string. Callback to the items.
--- @param item Item
function ProjectLocalization:set_loc_id(item)
    local lang = self._current_lang
    local orig_id = item.parent.orig_id
    local new_id = item:Value()
    local val = lang[orig_id]
    lang[orig_id] = nil
    lang[new_id] = val
    item.parent.orig_id = new_id
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

--- The callback function for all items for this menu.
function ProjectLocalization:set_data_callback(item)
    local data = self._data
end

function ProjectLocalization:save_data()
    FileIO:WriteScriptData(Path:Combine(self._parent:get_dir(), "loc/english.txt"), self._current_lang, "json")
end