EditorDisableUnit = EditorDisableUnit or class(MissionScriptEditor)
function EditorDisableUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDisableUnit"
    self._element.values.unit_ids = {}
end

function EditorDisableUnit:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("unit_ids")
end
