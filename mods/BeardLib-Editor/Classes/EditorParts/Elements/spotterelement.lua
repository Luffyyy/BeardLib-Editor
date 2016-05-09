EditorSpotter = EditorSpotter or class(MissionScriptEditor)
EditorSpotter.USES_POINT_ORIENTATION = true
EditorSpotter.ON_EXECUTED_ALTERNATIVES = {
	"on_outlined",
	"on_spotted"
}
function EditorSpotter:init(unit)
	EditorSpotter.super.init(self, unit)
end
function EditorSpotter:create_element()
    self.super.create_element(self)
    self._element.class = "ElementSpotter"
end
function EditorSpotter:_build_panel()
	self:_create_panel()
end
