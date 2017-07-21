EditorSpecialObjectiveTrigger = EditorSpecialObjectiveTrigger or class(MissionScriptEditor)
EditorSpecialObjectiveTrigger._options = {
	"anim_act_01",
	"anim_act_02",
	"anim_act_03",
	"anim_act_04",
	"anim_act_05",
	"anim_act_06",
	"anim_act_07",
	"anim_act_08",
	"anim_act_09",
	"anim_act_10",
	"administered",
	"admin_fail",
	"anim_start",
	"complete",
	"fail"
}

function EditorSpecialObjectiveTrigger:create_element()
	self.super.create_element(self)	
	self._element.class = "ElementSpecialObjectiveTrigger"
	self._element.values.event = self._options[1]
	self._element.values.elements = {}	
end

function EditorSpecialObjectiveTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementSpecialObjective","ElementSpecialObjectiveGroup"})
	self:ComboCtrl("event", self._options, {help = "Select an event from the combobox"})
end
