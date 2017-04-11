EditorBlackScreenVariant = EditorBlackScreenVariant or class(MissionScriptEditor)
function EditorBlackScreenVariant:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBlackscreenVariant"
	self._element.values.variant = "0" 
end
function EditorBlackScreenVariant:_build_panel()
	self:_create_panel()
	self:ComboCtrl("variant", self:_get_params(), "Select variant, from level_tweak_data.level.intro_event")
end
function EditorBlackScreenVariant:_get_params()
	local tbl = {}
	for i=1, 30 do 
		table.insert(tbl, tostring(i))
	end
	return tbl
end
EndscreenVariantElement = EndscreenVariantElement or class(EditorBlackScreenVariant)
function EditorBlackScreenVariant:_build_panel()
	self:_create_panel()
	self:ComboCtrl("variant", self:_get_params(), {
		help = "Select variant, from level_tweak_data.level.outro_event", 
		text = "Endscreen variant:"
	})
end
 