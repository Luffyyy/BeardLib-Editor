EditorRelativeTeleport = EditorRelativeTeleport or class(MissionScriptEditor)
function EditorRelativeTeleport:create_element()
	self.super.create_element(self)
	self._element.class = "ElementRelativeTeleport"
	self._element.values.elements = {}
end

function EditorRelativeTeleport:_build_panel()
	self:_create_panel()

	self:BuildElementsManage("elements", nil, {"ElementRelativeTeleportTarget"})
end
