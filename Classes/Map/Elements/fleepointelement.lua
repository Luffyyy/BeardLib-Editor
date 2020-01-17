EditorFleePoint = EditorFleePoint or class(MissionScriptEditor)
function EditorFleePoint:create_element()
    self.super.create_element(self)
    self._element.class = "ElementFleePoint"
    self._element.values.functionality = "flee_point" 
end

function EditorFleePoint:_build_panel()
	self:_create_panel()
    self:ComboCtrl("functionality", {"flee_point", "loot_drop"}, {help = "Select the functionality of the point"})
end
