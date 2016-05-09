EditorAreaMinPoliceForce = EditorAreaMinPoliceForce or class(MissionScriptEditor)
function EditorAreaMinPoliceForce:init(unit)
	EditorAreaMinPoliceForce.super.init(self, unit)
end
function EditorAreaMinPoliceForce:create_element()
    self.super.create_element(self)
    self._element.class = "ElementAreaMinPoliceForce"
    self._element.values.amount = 1 
end
function EditorAreaMinPoliceForce:_build_panel()
	self:_create_panel()
	self:_build_value_number("amount", {min = 0}, "Set amount of enemy forces in area. Use 0 to define dynamic spawn area for \"street\" GroupAI.")
end
