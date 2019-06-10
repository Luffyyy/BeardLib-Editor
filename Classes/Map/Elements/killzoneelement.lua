EditorKillZone = EditorKillZone or class(MissionScriptEditor)

function EditorKillZone:create_element()
    self.super.create_element(self)
    self._element.class = "ElementKillZone"
    self._element.values.type = "sniper"
end

function EditorKillZone:_build_panel()
	self:_create_panel()
	self:ComboCtrl("type", {
		"sniper",
		"gas",
		"fire",
        "kill"
	})
end
