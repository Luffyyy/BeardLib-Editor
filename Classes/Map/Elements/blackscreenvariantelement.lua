EditorBlackscreenVariant = EditorBlackscreenVariant or class(MissionScriptEditor)
function EditorBlackscreenVariant:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBlackscreenVariant"
	self._element.values.variant = "0" 
end
function EditorBlackscreenVariant:_build_panel()
	self:_create_panel()
	self:ComboCtrl("variant", self:_get_params(), {help = "Select variant, from level_tweak_data.level.intro_event"})
end
function EditorBlackscreenVariant:_get_params()
	local tbl = {}
	for i=1, 30 do 
		table.insert(tbl, tostring(i))
	end
	return tbl
end

-------------------------------------------------------------------------------------

EditorEndscreenVariant = EditorEndscreenVariant or class(EditorBlackscreenVariant)
function EditorEndscreenVariant:create_element()
	EditorBlackscreenVariant.super.create_element(self)
	self._element.class = "ElementEndscreenVariant"
	self._element.values.variant = "0" 
end

function EditorEndscreenVariant:_build_panel()
	self:_create_panel()
	self:ComboCtrl("variant", self:_get_params(), {help = "Select variant, from level_tweak_data.level.outro_event"})
end

-------------------------------------------------------------------------------------

EditorFailureVariant = EditorFailureVariant or class(EditorBlackscreenVariant)
function EditorFailureVariant:create_element()
	EditorBlackscreenVariant.super.create_element(self)
	self._element.class = "ElementFailureVariant"
	self._element.values.variant = "0" 
end

function EditorFailureVariant:_build_panel()
	self:_create_panel()
	self:ComboCtrl("variant", self:_get_params(), {help = "Select variant, from level_tweak_data.level.failure_music"})
end