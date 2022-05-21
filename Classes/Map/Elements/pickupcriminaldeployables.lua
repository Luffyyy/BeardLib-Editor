EditorPickupCriminalDeployables = EditorPickupCriminalDeployables or class(MissionScriptEditor)
function EditorPickupCriminalDeployables:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPickupCriminalDeployables"   
end

function EditorPickupCriminalDeployables:_build_panel()
	self:_create_panel()
	self:Info("Picks up every player placed sentry gun equipment on the map and gives them back to their owners.")
end
