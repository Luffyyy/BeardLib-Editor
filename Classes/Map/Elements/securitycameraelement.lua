EditorSecurityCamera = EditorSecurityCamera or class(MissionScriptEditor)
EditorSecurityCamera._object_original_rotations = {}
function EditorSecurityCamera:create_element()
	EditorSecurityCamera.super.create_element(self)
	self._element.class = "ElementSecurityCamera"
	self._element.values.yaw = 0
	self._element.values.pitch = -30
	self._element.values.fov = 60
	self._element.values.detection_range = 15
	self._element.values.suspicion_range = 7
	self._element.values.detection_delay_min = 2
	self._element.values.detection_delay_max = 3
end

function EditorSecurityCamera:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("camera_u_id", nil, nil, {text = "Camera unit", single_select = true, not_table = true, check_unit = function(unit)
		return unit:base() and unit:base().security_camera
	end})
 	self:BooleanCtrl("ai_enabled")
 	self:BooleanCtrl("apply_settings")
	self:NumberCtrl("yaw", {min = -180, max = 180, help = "Specify camera yaw (degrees)."})
	self:NumberCtrl("pitch", {min = -90, max = 90, help = "Specify camera pitch (degrees)."})
	self:NumberCtrl("fov", {min = 0, max = 180, help = "Specify camera FOV (degrees)."})
	self:NumberCtrl("detection_range", {min = 0, floats = 0, help = "Specify camera detection_range (meters)."})
	self:NumberCtrl("suspicion_range", {min = 0, floats = 0, help = "Specify camera suspicion_range."})
	self:NumberCtrl("detection_delay_min", {min = 0, floats = 0, help = "Detection delay at zero distance."})
	self:NumberCtrl("detection_delay_max", {min = 0, floats = 0, help = "Detection delay at max distance."})
end

function EditorSecurityCamera:update_selected(t, dt)
	Application:draw_cone(self._unit:position(), self._unit:position() + self._unit:rotation():y() * 75, 35, 1, 1, 1)

	local unit = managers.worlddefinition:get_unit(self._element.values.camera_u_id)
	if alive(unit) then
		self:draw_link({
			g = 0.75,
			b = 0,
			r = 0,
			from_unit = self._unit,
			to_unit = unit
		})
		Application:draw(unit, 0, 0.75, 0)
	else
		self._element.values.camera_u_id = nil
	end
end

function EditorSecurityCamera:link_managed(unit)
	if alive(unit) then
		if unit:base() and unit:base().security_camera and unit:unit_data() then
			self:AddOrRemoveManaged("camera_u_id", {unit = unit}, {not_table = true})
		end
	end
end