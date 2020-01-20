---Editor for BeardLib AssetUpdates module.
---@class ProjectUpdatesModule : ProjectModuleEditor
ProjectUpdatesModule = ProjectUpdatesModule or class(ProjectModuleEditor)
ProjectUpdatesModule.HAS_ID = false
ProjectEditor.EDITORS.AssetUpdates = ProjectUpdatesModule

local XML = BeardLib.Utils.XML

--- @param menu Menu
--- @param data table
function ProjectUpdatesModule:build_menu(menu, data)
    local updating = menu:divgroup("Updating", {border_position_below_title = true, private = {size = 22}})
    --[[local mod_assets = XML:GetNode(data, "AssetUpdates") TODO: use for creation
    if not mod_assets then
        mod_assets = {_meta = "AssetUpdates", id = -1, version = 1, provider = "modworkshop", use_local_dir = true}
        data.AssetUpdates = mod_assets
    end]]

    if data.provider == "lastbullet" then
        data.provider = "modworkshop"
    end

    updating:textbox("Provider", up, data.provider)
    updating:numberbox("DownloadId", up, data.id, {floats = 0})
    updating:textbox("Version", up, data.version)
    updating:tickbox("Downloadable", up, data.is_standalone ~= false, {
        text = "Downloadable From CrimeNet",
        help = "Can the level be downloaded by clients connecting? this can only work if the level has no extra dependencies"
    })
end

--- The callback function for all items for this menu.
function ProjectUpdatesModule:set_data_callback(item)
    local data = self._data
    local menu = item.menu
    data.provider = menu:GetItemValue("Provider")
    data.id = menu:GetItemValue("id")
    data.version = menu:GetItemValue("version")
    data.is_standalone = menu:GetItemValue("Downloadable")
end