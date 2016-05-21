EditorMissionFilter = EditorMissionFilter or class(MissionScriptEditor)
EditorMissionFilter.SAVE_UNIT_POSITION = false
EditorMissionFilter.SAVE_UNIT_ROTATION = false
function EditorMissionFilter:init(unit)
	EditorMissionFilter.super.init(self, unit)
end

function EditorMissionFilter:create_element()
    self.super.create_element(self)
	self._element.class = "ElementMissionFilter"
	self._element.values[1] = true
	self._element.values[2] = true
	self._element.values[3] = true
	self._element.values[4] = true
	self._element.values[5] = true    
end

function EditorMissionFilter:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox(1, "", nil, "Mission filter 1")
	self:_build_value_checkbox(2, "", nil, "Mission filter 2")
	self:_build_value_checkbox(3, "", nil, "Mission filter 3")
	self:_build_value_checkbox(4, "", nil, "Mission filter 4")
	self:_build_value_checkbox(5, "", nil, "Mission filter 5")
end
