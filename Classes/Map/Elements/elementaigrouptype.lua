EditorAIGroupType = EditorAIGroupType or class(MissionScriptEditor)
function EditorAIGroupType:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAIGroupType"
	self._element.values.ai_group_type = "default"
end

function EditorAIGroupType:_build_panel()
	self:_create_panel()

	local options = {"default"}
	for key, value in pairs(tweak_data.levels.LevelType) do
		table.insert(options, value)
	end

	self:ComboCtrl("ai_group_type", options, {help = "Select the ai group type to switch to."})
end
