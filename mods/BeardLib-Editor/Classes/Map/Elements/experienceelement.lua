EditorExperience = EditorExperience or class(MissionScriptEditor)
function EditorExperience:create_element()
    self.super.create_element(self)
    self._element.class = "ElementExperience"
    self._element.values.elements = {}
    self._element.values.amount = 0
end

function EditorExperience:_build_panel()
	self:_create_panel()
    self:NumberCtrl("amount", {min = 0, help = "Specify the amount of experience given."})
end
