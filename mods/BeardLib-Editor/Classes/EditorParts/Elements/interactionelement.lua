EditorInteraction = EditorInteraction or class(MissionScriptEditor)
EditorInteraction.ON_EXECUTED_ALTERNATIVES = {
	"interacted",
	"interupt",
	"start"
}
function EditorInteraction:init(unit)
	EditorInteraction.super.init(self, unit)
end

function EditorInteraction:create_element()
	self.super.create_element(self)
	self._element.class = "ElementInteraction"
	self._element.values.tweak_data_id = "none"
	self._element.values.override_timer = -1 
end

function EditorInteraction:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("tweak_data_id", table.list_add({"none"}, table.map_keys(tweak_data.interaction)))
	self:_build_value_number("override_timer", {floats = 1, min = -1}, "Can be used to override the interaction time specified in tweak data. -1 means that it should not override.")
	self:_add_help_text("This element creates an interaction. Override time is optional and will replace tweak data timer (-1 means do not overrride). Use disabled/enabled state on element to set active state on interaction.")
end
