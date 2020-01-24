---Editor for BeardLib Localization module.
---@class ProjectLocalization : ProjectModuleEditor
ProjectLocalization = ProjectLocalization or class(ProjectModuleEditor)
ProjectLocalization.HAS_ID = false
ProjectEditor.EDITORS.Localization = ProjectLocalization

local XML = BeardLib.Utils.XML

--- @param menu Menu
--- @param data table
function ProjectLocalization:build_menu(menu, data)

end

function ProjectLocalization:create()
    FileIO:WriteTo(Path:Combine(self._parent:get_dir(), "loc/english.txt"), "{\n}")
    return {_meta = "Localization", default = "english.txt", directory = "loc"}
end

--- The callback function for all items for this menu.
function ProjectLocalization:set_data_callback(item)
    local data = self._data

end