EditorUnitSequence = EditorUnitSequence or class(MissionScriptEditor)
function EditorUnitSequence:init(element) 
	self.super.init(self, element)
end
function EditorUnitSequence:create_element()
    self.super.create_element(self)
	self._element.class = "ElementUnitSequence"
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
	self:reload_trigger_list_combo()
end
function EditorUnitSequence:reload_trigger_list_combo()
	local trigger_list = {}
	for _, unit in pairs(self._element.values.trigger_list) do
		table.insert(trigger_list, unit.notify_unit_id)
	end
	self._elements_menu:GetItem("trigger_list"):SetItems(trigger_list)
end
function EditorUnitSequence:modify_selected_unit()
	local trigger_list = self._elements_menu:GetItem("trigger_list")
	local unit_id = tonumber(trigger_list:SelectedItem())
	local unit = managers.worlddefinition:get_unit(unit_id)
	local trigger_list_unit = self._element.values.trigger_list[trigger_list.value]
	local sequence_list = managers.sequence:get_editable_state_sequence_list(unit and unit:name() or "")
	if trigger_list_unit and unit then
		local items = {              
			{
				name = "name",
				text = "Name:",
				value = trigger_list_unit.name,
				type = "TextBox",
			},        
			{
				name = "notify_unit_sequence",
				text = "Notify Unit Sequence:",
				items = sequence_list,
				value = table.get_key(sequence_list, trigger_list_unit.notify_unit_sequence),
				type = "ComboBox",
			},           
			{
				name = "time",
				text = "Time:",
				value = trigger_list_unit.time,
				filter = "number",
				min = 0,
				type = "TextBox",
			},      
		}	
		BeardLibEditor.managers.Dialog:show({
			title = "Modifying " .. (unit and unit:unit_data().name_id or "") .. "[" .. unit_id .. "]", 
			callback = callback(self, self, "apply_modify_trigger_unit", trigger_list.value),
			items = items,
			yes = "Apply",
			no = "Cancel",
		})
		self:reload_trigger_list_combo()   
	end
end
function EditorUnitSequence:apply_modify_trigger_unit(i, items)
	self._element.values.trigger_list[i].name = items[1].value
	self._element.values.trigger_list[i].notify_unit_sequence = tonumber(items[2]:SelectedItem())
	self._element.values.trigger_list[i].time = tonumber(items[3].value)
end
function EditorUnitSequence:add_selected_units(value_name)
	for _, unit in pairs(self._editor.managers.UnitEditor._selected_units) do
		if unit:unit_data() then
			table.insert(self._element.values[value_name], {
				name = "run_sequence", 
				id = #self._element.values[value_name] + 1, 
				notify_unit_id = unit:unit_data().unit_id,
				time = 0,
				notify_unit_sequence = "" 
			}) 			
		end
	end
	self:reload_trigger_list_combo()
end
function EditorUnitSequence:remove_selected_units(value_name)
	for _, unit in pairs(self._editor.managers.UnitEditor._selected_units) do
		if unit:unit_data() then
			for k, trigger_list_unit in pairs(self._element.values[value_name]) do 
				if trigger_list_unit.notify_unit_id == unit:unit_data().unit_id then
					table.remove(self._element.values[value_name], k)
				end
			end
		end
	end
	self:reload_trigger_list_combo()
end
function EditorUnitSequence:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("only_for_local_player")
	local trigger_list = {}
	for _, unit in pairs(self._element.values.trigger_list) do
		table.insert(trigger_list, unit.notify_unit_id)
	end
	self._elements_menu:ComboBox({
		name = "trigger_list",
		text = "Trigger List",
		help = "Select a unit to modify",
		items = trigger_list,
	})	
	self._elements_menu:Button({
		name = "modify_selected_unit",
		text = "Modify selected",
		callback = callback(self, self, "modify_selected_unit")
	})	
	self:_build_unit_list("trigger_list", callback(self, self, "select_unit_trigger_list"), "notify_unit_id")

	self:add_help_text("Use the \"Edit Triggable\" interface, which you enable in the down left toolbar, to select and edit which units and sequences you want to run.")
end
