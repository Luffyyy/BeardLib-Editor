EditorMissionEnd = EditorMissionEnd or class(MissionScriptEditor)
function EditorMissionEnd:create_element()
    self.super.create_element(self)
	self._element.class = "ElementMissionEnd"
	self._element.values.state = "none"    
end

function EditorMissionEnd:_build_panel()
	self:_create_panel()
	self:ComboCtrl("state", {
		"none",
		"success",
		"failed",
		"leave_safehouse"
	})
end
