EditorDifficulty = EditorDifficulty or class(MissionScriptEditor)
function EditorDifficulty:init(unit)
	EditorDifficulty.super.init(self, unit)
end
function EditorDifficulty:create_element()
    self.super.create_element(self)
    self._element.class = "ElementDifficulty"
    self._element.values.difficulty = 0 
end
function EditorDifficulty:_build_panel()
	self:_create_panel()
	self:_build_value_number("difficulty", {min = 0, max = 1}, "Set the current difficulty in level")
	self:add_help_text("Set the current difficulty in the level. Affects what enemies will be spawned etc.")
end
