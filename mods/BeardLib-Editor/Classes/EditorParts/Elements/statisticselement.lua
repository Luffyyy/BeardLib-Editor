EditorStatistics = EditorStatistics or class(MissionScriptEditor)
EditorStatistics.SAVE_UNIT_POSITION = false
EditorStatistics.SAVE_UNIT_ROTATION = false
function EditorStatistics:init(unit)
	MissionScriptEditor.init(self, unit)
end
function EditorStatistics:create_element()
    self.super.create_element(self)
    self._element.class = "ElementStatistics"
    self._element.values.elements = {}
    self._element.values.name = tweak_data.statistics:mission_statistics_table()[1]
end
function EditorStatistics:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("name", tweak_data.statistics:mission_statistics_table(), "Select an mission statistics from the combobox")
end
