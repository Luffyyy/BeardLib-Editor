EditorEnableUnit = EditorEnableUnit or class(MissionScriptEditor)
function EditorEnableUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementEnableUnit"
    self._element.values.unit_ids = {}
end

function EditorEnableUnit:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("unit_ids")
end
