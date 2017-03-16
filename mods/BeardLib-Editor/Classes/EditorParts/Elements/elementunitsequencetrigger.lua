EditorUnitSequenceTrigger = EditorUnitSequenceTrigger or class(MissionScriptEditor)
function EditorUnitSequenceTrigger:create_element()
    self.super.create_element(self)
	self._element.class = "ElementUnitSequenceTrigger"
	self._element.module = "CoreElementUnitSequenceTrigger"
	self._element.values.trigger_times = 1
	self._element.values.sequence_list = {}
end

function EditorUnitSequenceTrigger:set_selected_sequence(menu, item)
	self._element.values.sequence_list[self._menu:GetItem("sequence"):Value()].sequence = item:SelectedItem()
end

function EditorUnitSequenceTrigger:apply_units(value_name)
	self.super.apply_units(self, value_name)
	self:update_selected_sequence()
end

function EditorUnitSequenceTrigger:add_selected_units(value_name)
	for _, unit in pairs(self:Manager("static")._selected_units) do
		if unit:unit_data() then
			table.insert(self._element.values[value_name], {
				guis_id = #self._element.values[value_name] + 1,
				sequence = "",
				unit_id = unit:unit_data().unit_id,
			}) 			
		end
	end
	self:update_selected_sequence()
end

function EditorUnitSequenceTrigger:remove_selected_units(value_name)
	for _, unit in pairs(self:Manager("static")._selected_units) do
		if unit:unit_data() then
			for k, sequence_unit in pairs(self._element.values[value_name]) do 
				if sequence_unit.unit_id == unit:unit_data().unit_id then
					table.remove(self._element.values[value_name], k)
				end
			end
		end
	end
	self:update_selected_sequence()
end

function EditorUnitSequenceTrigger:update_selected_sequence()
	local combo_sequence_list = {}
	local sequence_list = {}
	local sequence_combo = self._menu:GetItem("sequence")	
	local selected_sequence = self._menu:GetItem("selected_sequence")
	for _, sequence_unit in pairs(self._element.values.sequence_list) do
		local unit = managers.worlddefinition:get_unit_on_load(sequence_unit.unit_id)  
		if alive(unit) then		
			table.insert(combo_sequence_list, unit:unit_data().name_id .. "[" .. sequence_unit.unit_id .. "]")
			table.insert(sequence_list, sequence_unit.unit_id)
		end
	end		
	if #sequence_combo.items ~= #combo_sequence_list then
		sequence_combo:SetValue(1)
	end
	sequence_combo:SetItems(combo_sequence_list)
	if #sequence_list > 0 and sequence_combo:SelectedItem() then
		local unit = managers.worlddefinition:get_unit_on_load(sequence_list[sequence_combo.value])   
		if alive(unit) then
			local sequences = managers.sequence:get_editable_state_sequence_list(unit:name() or "")
			table.insert(sequences, "interact")
			selected_sequence:SetItems(sequences)
			local sequence_list_unit = self._element.values.sequence_list[sequence_combo.value]
			selected_sequence:SetValue(table.get_key(sequences, sequence_list_unit.sequence))
		end
	else
		selected_sequence:SetItems()
	end

end

function EditorUnitSequenceTrigger:_build_panel()
	self:_create_panel()
	self._menu:ComboBox({
		name = "sequence",
		text = "Sequence Unit",
		help = "Select a sequence unit to modify",
		group = self._class_group,
		callback = callback(self, self, "update_selected_sequence"),
		value = 1,
		items = {},
	})	
	self._menu:ComboBox({
		name = "selected_sequence",
		text = "Sequence",
		help = "Select a sequence for the unit",
		group = self._class_group,
		callback = callback(self, self, "set_selected_sequence"),
		items = {},
	})		 
	self:BuildUnitsManage("sequence_list", {key = "unit_id", orig = {unit_id = 0, sequence = "", guis_id = 1}}, callback(self, self, "update_selected_sequence"))
	self:update_selected_sequence()
end
 