EditorExperience = EditorExperience or class(MissionScriptEditor)
EditorExperience.SAVE_UNIT_POSITION = false
EditorExperience.SAVE_UNIT_ROTATION = false
function EditorExperience:init(unit)
	MissionScriptEditor.init(self, unit)
end
function EditorExperience:create_element()
    self.super.create_element(self)
    self._element.class = "ElementExperience"
    self._element.values.elements = {}
    self._element.values.amount = 0
end
function EditorExperience:_build_panel()
	self:_create_panel()
	self:_build_value_number("amount", {min = 0}, "Specify the amount of experience given.")
end
