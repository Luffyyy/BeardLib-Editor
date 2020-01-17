EditorDebug = EditorDebug or class(MissionScriptEditor)
EditorDebug.SAVE_UNIT_POSITION = false
EditorDebug.SAVE_UNIT_ROTATION = false
function EditorDebug:create_element(...)
	EditorDebug.super.create_element(self, ...)
	self._element.class = "ElementDebug"
	self._element.values.debug_string = "none"
	self._element.values.as_subtitle = false
	self._element.values.show_instigator = false
end

function EditorDebug:_build_panel()
	self:_create_panel()
	self:StringCtrl("debug_string")
	self:BooleanCtrl("as_subtitle", {text = "Show as subtitle"})
	self:BooleanCtrl("show_instigator")
end