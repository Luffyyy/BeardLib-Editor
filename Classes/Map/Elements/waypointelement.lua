EditorWaypoint = EditorWaypoint or class(MissionScriptEditor)
EditorWaypoint._icon_options = {
	"pd2_lootdrop",
	"pd2_escape",
	"pd2_talk",
	"pd2_kill",
	"pd2_drill",
	"pd2_generic_look",
	"pd2_phone",
	"pd2_c4",
	"pd2_power",
	"pd2_door",
	"pd2_computer",
	"pd2_wirecutter",
	"pd2_fire",
	"pd2_loot",
	"pd2_methlab",
	"pd2_generic_interact",
	"pd2_goto",
	"pd2_ladder",
	"pd2_fix",
	"pd2_question",
	"pd2_defend",
	"pd2_generic_saw",
	"pd2_chainsaw",
	"pd2_car",
	"pd2_melee",
	"pd2_water_tap"
}

function EditorWaypoint:create_element()
	self.super.create_element(self)
	self._element.class = "ElementWaypoint"	
	self._element.values.icon = "pd2_goto"
	self._element.values.text_id = "debug_none"
	self._element.values.only_in_civilian = false	
end

function EditorWaypoint:set_element_data(params, ...)
	EditorWaypoint.super.set_element_data(self, params, ...)
	if params.value == "text_id" then
		self:_set_text()
	end
end

function EditorWaypoint:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("only_in_civilian", {help = "This waypoint will only be visible for players that are in civilian mode"})
	self:ComboCtrl("icon", self._icon_options, {help = "Select an icon"})
	self:StringCtrl("text_id")
end