EditorStatisticsContact = EditorStatisticsContact or class(MissionScriptEditor)
EditorStatisticsContact.SAVE_UNIT_POSITION = false
EditorStatisticsContact.SAVE_UNIT_ROTATION = false
function EditorStatisticsContact:init(unit)
	MissionScriptEditor.init(self, unit)
end
function EditorStatisticsContact:create_element()
	self.super.create_element(self)
	self._element.class = "ElementStatisticsContact"
	self._element.values.elements = {}
	self._element.values.contact = "bain"
	self._element.values.state = "completed"
	self._element.values.difficulty = "all"
	self._element.values.include_dropin = false
	self._element.values.required = 1
end
function EditorStatisticsContact:_build_panel()
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local contact_list = {}
	for contact, _ in pairs(tweak_data.narrative.contacts) do
		if contact ~= "wip" and contact ~= "tests" then
			table.insert(contact_list, contact)
		end
	end
	table.sort(contact_list)
	self:_build_value_combobox("contact", contact_list, "Select the required contact")
	local states = {
		"started",
		"started_dropin",
		"completed",
		"completed_dropin",
		"failed",
		"failed_dropin"
	}
	self:_build_value_combobox("state", states, "Select the required play state.")
	local difficulties = deep_clone(tweak_data.difficulties)
	table.insert(difficulties, "all")
	self:_build_value_combobox("difficulty", difficulties, "Select the required difficulty.")
	self:_build_value_checkbox("include_dropin", "Select if drop-in is counted as well.")
	self:_build_value_number("required", {floats = 0, min = 1}, "Type the required amount that is needed.")
end
