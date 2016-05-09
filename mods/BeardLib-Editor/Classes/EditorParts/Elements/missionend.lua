EditorMissionEnd = EditorMissionEnd or class(MissionScriptEditor)
function EditorMissionEnd:init(unit)
	EditorMissionEnd.super.init(self, unit)
end

function EditorMissionEnd:create_element()
    self.super.create_element(self)
	self._element.class = "ElementMissionEnd"
	self._element.values.state = "none"    
end

function EditorMissionEnd:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("state", {
		"none",
		"success",
		"failed",
		"leave_safehouse"
	})
end
