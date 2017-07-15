EditorPrePlanning = EditorPrePlanning or class(MissionScriptEditor)
function EditorPrePlanning:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPrePlanning"
	self._element.values.allowed_types = {}
	self._element.values.disables_types = {}
	self._element.values.location_group = tweak_data.preplanning.location_groups[1]
	self._element.values.upgrade_lock = "none"
	self._element.values.dlc_lock = "none"	
end

function EditorPrePlanning:_data_updated(value_type, value)
	self._element.values[value_type] = value
end

function EditorPrePlanning:_build_panel()
	self:_create_panel()
	self:ComboCtrl("upgrade_lock", tweak_data.preplanning.upgrade_locks, {help =  "Select a upgrade lock from the combobox"})
	self:ComboCtrl("dlc_lock", tweak_data.preplanning.dlc_locks, {help = "Select a DLC lock from the combobox"})
	self:ComboCtrl("location_group", tweak_data.preplanning.location_groups, {help = "Select a location group from the combobox"})
	local types = managers.preplanning:types()
	self:Button("SelectAllowedTypes", function()
	    BeardLibEditor.managers.SelectDialog:Show({
	        selected_list = self._element.values.allowed_types,
	        list = types,
	        callback = callback(self, self, "_data_updated", "allowed_types")
	    })		
	end)	
	self:Button("SelectDisablesTypes", function()
	    BeardLibEditor.managers.SelectDialog:Show({
	        selected_list = self._element.values.disables_types,
	        list = types,
	        callback = callback(self, self, "_data_updated", "disables_types")
	    })		
	end)
end