---Editor for BeardLib AssetUpdates module.
---@class ProjectUpdatesModule : ProjectModuleEditor
ProjectUpdatesModule = ProjectUpdatesModule or class(ProjectModuleEditor)
ProjectUpdatesModule.HAS_ID = false
ProjectEditor.EDITORS.AssetUpdates = ProjectUpdatesModule

local XML = BeardLib.Utils.XML

--- @param menu Menu
--- @param data table
function ProjectUpdatesModule:build_menu(menu, data)
    --[[local mod_assets = XML:GetNode(data, "AssetUpdates") TODO: use for creation
    if not mod_assets then
        mod_assets = {_meta = "AssetUpdates", id = -1, version = 1, provider = "modworkshop", use_local_dir = true}
        data.AssetUpdates = mod_assets
    end]]

    if data.provider == "lastbullet" then
        data.provider = "modworkshop"
    end

    local up = ClassClbk(self, "set_data_callback")
    menu:textbox("Provider", up, data.provider)
    menu:textbox("DownloadId", up, data.id)
    menu:textbox("Version", up, data.version)
    menu:tickbox("Downloadable", up, data.is_standalone ~= false, {
        text = "Downloadable From CrimeNet",
        help = "Can the level be downloaded by clients connecting? this can only work if the level has no extra dependencies"
    })
end

--- The callback function for all items for this menu.
function ProjectUpdatesModule:set_data_callback(item)
    local data = self._data
    data.provider = self:GetItemValue("Provider")
    data.id = self:GetItemValue("DownloadId")
    data.version = self:GetItemValue("Version")
    data.is_standalone = self:GetItemValue("Downloadable")
    if data.is_standalone == true then
        data.is_standalone = nil
    end
end