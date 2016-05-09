EditorKillZone = EditorKillZone or class(MissionScriptEditor)
function EditorKillZone:init(unit)
	EditorKillZone.super.init(self, unit)
end

function EditorKillZone:create_element()
    self.super.create_element(self)
    self._class = "ElementKillZone"
    self._element.values.type = "sniper"
end

function EditorKillZone:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("type", {
		"sniper",
		"gas",
		"fire"
	})
end
