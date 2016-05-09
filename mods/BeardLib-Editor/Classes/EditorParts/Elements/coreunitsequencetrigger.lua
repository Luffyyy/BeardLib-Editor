EditorUnitSequenceTrigger = EditorUnitSequenceTrigger or class(MissionScriptEditor)
EditorUnitSequenceTrigger.SAVE_UNIT_POSITION = false
EditorUnitSequenceTrigger.SAVE_UNIT_ROTATION = false
function EditorUnitSequenceTrigger:init(unit)
	self.super.init(self, unit)
end
function EditorUnitSequenceTrigger:create_element()
    self.super.create_element(self)
	self._element.class = "ElementUnitSequenceTrigger"
	self._element.values.trigger_times = 1
	self._element.values.sequence_list = {}
end
function EditorUnitSequenceTrigger:select_unit_sequence_list(id, params) 
	table.insert(self._selected_units, {
		guis_id = #self._selected_units + 1,
		sequence = "",
		unit_id = id,
	}) 
	self:load_all_units(params)
end
function EditorUnitSequenceTrigger:apply_units(value_name)
	self.super.apply_units(self, value_name)
	self:reload_sequence_list_combo()
end
function EditorUnitSequenceTrigger:reload_sequence_list_combo()
	local sequence_list = {}
	for _, unit in pairs(self._element.values.sequence_list) do
		table.insert(sequence_list, unit.unit_id)
	end
	self._elements_menu:GetItem("sequence_list"):SetItems(sequence_list)
end
function EditorUnitSequenceTrigger:modify_selected_unit()
	local sequence_combo = self._elements_menu:GetItem("sequence_list")
	local unit_id = sequence_combo:SelectedItem()
	local unit = managers.worlddefinition:get_unit(unit_id)
	if unit then
		local sequence_list_unit = self._element.values.sequence_list[sequence_combo.value]
		local sequence_list = managers.sequence:get_editable_state_sequence_list(unit:name() or "")
		BeardLibEditor.managers.Dialog:show({
	        title = "Modifying " .. unit:unit_data().name_id .. "[" .. unit_id .. "]", 
	        callback = callback(self, self, "apply_modify_sequence_unit", sequence_combo.value),
	        items = {    
	        	{	            
	        		name = "sequence",
		            text = "Sequence:",
		            items = sequence_list,
		            value = table.get_key(sequence_list, sequence_list_unit.sequence),
		            type = "ComboBox",
	        	}                 
	        },  
	        yes = "Apply",
	        no = "Cancel",
	    })
		self:reload_sequence_list_combo()   
	end
end
function EditorUnitSequenceTrigger:apply_modify_sequence_unit(i, items)
	self._element.values.sequence_list[i].sequence = items[1]:SelectedItem()
end
function EditorUnitSequenceTrigger:add_selected_units(value_name)
	for _, unit in pairs(self._editor.managers.UnitEditor._selected_units) do
		if unit:unit_data() then
			table.insert(self._element.values[value_name], {
				guis_id = #self._element.values[value_name] + 1,
				sequence = "",
				unit_id = unit:unit_data().unit_id,
			}) 			
		end
	end
	self:reload_sequence_list_combo()
end
function EditorUnitSequenceTrigger:remove_selected_units(value_name)
	for _, unit in pairs(self._editor.managers.UnitEditor._selected_units) do
		if unit:unit_data() then
			for k, sequence_unit in pairs(self._element.values[value_name]) do 
				if sequence_unit.unit_id == unit:unit_data().unit_id then
					table.remove(self._element.values[value_name], k)
				end
			end
		end
	end
	self:reload_sequence_list_combo()
end
function EditorUnitSequenceTrigger:_build_panel()
	self:_create_panel()
	local sequence_list = {}
	for _, unit in pairs(self._element.values.sequence_list) do
		table.insert(sequence_list, unit.unit_id)
	end
	self._elements_menu:ComboBox({
		name = "sequence_list",
		text = "Sequence List",
		help = "Select a unit to modify",
		items = sequence_list,
	})	
	self._elements_menu:Button({
		name = "modify_selected_unit",
		text = "Modify selected",
		callback = callback(self, self, "modify_selected_unit")
	})	
	self:_build_unit_list("sequence_list", callback(self, self, "select_unit_sequence_list"), "unit_id")
end
