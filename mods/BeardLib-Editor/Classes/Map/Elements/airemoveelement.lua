EditorAIRemove = EditorAIRemove or class(MissionScriptEditor)
EditorAIRemove.LINK_ELEMENTS = {"elements"}
function EditorAIRemove:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAIRemove"
	self._element.values.elements = {}
	self._element.values.use_instigator = false
	self._element.values.true_death = false
	self._element.values.force_ragdoll = false
end

function EditorAIRemove:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:BooleanCtrl("use_instigator", {text = "Remove Instigator"})
	self:BooleanCtrl("true_death")
	self:BooleanCtrl("force_ragdoll")
end
