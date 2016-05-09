EditorDangerZone = EditorDangerZone or class(MissionScriptEditor)
function EditorDangerZone:init(unit)
	EditorDangerZone.super.init(self, unit)
end
function EditorDangerZone:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDangerZone"
    self._element.values.level = 1 
end
function EditorDangerZone:_build_panel()
	self:_create_panel()
	self:_build_value_number("level", {min = 1, max = 4}, "Sets the level of danger. 1 is least dangerous.")
end
