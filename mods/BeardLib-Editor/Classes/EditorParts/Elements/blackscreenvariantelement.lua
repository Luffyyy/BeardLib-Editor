EditorBlackscreenVariant = EditorBlackscreenVariant or class(MissionScriptEditor)
function EditorBlackscreenVariant:init(unit)
	EditorBlackscreenVariant.super.init(self, unit)
end
function EditorBlackscreenVariant:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBlackscreenVariant"
	self._element.values.variant = "0" 
end
function EditorBlackscreenVariant:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("variant", self:_get_params(), "Select variant, from level_tweak_data.level.intro_event")
end
function EditorBlackscreenVariant:_get_params()
	return {
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"10",
		"11",
		"12",
		"13",
		"14",
		"15",
		"16",
		"17",
		"18",
		"19",
		"20",
		"21",
		"22",
		"23",
		"24",
		"25",
		"26",
		"27",
		"28",
		"29",
		"30"
	}
end
EndscreenVariantElement = EndscreenVariantElement or class(EditorBlackscreenVariant)
function EndscreenVariantElement:init(unit)
	EndscreenVariantElement.super.init(self, unit)
end
function EditorBlackscreenVariant:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("variant", self:_get_params(), "Select variant, from level_tweak_data.level.outro_event", "Endscreen variant:")
end
 