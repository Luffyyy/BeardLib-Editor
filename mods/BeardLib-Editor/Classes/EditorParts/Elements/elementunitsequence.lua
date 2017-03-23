EditorUnitSequence = EditorUnitSequence or class(MissionScriptEditor)
function EditorUnitSequence:create_element()
    self.super.create_element(self)
	self._element.class = "ElementUnitSequence"
	self._element.module = "CoreElementUnitSequence"
	self._element.values.trigger_list = {}
	self._element.values.only_for_local_player = nil
end

function EditorUnitSequence:select_unit_trigger_list(id, params) 
	table.insert(self._selected_units, {
		name = "run_sequence", 
		id = #self._selected_units + 1, 
		notify_unit_id = id,
		time = 0,
		notify_unit_sequence = "" 
	}) 
	self:load_all_units(params)
end

function EditorUnitSequence:apply_units(value_name)
	self.super.apply_units(self, value_name)
	self:update_selected_sequence()
end

function EditorUnitSequence:set_selected_trigger_sequence(menu, item)
	self._element.values.trigger_list[self._menu:GetItem("trigger_list"):Value()].notify_unit_sequence = item:SelectedItem()
	self:update_element()
end

function EditorUnitSequence:update_selected_sequence()
	local combo_trigger_list = {}
	local trigger_list = {}
	local selected_sequence = self._menu:GetItem("selected_trigger")
	local sequence_combo = self._menu:GetItem("trigger_list")
	for _, trigger_unit in pairs(self._element.values.trigger_list) do
		local unit = managers.worlddefinition:get_unit_on_load(trigger_unit.notify_unit_id)  
		if alive(unit) then		
			table.insert(combo_trigger_list, unit:unit_data().name_id .. "[" .. trigger_unit.notify_unit_id .. "]")
			table.insert(trigger_list, trigger_unit.notify_unit_id)
		end
	end		
	if #sequence_combo.items ~= #combo_trigger_list then
		sequence_combo:SetValue(1)
	end
	sequence_combo:SetItems(combo_trigger_list)
	if #trigger_list > 0 and sequence_combo:SelectedItem() then
		local unit = managers.worlddefinition:get_unit_on_load(trigger_list[sequence_combo.value])   
		if alive(unit) then
			local sequences = managers.sequence:get_editable_state_sequence_list(unit:name() or "")
			table.insert(sequences, "interact")			
			selected_sequence:SetItems(sequences)
			local trigger_list_unit = self._element.values.trigger_list[sequence_combo.value]
			selected_sequence:SetValue(table.get_key(sequences, trigger_list_unit.notify_unit_sequence))
		end
	else
		selected_sequence:SetItems()
	end
end

function EditorUnitSequence:apply_modify_trigger_unit(i, items)
	self._element.values.trigger_list[i].name = items[1].value
	self._element.values.trigger_list[i].notify_unit_sequence = items[2]:SelectedItem()
	self._element.values.trigger_list[i].time = tonumber(items[3].value)
	self:update_selected_sequence()
end

function EditorUnitSequence:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("only_for_local_player")
	local trigger_list = {}
	for _, unit in pairs(self._element.values.trigger_list) do
		table.insert(trigger_list, unit.notify_unit_id)
	end
	self._menu:ComboBox({	
		name = "trigger_list",
		text = "Trigger List",
		help = "Select a unit to modify",
		group = self._class_group,
		callback = callback(self, self, "update_selected_sequence"),
		items = trigger_list,
	})	
	self._menu:ComboBox({
		name = "selected_trigger",
		text = "Trigger Sequence",
		help = "Select a sequence for the unit",
		group = self._class_group,
		callback = callback(self, self, "set_selected_trigger_sequence"),
		items = {},
	})		  	
	self:NumberCtrl("time", {floats = 0, min = 0}) 
	self:BuildUnitsManage("trigger_list", {key = "notify_unit_id", orig = {notify_unit_id = 0, id = 1, name = "run_sequence", notify_unit_sequence = "", time = 0}}, callback(self, self, "update_selected_sequence"))
	self:update_selected_sequence()
end
