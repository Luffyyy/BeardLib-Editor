EditorSpawnGageAssignment = EditorSpawnGageAssignment or class(MissionScriptEditor)
EditorSpawnGageAssignment.USES_POINT_ORIENTATION = true
function EditorSpawnGageAssignment:create_element()
    self.super.create_element(self)    
    self._element.class = "ElementSpawnGageAssignment"
end