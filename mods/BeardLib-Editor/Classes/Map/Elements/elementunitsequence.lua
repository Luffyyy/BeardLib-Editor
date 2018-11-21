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

function EditorUnitSequence:update_selected(...)
    self:verify_trigger_units()
    self:_draw_trigger_units(0, 1, 1)
end

function EditorUnitSequence:verify_trigger_units()
    for i = #self._element.values.trigger_list, 1, -1 do
        local unit = managers.worlddefinition:get_unit(self._element.values.trigger_list[i].notify_unit)

        if not alive(unit) then
            table.remove(self._element.values.trigger_list, i)
        end
    end
end

function EditorUnitSequence:_draw_trigger_units(r, g, b)
    for _, unit in ipairs(self:_get_sequence_units()) do
        local params = {
            from_unit = self._unit,
            to_unit = unit,
            r = r,
            g = g,
            b = b
        }

        self:draw_link(params)
        Application:draw(unit, r, g, b)
    end
end

function EditorUnitSequence:_get_sequence_units()
	local units = {}
	local triggers = managers.sequence:get_trigger_list(self._unit:name())
	
	if #triggers <= 0 then
		return {}
	end
	
	local trigger_name_list = self._unit:damage():get_trigger_name_list()
    if trigger_name_list then
        for _, trigger_name in ipairs(trigger_name_list) do
            local trigger_data = self._unit:damage():get_trigger_data_list(trigger_name)

            if trigger_data and #trigger_data > 0 then
                for _, data in ipairs(trigger_data) do
                    if alive(data.notify_unit) then
                        table.insert(units, data.notify_unit)
                    end
                end
            end
        end
    end

    return units
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