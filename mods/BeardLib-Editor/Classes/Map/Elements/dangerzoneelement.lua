EditorDangerZone = EditorDangerZone or class(MissionScriptEditor)
function EditorDangerZone:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDangerZone"
    self._element.values.level = 1 
end

function EditorDangerZone:_build_panel()
	self:_create_panel()
    self:NumberCtrl("level", {min = 1, max = 4, help = "Sets the level of danger. 1 is least dangerous."})
end
