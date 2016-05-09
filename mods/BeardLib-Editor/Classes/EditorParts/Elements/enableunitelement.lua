EditorEnableUnit = EditorEnableUnit or class(MissionScriptEditor)
function EditorEnableUnit:init(unit)
	EditorEnableUnit.super.init(self, unit)    
	self._selected_units = {} 
end
 
function EditorEnableUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementEnableUnit"
    self._element.values.unit_ids = {}
end

function EditorEnableUnit:_build_panel()
	self:_create_panel()
	self:_build_unit_list("unit_ids")
end
