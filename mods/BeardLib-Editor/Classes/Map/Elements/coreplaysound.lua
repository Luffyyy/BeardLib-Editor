EditorPlaySound = EditorPlaySound or class(MissionScriptEditor)
function EditorPlaySound:create_element()
	EditorPlaySound.super.create_element(self)
	self._element.class = "ElementPlaySound"
	self._element.values.elements = {}
	self._element.values.append_prefix = false
	self._element.values.use_instigator = false
end
function EditorPlaySound:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"})
	self:StringCtrl("sound_event", {text = "Sound ID"})
	self:BooleanCtrl("append_prefix", {help = "Append unit prefix"})
	self:BooleanCtrl("use_instigator", {help = "Play on instigator"})
end
