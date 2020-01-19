---Editor for BeardLib narrative module.
---@class ProjectNarrativeEditor : ProjectModuleEditor
ProjectNarrativeEditor = ProjectNarrativeEditor or class(ProjectModuleEditor)
ProjectEditor.EDITORS.narrative = ProjectNarrativeEditor

--- @param parent ProjectEditor
function ProjectNarrativeEditor:build_menu(menu, data)
    menu:textbox("NarrName", up, data.id)
end

--- The callback function for all items for this menu.
function ProjectNarrativeEditor:set_data_callback()
    local data = self._data
    data.name = self:GetItemValue("NarrName")
end