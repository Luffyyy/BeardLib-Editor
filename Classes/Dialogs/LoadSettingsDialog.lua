LoadSettingsDialog = LoadSettingsDialog or class(MenuDialog)
LoadSettingsDialog.type_name = "LoadSettingsDialog"
function LoadSettingsDialog:_Show(params)
    local p = table.merge({title = "Asset Load Options", yes = false, w = 500}, params)
    if not self.super._Show(self, p) then
        return
    end

    self._utils = params.utils
    local settings = self._utils._load_settings
    local exclude = settings.exclude or {
        network_unit = false,
        animation = true,
        bnk = false,
        texture = true,
        model = true,
        cooked_physics = true,
        animation_subset = false,
        animation_states = false,
        animation_state_machine = false,
        animation_def = false
    }

    ItemExt:add_funcs(self, self._menu:pan({name = "holder", index = 3, auto_height = true}))

    local semi_opt = {help = "Semi optional asset, some assets don't need it and some do, better keep it on.", size_by_text = true}
    local opt = {help = "Optional asset, the game can load it by itself.", size_by_text = true}

    --TODO: Implement these
    --self:tickbox("LoadWithPackages", nil, settings.load_with_packages or false, {
    --    help = "Opens a dialog to pick a package in order to load the unit instead of loading it from the database"
    --})
    --self:separator()
    self:tickbox("LoadBaseAssets", nil, settings.base_assets or false, {
        text = "Allow Loading Base Assets", 
        help = "Load assets even if they are part of the always loaded base packages (Loading enemies and certain other base assets can cause incompatibilities with some mods)"
    })

    --self:tickbox("IncludeFilesInProject", nil, settings.include_in_project or false, {
    --    help = "Should the assets imported be included in the project? This is useful if you need to edit the assets"
    --})

    self:divider("Include:", {border_left = false, border_bottom = true})
    local include = self:holder("Include", {align_method = "grid"})
    include:tickbox("NetworkUnits", nil, not exclude.network_unit, {size_by_text = true})
    include:tickbox("Animations", nil, not exclude.animation, semi_opt)
    include:tickbox("SoundBanks", nil, not exclude.bnk, semi_opt)
    include:tickbox("Textures", nil, not exclude.texture, opt)
    include:tickbox("Models", nil, not exclude.model, opt)
    include:tickbox("CookedPhysics", nil, not exclude.cooked_physics, opt)
    include:separator()
    include:tickbox("AnimationSubsets", nil, not exclude.animation_subset, semi_opt)
    include:tickbox("AnimationStates", nil, not exclude.animation_states, semi_opt)
    include:tickbox("AnimationStateMachines", nil, not exclude.animation_state_machine, semi_opt)
    include:tickbox("AnimationDefinitions", nil,not exclude.animation_def, semi_opt)

    self:button("Save", ClassClbk(self, "hide", true))
    self:button("Cancel", ClassClbk(self, "hide", false))
end

function LoadSettingsDialog:hide(success)
    if success then
        self._utils._load_settings = {
            --load_with_packages = self:GetItem("LoadWithPackages"):Value(),
            base_assets = self:GetItem("LoadBaseAssets"):Value(),
            --include_in_project = self:GetItem("IncludeFilesInProject"):Value(),
            exclude = {
                animation = not self:GetItem("Animations"):Value(),
                animation_subset = not self:GetItem("AnimationSubsets"):Value(),
                animation_def = not self:GetItem("AnimationDefinitions"):Value(),
                animation_states = not self:GetItem("AnimationStates"):Value(),
                animation_state_machine = not self:GetItem("AnimationStateMachines"):Value(),
                bnk = not self:GetItem("SoundBanks"):Value(),
                texture = not self:GetItem("Textures"):Value(),
                model = not self:GetItem("Models"):Value(),
                cooked_physics = not self:GetItem("CookedPhysics"):Value(),
                network_unit = not self:GetItem("NetworkUnits"):Value()
            }
        }
        BLE.Options:SetValue("Map/AssetLoadSettings", self._utils._load_settings)
        BLE.Options:Save()
    end
    return LoadSettingsDialog.super.hide(self, success)
end