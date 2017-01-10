EditorVariable = EditorVariable or class(MissionScriptEditor)
function EditorVariable:create_element()
	self.super.create_element(self)
	self._element.class = "ElementVariable"
	self._element.values.elements = {}
	self._element.values.variable = ""
	self._element.values.activated = true
end

function EditorVariable:_build_panel()
	self:_create_panel()
    self:StringCtrl("variable")
	self:BooleanCtrl("activated", {help = "Set if the variable is active and uncheck if the variable is disabled."})
end
