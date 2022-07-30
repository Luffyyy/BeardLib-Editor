EditorEnableSoundEnvironment = EditorEnableSoundEnvironment or class(MissionScriptEditor)
EditorEnableSoundEnvironment.WEIRD_ELEMENTS_VALUE = true

function EditorEnableSoundEnvironment:create_element(...)
	EditorEnableSoundEnvironment.super.create_element(self, ...)
	self._element.class = "ElementEnableSoundEnvironment"
	self._element.values.enable = true
	self._element.values.elements = {}
end

function EditorEnableSoundEnvironment:check_unit(unit)
	local ud = unit:unit_data()
	if ud then
		return ud.name == "core/units/sound_environment/sound_environment" and ud.name_id ~= "none"
	end
	
	return false
end

function EditorEnableSoundEnvironment:update_selected(t, dt)
	for _, area in ipairs(managers.sound_environment:areas()) do
		for _, name in ipairs(self._element.values.elements) do
			if area:name() == name then
				self:draw_link({
					g = 0.5,
					b = 1,
					r = 0.9,
					from_unit = self._unit,
					to_unit = area:unit()
				})
			end
		end
	end
end

function EditorEnableSoundEnvironment:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("elements", nil, nil, {need_name_id = true, ignore_unit_id = true, check_unit = ClassClbk(self, "check_unit")})
	self:BooleanCtrl("enable", {help = "Enable or disable the selected Sound Environments"})
	self:Info("Requires the Sound Environments to have a unique name!")
end


function EditorEnableSoundEnvironment:link_managed(unit)
	if alive(unit) and unit:unit_data() and self:check_unit(unit) then
		self:AddOrRemoveManaged("elements", {unit = unit}, {need_name_id = true})
	end
end
