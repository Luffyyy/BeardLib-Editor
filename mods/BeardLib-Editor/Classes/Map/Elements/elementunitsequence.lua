EditorUnitSequence = EditorUnitSequence or class(MissionScriptEditor)
function EditorUnitSequence:work(...)
	self._draw = {key = "trigger_list", id_key = "notify_unit_id"}
	self:add_draw_units(self._draw)
	EditorUnitSequence.super.work(self, ...)
end

function EditorUnitSequence:create_element()
    self.super.create_element(self)
	self._element.class = "ElementUnitSequence"
	self._element.module = "CoreElementUnitSequence"
	self._element.values.trigger_list = {}
	self._element.values.only_for_local_player = nil
end

function EditorUnitSequence:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("only_for_local_player")
	self:BuildUnitsManage("trigger_list", {
		key = "notify_unit_id", values_name = "Sequence To Trigger", value_key = "notify_unit_sequence", orig = {notify_unit_id = 0, name = "run_sequence", notify_unit_sequence = "", time = 0}, combo_items_func = function(name, value)
			local unit_name = value.unit:name() or ""
			local sequences = table.merge({"interact", "complete", "load"}, managers.sequence:get_editable_state_sequence_list(unit_name), managers.sequence:get_triggable_sequence_list(unit_name))
			return sequences
		end 
	}, self._draw.update_units, {text = "Manage trigger list"})
	self:BuildUnitsManage("trigger_list", {
		key = "notify_unit_id", values_name = "Time To Trigger", value_key = "time", orig = {notify_unit_id = 0, name = "run_sequence", notify_unit_sequence = "", time = 0}
	}, self._draw.update_units, {text = "Manage trigger list / trigger time"})
end