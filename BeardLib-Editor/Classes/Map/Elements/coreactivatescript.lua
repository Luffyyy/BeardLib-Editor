EditorActivateScript = EditorActivateScript or class(MissionScriptEditor)
function EditorActivateScript:init(...)
	local unit = EditorActivateScript.super.init(self, ...)
	if self._element.values.activate_script ~= "none" and not table.contains(self:scripts(), self._element.values.activate_script) then
		self._element.values.activate_script = "none"
	end
	return unit
end

function EditorActivateScript:create_element(...)
	EditorActivateScript.super.create_element(self, ...)
	self._element.class = "ElementActivateScript"
	self._element.values.activate_script = "none"
end

function EditorActivateScript:scripts()
	return managers.mission._scripts
end

function EditorActivateScript:_build_panel()
	self:_create_panel()
	self:ComboCtrl("script", self:scripts(), {default = "none"})
end