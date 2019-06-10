EditorToggle = EditorToggle or class(MissionScriptEditor)
function EditorToggle:create_element()
	self.super.create_element(self)
	self._element.class = "ElementToggle"
	self._element.values.toggle = "on"
	self._element.values.set_trigger_times = -1
	self._element.values.elements = {}
end

function EditorToggle:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements")
	self:ComboCtrl("toggle", {"on","off","toggle"}, {help = "Select how you want to toggle an element"})
	self:NumberCtrl("set_trigger_times", {floats = 0, min = -1, help = "Sets the elements trigger times when toggle on (-1 means do not use)"})
end

