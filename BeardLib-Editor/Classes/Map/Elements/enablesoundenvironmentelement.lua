EditorEnableSoundEnvironment = EditorEnableSoundEnvironment or class(MissionScriptEditor)
function EditorEnableSoundEnvironment:create_element(...)
	EditorEnableSoundEnvironment.super.create_element(self, ...)
	self._element.class = "ElementEnableSoundEnvironment"
	self._element.values.enable = true
	self._element.values.elements = {}
end

function EditorEnableSoundEnvironment:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("elements", nil, nil, {check_unit = function(unit)
		return unit:type() == Idstring("sound")
	end})
	self:BooleanCtrl("enable", {help = "if enable is true then the sound area will be enabled otherwise it will be disabled"})
end