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