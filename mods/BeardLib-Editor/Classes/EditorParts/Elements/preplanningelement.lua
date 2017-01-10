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
function EditorPrePlanning:_create_dynamic_on_executed_alternatives() --?
	EditorPrePlanning.ON_EXECUTED_ALTERNATIVES = {"any"}
	for _, type in ipairs(managers.preplanning:types()) do
		table.insert(EditorPrePlanning.ON_EXECUTED_ALTERNATIVES, type)
	end
end
function EditorPrePlanning:_data_updated(value_type, value)
	self._element.values[value_type] = value
end
function EditorPrePlanning:_build_panel()
	self:_create_panel()
	self:ComboCtrl("upgrade_lock", tweak_data.preplanning.upgrade_locks, "Select a upgrade lock from the combobox")
	self:ComboCtrl("dlc_lock", tweak_data.preplanning.dlc_locks, "Select a DLC lock from the combobox")
	self:ComboCtrl("location_group", tweak_data.preplanning.location_groups, "Select a location group from the combobox")
	local allowed_types = {}
	for k, v in pairs(managers.preplanning:types()) do
		allowed_types[v] = self._element.values.allowed_types[v] == true
	end
	--[[ Redo later
	self._menu:Table({
		name = "allowed_types",
		text = "Allowed Types:",
		items = allowed_types,
		add = false,
		remove = false,		
		help = "Select allowed preplanning types for this point",
		callback = callback(self, self, "_data_updated", "allowed_types"),
	})
	local disables_types = {}
	for k, v in pairs(managers.preplanning:types()) do
		disables_types[v] = self._element.values.disables_types[v] == true
	end
	self._menu:Table({
		name = "disables_types",
		text = "Disables Types:",
		items = disables_types,
		add = false,
		remove = false,
		help = "Select preplanning types that are disabled if point is used",
		callback = callback(self, self, "_data_updated", "disables_types"),
	})]]
end
