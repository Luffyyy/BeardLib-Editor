EditorAccessCamera = EditorAccessCamera or class(MissionScriptEditor)
function EditorAccessCamera:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAccessCamera"
	self._element.values.text_id = "debug_none"	
	self._element.values.yaw_limit = 25
	self._element.values.pitch_limit = 25
end
 
function EditorAccessCamera:_build_panel()
	self:_create_panel()

	self:BuildUnitsManage("camera_u_id", nil, nil, {text = "Camera unit", single_select = true, not_table = true, check_unit = function(unit)
		return unit:base() and unit:base().security_camera
	end})
	self:StringCtrl("text_id", {help = "Select a text id from the combobox"})
	self:NumberCtrl("yaw_limit", {floats = 0, min = -1}, {help = "Specify a yaw limit."})
	self:NumberCtrl("pitch_limit", {floats = 0, min = -1}, {help = "Specify a pitch limit."})
end

function EditorAccessCamera:get_unit()
	self._camera_unit = nil
    if not self._element.values.camera_u_id then
        return
    end
	local unit = managers.worlddefinition:get_unit(self._element.values.camera_u_id)
	if alive(unit) then
		self._camera_unit = unit
	end
end

function EditorAccessCamera:update_element(...)
    EditorAccessCamera.super.update_element(self, ...)
    self:get_unit()
end

function EditorAccessCamera:update_selected(t, dt)
	Application:draw_cone(self._unit:position(), self._unit:position() + self._unit:rotation():y() * 75, 35, 1, 1, 1)

	if alive(self._camera_unit) then
		self:draw_link({
			g = 0.75,
			b = 0,
			r = 0,
			from_unit = self._unit,
			to_unit = self._camera_unit
		})
		Application:draw(self._camera_unit, 0, 0.75, 0)
	elseif self._element.values.camera_u_id then
		self._element.values.camera_u_id = nil
		self._camera_unit = nil
	end
end

function EditorAccessCamera:link_managed(unit)
	if alive(unit) then
		if unit:base() and unit:base().security_camera and unit:unit_data() then
			self:AddOrRemoveManaged("camera_u_id", {unit = unit}, {not_table = true})
		end
	end
end

EditorAccessCameraOperator = EditorAccessCameraOperator or class(MissionScriptEditor)
function EditorAccessCameraOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAccessCameraOperator"
	self._element.values.operation = "none"
	self._element.values.elements = {}
end

function EditorAccessCameraOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementAccessCamera", "ElementSecurityCamera"})
	self:ComboCtrl("operation", {"none", "destroy"}, {help = "Select an operation for the selected elements"})
	self:Text("This element can modify point_access_camera element. Select elements to modify using insert and clicking on them.")
end

EditorAccessCameraTrigger = EditorAccessCameraTrigger or class(MissionScriptEditor)

function EditorAccessCameraTrigger:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAccessCameraTrigger"
	self._element.values.trigger_type = "accessed"
	self._element.values.elements = {}	
end

function EditorAccessCameraTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementAccessCamera", "ElementSecurityCamera"})
	self:ComboCtrl("trigger_type", {
		"accessed",
		"destroyed",
		"alarm"
	}, {help = "Select a trigger type for the selected elements"})
	self:Text("This element is a trigger to point_access_camera element.")
end