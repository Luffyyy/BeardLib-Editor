EditorAlertTrigger = EditorAlertTrigger or class(MissionScriptEditor)
function EditorAlertTrigger:create_element()	
	self.super.create_element(self)
	self._element.class = "ElementAlertTrigger"
	self._element.values.filter = "0"
	self._element.values.alert_types = {}
end

function EditorAlertTrigger:_build_panel()
	self:_create_panel()
	local alert_type_table = {
		"footstep",
		"vo_ntl",
		"vo_cbt",
		"vo_intimidate",
		"vo_distress",
		"bullet",
		"aggression",
		"explosion"
	}
	self._alert_type_check_boxes = {}
	for i, o in ipairs(alert_type_table) do
		local check = self._menu:Toggle({
			name = o,
			text = string.pretty(o, true),
			value = table.contains(self._element.values.alert_types, o),
			callback = callback(self, self, "on_alert_type_checkbox_changed"),
		})
		self._alert_type_check_boxes[o] = check
	end
	self._menu:ComboBox({
		name = "preset",
		text = "Preset:",
		items = {"clear", "all"},
		help = "Select a preset.",
		callback = callback(self, self, "apply_preset"),
	})
	local opt = NavigationManager.ACCESS_FLAGS
	local filter_table = managers.navigation:convert_access_filter_to_table(self._element.values.filter)
	self._filter_check_boxes = {}
	for i, o in ipairs(opt) do
		local check = self._menu:Toggle({
			name = o,
			text = string.pretty(o, true),
			value = table.contains(filter_table, o),
			callback = callback(self, self, "on_filter_checkbox_changed"),
		})		
		self._filter_check_boxes[o] = check
	end
end

function EditorAlertTrigger:apply_preset(menu, item)
	local value = item:SelectedItem()
	BeardLibEditor.Utils:YesNoQuestion("This will apply the preset" .. (item:SelectedItem() or ""), function()
		if value == "clear" then
			self:_set_filter_none()
		elseif value == "all" then
			self:_set_filter_all()
		else
			BeardLibEditor:log(tostring(value) .. " Didn't have preset yet.")
		end	
	end)
end

function EditorAlertTrigger:_set_filter_all()
	for name, item in pairs(self._filter_check_boxes) do
		item:SetValue(true)
	end
	self._element.values.filter = managers.navigation:convert_access_filter_to_string(managers.navigation.ACCESS_FLAGS)
end

function EditorAlertTrigger:_set_filter_none()
	for name, item in pairs(self._filter_check_boxes) do
		item:SetValue(false)
	end
	self._element.values.filter = "0"
end

function EditorAlertTrigger:on_filter_checkbox_changed(menu, item)
	local filter_table = managers.navigation:convert_access_filter_to_table(self._element.values.filter)
	local value = item.value
	if value then
		if table.contains(filter_table, item.name) then
			return
		end
		table.insert(filter_table, item.name)
	else
		table.delete(filter_table, item.name)
	end
	self._element.values.filter = managers.navigation:convert_access_filter_to_string(filter_table)
	local filter = managers.navigation:convert_access_filter_to_number(self._element.values.filter)
end

function EditorAlertTrigger:on_alert_type_checkbox_changed(menu, item)
	local value = item.value
	if value then
		if table.contains(self._element.values.alert_types, item.name) then
			return
		end
		table.insert(self._element.values.alert_types, item.name)
	else
		table.delete(self._element.values.alert_types, item.name)
	end
end
