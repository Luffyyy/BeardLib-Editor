EditorTeleportPlayer = EditorTeleportPlayer or class(MissionScriptEditor)
function EditorTeleportPlayer:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTeleportPlayer"
	self._element.values.use_instigator = true
end

function EditorTeleportPlayer:build_panel()
	self:_create_panel()
	self:BooleanCtrl("use_instigator")
end