EditorFilter = EditorFilter or class(MissionScriptEditor)
function EditorFilter:create_element()
	self.super.create_element(self)
	self._element.class = "ElementFilter"
	self._element.values.difficulty_easy = true
	self._element.values.difficulty_normal = true
	self._element.values.difficulty_hard = true
	self._element.values.difficulty_overkill = true
	self._element.values.difficulty_overkill_145 = true
	self._element.values.difficulty_easy_wish = true
	self._element.values.difficulty_overkill_290 = true
	self._element.values.difficulty_sm_wish = true
	self._element.values.player_1 = true
	self._element.values.player_2 = true
	self._element.values.player_3 = true
	self._element.values.player_4 = true
	self._element.values.platform_win32 = true
	self._element.values.mode_assault = true
	self._element.values.mode_control = true
end

function EditorFilter:_build_panel()
	self:_create_panel()
	self:Text("Difficulty")
	self:BooleanCtrl("difficulty_easy", {text = "Easy"})
	self:BooleanCtrl("difficulty_normal", {text = "Normal"})
	self:BooleanCtrl("difficulty_hard", {text = "Hard"})
	self:BooleanCtrl("difficulty_overkill", {text = "Very Hard"})
	self:BooleanCtrl("difficulty_overkill_145", {text = "Overkill"})
	self:BooleanCtrl("difficulty_easy_wish", {text = "Mayhem"})
	self:BooleanCtrl("difficulty_overkill_290", {text = "Death Wish"})
	self:BooleanCtrl("difficulty_sm_wish", {text = "One Down"})
	self:Text("Players")    
	self:BooleanCtrl("player_1", {text = "One Player"})
	self:BooleanCtrl("player_2", {text = "Two Players"})
	self:BooleanCtrl("player_3", {text = "Three Players"})
	self:BooleanCtrl("player_4", {text = "Four Players"})
	self:Text("Mode")   
	self:BooleanCtrl("mode_control", {text = "Control"})
	self:BooleanCtrl("mode_assault", {text = "Assault"})
end
