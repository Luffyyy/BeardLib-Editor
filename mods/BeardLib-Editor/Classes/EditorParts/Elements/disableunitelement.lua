EditorDisableUnit = EditorDisableUnit or class(MissionScriptEditor)
function EditorDisableUnit:init(unit)
	EditorDisableUnit.super.init(self, unit)    
	self._selected_units = {} 
end
 
function EditorDisableUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDisableUnit"
    self._element.values.unit_ids = {}
end

function EditorDisableUnit:_build_panel()
	self:_create_panel()
	self:_build_unit_list("unit_ids")
end
