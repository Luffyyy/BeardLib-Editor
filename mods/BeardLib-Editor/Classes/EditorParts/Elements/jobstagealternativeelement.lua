EditorJobStageAlternative = EditorJobStageAlternative or class(MissionScriptEditor)
EditorJobStageAlternative.SAVE_UNIT_POSITION = false
EditorJobStageAlternative.SAVE_UNIT_ROTATION = false
function EditorJobStageAlternative:init(unit)
	EditorJobStageAlternative.super.init(self, unit)
end

function EditorJobStageAlternative:create_element()
    self.super.create_element(self)
    self._element.class = "ElementJobStageAlternative"
    self._element.values.alternative = 1
    self._element.values.interupt = "none" 
end

function EditorJobStageAlternative:_build_panel()
	self:_create_panel()
	self:_build_value_number("alternative", {min = 1}, "Sets the next job stage alternative")
	self:_build_value_combobox("interupt", table.list_add({"none"}, tweak_data.levels.escape_levels), "Select an escape level to be loaded between stages")
end
