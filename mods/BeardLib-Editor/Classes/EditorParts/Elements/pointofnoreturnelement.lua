EditorPointOfNoReturn = EditorPointOfNoReturn or class(MissionScriptEditor)
function EditorPointOfNoReturn:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPointOfNoReturn"
	self._element.values.time_easy = 300
	self._element.values.time_normal = 240
	self._element.values.time_hard = 120
	self._element.values.time_overkill = 60
	self._element.values.time_overkill_145 = 30
	self._element.values.time_overkill_290 = 15
end
function EditorPointOfNoReturn:_build_panel()
	self:_create_panel()
	self:_build_value_number("time_normal", {floats = 0, min = 1}, "Set the time left(seconds)", nil ,"Normal:")
	self:_build_value_number("time_hard", {floats = 0, min = 1}, "Set the time left(seconds)", nil ,"Hard:")
	self:_build_value_number("time_overkill", {floats = 0, min = 1}, "Set the time left(seconds)", nil ,"Very hard:")
	self:_build_value_number("time_overkill_145", {floats = 0, min = 1}, "Set the time left(seconds)", nil ,"Overkill")
	self:_build_value_number("time_overkill_290", {floats = 0, min = 1}, "Set the time left(seconds)", nil ,"Deathwish:")
end
