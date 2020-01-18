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
	local alert_types = self._class_group:group("AlertTypes")
	for i, o in ipairs(alert_type_table) do
		alert_types:Toggle({
			name = o,
			text = string.pretty(o, true),
			value = table.contains(self._element.values.alert_types, o),
			on_callback = ClassClbk(self, "on_alert_type_checkbox_changed"),
		})
	end
	self._class_group:button("SelectFlags", ClassClbk(self, "open_select_flags"))
end

function EditorAlertTrigger:open_select_flags()
	local opt = NavigationManager.ACCESS_FLAGS
	local filter_table = managers.navigation:convert_access_filter_to_table(self._element.values.filter)

	self:ListSelectorOpen({
		list = opt,
		selected_list = filter_table,
		callback = ClassClbk(self, "on_filter_checkbox_changed")
	})
end

function EditorAlertTrigger:apply_preset(item)
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

function EditorAlertTrigger:on_filter_checkbox_changed(selected)
	self._element.values.filter = managers.navigation:convert_access_filter_to_string(selected)
end

function EditorAlertTrigger:on_alert_type_checkbox_changed(item)
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
