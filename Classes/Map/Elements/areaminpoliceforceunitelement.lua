EditorAreaMinPoliceForce = EditorAreaMinPoliceForce or class(MissionScriptEditor)
function EditorAreaMinPoliceForce:create_element()
	EditorAreaMinPoliceForce.super.create_element(self)
	self._element.class = "ElementAreaMinPoliceForce"
	self._element.values.amount = 1
end

function EditorAreaMinPoliceForce:_build_panel()
	self:_create_panel()
	self:NumberCtrl("amount", {floats = 0, min = 0, help = "Set amount of enemy forces in area. Use 0 to define dynamic spawn area for \"street\" GroupAI."})
end
