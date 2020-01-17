EditorDifficulty = EditorDifficulty or class(MissionScriptEditor)
function EditorDifficulty:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDifficulty"
    self._element.values.difficulty = 0 
end

function EditorDifficulty:_build_panel()
	self:_create_panel()
	self:NumberCtrl("difficulty", {min = 0, max = 1, help = "Set the current difficulty in level"})
	self:Text("Set the current difficulty in the level. Affects what enemies will be spawned etc.")
end
