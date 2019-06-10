EditorMissionFilter = EditorMissionFilter or class(MissionScriptEditor)
function EditorMissionFilter:create_element()
    self.super.create_element(self)
	self._element.class = "ElementMissionFilter"  
	for i=1,5 do
		self._element.values[i] = true
	end
end

function EditorMissionFilter:_build_panel()
	self:_create_panel()
	for i=1,5 do
		self._class_group:tickbox(i, ClassClbk(self, "set_element_data"), self._element.values[i], {text = "Mission filter " .. tostring(i)})
	end
end
