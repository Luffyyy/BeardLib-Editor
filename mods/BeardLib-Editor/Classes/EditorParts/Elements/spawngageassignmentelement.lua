core:import("CoreEditorUtils")
EditorSpawnGageAssignment = EditorSpawnGageAssignment or class(MissionScriptEditor)
EditorSpawnGageAssignment.USES_POINT_ORIENTATION = true
function EditorSpawnGageAssignment:init(unit)
	EditorSpawnGageAssignment.super.init(self, unit)
end
function EditorSpawnGageAssignment:create_element()
    self.super.create_element(self)    
    self._element.class = "ElementSpawnGageAssignment"
end
function EditorSpawnGageAssignment:_build_panel()
	self:_create_panel()
end
function EditorSpawnGageAssignment:destroy(...)
	EditorSpawnGageAssignment.super.destroy(self, ...)
end
