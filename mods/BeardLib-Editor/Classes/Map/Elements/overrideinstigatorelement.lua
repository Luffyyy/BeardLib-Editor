EditorOverrideInstigator = EditorOverrideInstigator or class(MissionScriptEditor)
function EditorOverrideInstigator:create_element()
    self.super.create_element(self)
    self._element.class = "ElementOverrideInstigator"
end

function EditorOverrideInstigator:_build_panel()
    self:_create_panel()
    self:BuildUnitsManage("unit_id", nil, nil, {text = "Instigator", single_select = true, not_table = true})
end