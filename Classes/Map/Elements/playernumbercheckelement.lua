EditorPlayerNumberCheck = EditorPlayerNumberCheck or class(MissionScriptEditor)
function EditorPlayerNumberCheck:create_element()
	EditorPlayerNumberCheck.super.create_element(self)
	self._element.class = "ElementPlayerNumberCheck"
	self._element.values.num1 = true
	self._element.values.num2 = true
	self._element.values.num3 = true
	self._element.values.num4 = true
end

function EditorPlayerNumberCheck:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("num1", {text = "1 Player"})
	self:BooleanCtrl("num2", {text = "2 Players"})
	self:BooleanCtrl("num3", {text = "3 Players"})
	self:BooleanCtrl("num4", {text = "4 Players"})
	self:Text("The element will only execute if the number of players is set to what you pick.")
end