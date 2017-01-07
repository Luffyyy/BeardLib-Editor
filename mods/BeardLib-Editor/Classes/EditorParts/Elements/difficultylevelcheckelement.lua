EditorDifficultyLevelCheck = EditorDifficultyLevelCheck or class(MissionScriptEditor)
function EditorDifficultyLevelCheck:create_element()
	self.super.create_element(self)
 	self._element.class = "ElementDifficultyLevelCheck"
	self._element.values.difficulty = "easy"
end

function EditorDifficultyLevelCheck:_build_panel()
	self:_create_panel()
	local difficulty_params = {
		name = "Difficulty:",
		panel = panel,
		sizer = panel_sizer,
		default = "easy",
		options = {
			"normal",
			"hard",
			"overkill"
		},
		value = self._element.values.difficulty,
		tooltip = "Select a difficulty",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	self:ComboCtrl("difficulty", {"normal", "hard", "overkill"}, {help = "Select a difficulty"})
	self:Text("The element will only execute if the difficulty level is set to what you pick.")
end
