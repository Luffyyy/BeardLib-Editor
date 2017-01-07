EditorAssetTrigger = EditorAssetTrigger or class(MissionScriptEditor)
function EditorAssetTrigger:create_element()
    self.super.create_element(self)
    self._element.class = "ElementAssetTrigger"
    self._element.values.trigger_times = 1
    self._element.values.id = managers.assets:get_default_asset_id()    
end
function EditorAssetTrigger:_build_panel()
	self:_create_panel()
    self:ComboCtrl("id", managers.assets:get_every_asset_ids(), {help = "Select an asset id from the combobox"})
end
