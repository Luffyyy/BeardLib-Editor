EditorPointOfNoReturn = EditorPointOfNoReturn or class(MissionScriptEditor)
function EditorPointOfNoReturn:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPointOfNoReturn"
	self._element.values.elements = {}
	self._element.values.time_easy = 300
	self._element.values.time_normal = 240
	self._element.values.time_hard = 120
	self._element.values.time_overkill = 60
	self._element.values.time_overkill_145 = 30
	self._element.values.time_easy_wish = nil
	self._element.values.time_overkill_290 = 15
	self._element.values.time_sm_wish = nil
end

function EditorPointOfNoReturn:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementAreaTrigger"})
	self:NumberCtrl("time_normal", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Normal"})
	self:NumberCtrl("time_hard", {floats = 0, min = 1, help = "Set the time left(seconds)", text  = "Hard"})
	self:NumberCtrl("time_overkill", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Very hard"})
	self:NumberCtrl("time_overkill_145", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Overkill"})
	self:NumberCtrl("time_easy_wish", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Mayhem"})
	self:NumberCtrl("time_overkill_290", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "DeathWish"})
	self:NumberCtrl("time_sm_wish", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "One Down"})
end