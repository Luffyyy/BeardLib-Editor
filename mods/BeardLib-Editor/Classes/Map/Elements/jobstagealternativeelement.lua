EditorJobStageAlternative = EditorJobStageAlternative or class(MissionScriptEditor)
function EditorJobStageAlternative:create_element()
    self.super.create_element(self)
    self._element.class = "ElementJobStageAlternative"
    self._element.values.alternative = 1
    self._element.values.interupt = "none" 
end

function EditorJobStageAlternative:_build_panel()
	self:_create_panel()
    self:NumberCtrl("alternative", {min = 1, help = "Sets the next job stage alternative"})
    self:ComboCtrl("interupt", table.list_add({"none"}, tweak_data.levels.escape_levels), {help = "Select an escape level to be loaded between stages"})
end
