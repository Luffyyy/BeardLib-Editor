EditorFilter = EditorFilter or class(MissionScriptEditor)
function EditorFilter:init(unit)
	EditorFilter.super.init(self, unit)
end

function EditorFilter:create_element()
	self.super.create_element(self)
	self._element.class = "ElementFilter"
	self._element.values.difficulty_easy = true
	self._element.values.difficulty_normal = true
	self._element.values.difficulty_hard = true
	self._element.values.difficulty_overkill = true
	self._element.values.difficulty_overkill_145 = true
	self._element.values.difficulty_overkill_290 = nil
	self._element.values.player_1 = true
	self._element.values.player_2 = true
	self._element.values.player_3 = true
	self._element.values.player_4 = true
	self._element.values.platform_win32 = true
	self._element.values.platform_ps3 = true
	self._element.values.mode_assault = true
	self._element.values.mode_control = true 
end

function EditorFilter:post_init(...)
	EditorFilter.super.post_init(self, ...)
	self:_check_convertion()
end
function EditorFilter:_check_convertion()
	if self._element.values.difficulty_overkill_290 == nil then
		self._element.values.difficulty_overkill_290 = self._element.values.difficulty_overkill_145
	end
end
function EditorFilter:_build_panel()
	self:_check_convertion()
	self:_create_panel()

	self:_build_text("Difficulty")
	self:_build_value_checkbox("difficulty_easy", "", "Easy")
	self:_build_value_checkbox("difficulty_normal", "", "Normal")
	self:_build_value_checkbox("difficulty_hard", "", "Hard")
	self:_build_value_checkbox("difficulty_overkill", "", "Very Hard")
	self:_build_value_checkbox("difficulty_overkill_145", "", "Overkill")
	self:_build_value_checkbox("difficulty_overkill_290", "", "Death Wish")

	self:_build_text("Players")
	self:_build_value_checkbox("player_1", "", "One Player")
	self:_build_value_checkbox("player_2", "", "Two Players")
	self:_build_value_checkbox("player_3", "", "Three Players")
	self:_build_value_checkbox("player_4", "", "Four Players")

	self:_build_text("Players")
	self:_build_value_checkbox("mode_control", "", "Control")
	self:_build_value_checkbox("mode_assault", "", "Assault")
end
