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
	self._element.values.one_down = true
	self._element.values.player_1 = true
	self._element.values.player_2 = true
	self._element.values.player_3 = true
	self._element.values.player_4 = true
	self._element.values.platform_win32 = true
	self._element.values.mode_assault = true
	self._element.values.mode_control = true
end

function EditorFilter:init(...)
	local unit = EditorFilter.super.init(self, ...)
	self:_check_convertion()

	return unit
end

function EditorFilter:_check_convertion()
	if self._element.values.difficulty_overkill_290 == nil then
		self._element.values.difficulty_overkill_290 = self._element.values.difficulty_overkill_145
	end

	if self._element.values.difficulty_easy_wish == nil then
		self._element.values.difficulty_easy_wish = self._element.values.difficulty_overkill_290
	end

	if self._element.values.difficulty_sm_wish == nil then
		self._element.values.difficulty_sm_wish = self._element.values.difficulty_overkill_290
	end
end

function EditorFilter:_build_panel()
	self:_create_panel()

	local difficulty = self._class_group:group("Difficulty", {align_method = "grid"})
	self:BooleanCtrl("difficulty_easy", {text = "Easy", group = difficulty})
	self:BooleanCtrl("difficulty_normal", {text = "Normal", group = difficulty})
	self:BooleanCtrl("difficulty_hard", {text = "Hard", group = difficulty})
	self:BooleanCtrl("difficulty_overkill", {text = "Very Hard", group = difficulty})
	self:BooleanCtrl("difficulty_overkill_145", {text = "Overkill", group = difficulty})
	self:BooleanCtrl("difficulty_easy_wish", {text = "Mayhem", group = difficulty})
	self:BooleanCtrl("difficulty_overkill_290", {text = "Death Wish", group = difficulty})
	self:BooleanCtrl("difficulty_sm_wish", {text = "Death Sentence", group = difficulty})
	difficulty:separator()
	self:BooleanCtrl("one_down", {text = "One Down", group = difficulty})

	local players = self._class_group:group("Players", {align_method = "grid"}) 
	self:BooleanCtrl("player_1", {text = "One Player", group = players})
	self:BooleanCtrl("player_2", {text = "Two Players", group = players})
	self:BooleanCtrl("player_3", {text = "Three Players", group = players})
	self:BooleanCtrl("player_4", {text = "Four Players", group = players})

	local mode = self._class_group:group("Mode", {align_method = "grid"}) 
	self:BooleanCtrl("mode_control", {text = "Control", group = mode})
	self:BooleanCtrl("mode_assault", {text = "Assault", group = mode})
end
