ExportDialog = ExportDialog or class(MenuDialog)
ExportDialog.type_name = "ExportDialog"
function ExportDialog:_Show(params)
    local p = table.merge({title = "Export a unit", yes = "Export", no = "Close", w = 600}, params)
    if not self.super._Show(self, p) then
        return
    end
    self._assets = params.assets
    self._assets_manager = params.assets_manager
    ItemExt:add_funcs(self, self._menu:pan({name = "holder", index = 3, auto_height = true}))

    local semi_opt = {help = "Semi optional asset, some units don't need it and some do, better keep it on."}
    local opt = {help = "Optional asset, the game can load it by itself."}

    self._clbk = params.done_clbk

    self:divider("Include:")
    self:tickbox("NetworkUnits", nil, true)
    self:tickbox("Animations", nil, true, semi_opt)
    self:tickbox("SoundBanks", nil, true, semi_opt)
    self:tickbox("Textures", nil, false, opt)
    self:tickbox("Models", nil, false, opt)
    self:tickbox("CookedPhysics", nil, false, opt)
end

function ExportDialog:hide(success)
    if success then
        self._assets_manager:load_from_extract(self._assets, {
            animation = not self:GetItem("Animations"):Value(),
            bnk = not self:GetItem("SoundBanks"):Value(),
            texture = not self:GetItem("Textures"):Value(),
            model = not self:GetItem("Models"):Value(),
            cooked_physics = not self:GetItem("CookedPhysics"):Value(),
            network_unit = not self:GetItem("NetworkUnits"):Value()
        }, true, self._clbk)
    end
    return ExportDialog.super.hide(self, success)
end