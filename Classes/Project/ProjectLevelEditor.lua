---Editor for BeardLib level module.
---@class ProjectLevelEditor : ProjectModuleEditor
ProjectLevelEditor = ProjectLevelEditor or class(ProjectModuleEditor)
ProjectEditor.EDITORS.level = ProjectLevelEditor

--- @param menu Menu
--- @param data table
function ProjectLevelEditor:build_menu(menu, data)
    menu:textbox("LevelName", up, data.id)
end

--- The callback function for all items for this menu.
function ProjectLevelEditor:set_data_callback()
    local data = self._data
    data.id = self:GetItemValue("LevelName")
end