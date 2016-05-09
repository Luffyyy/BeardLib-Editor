EditorPlayerStyle = EditorPlayerStyle or class(MissionScriptEditor)
function EditorPlayerStyle:init(unit)
	EditorPlayerStyle.super.init(self, unit)
end
function EditorPlayerStyle:create_element()
    self.super.create_element(self) 
    self._element.class = "ElementPlayerStyle"
    self._element.values.style = ""
end
function EditorPlayerStyle:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("style", {"_scrubs"}, "Select a style from the combobox")
	self:add_help_text( "Change player style.")
end
