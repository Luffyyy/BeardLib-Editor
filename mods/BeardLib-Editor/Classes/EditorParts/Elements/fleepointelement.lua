EditorFleePoint = EditorFleePoint or class(MissionScriptEditor)
EditorFleePoint.SAVE_UNIT_ROTATION = false
function EditorFleePoint:init(unit)
	EditorFleePoint.super.init(self, unit)
end

function EditorFleePoint:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFleePoint"
    self._element.values.functionality = "flee_point" 
end

function EditorFleePoint:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("functionality", {"flee_point", "loot_drop"}, "Select the functionality of the point")
end
