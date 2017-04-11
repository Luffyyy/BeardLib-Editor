EditorStatistics = EditorStatistics or class(MissionScriptEditor)
function EditorStatistics:create_element()
    self.super.create_element(self)
    self._element.class = "ElementStatistics"
    self._element.values.elements = {}
    self._element.values.name = tweak_data.statistics:mission_statistics_table()[1]
end

function EditorStatistics:_build_panel()
	self:_create_panel()
    self:ComboCtrl("name", tweak_data.statistics:mission_statistics_table(), {help = "Select an mission statistics from the combobox"})
end
