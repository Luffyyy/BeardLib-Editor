EditorSecurityCamera = EditorSecurityCamera or class(MissionScriptEditor)
EditorSecurityCamera._object_original_rotations = {}
function EditorSecurityCamera:create_element(unit)
	EditorSecurityCamera.super.create_element(self, unit)
	self._element.class = "ElementSecurityCamera"
	self._element.values.yaw = 0
	self._element.values.pitch = -30
	self._element.values.fov = 60
	self._element.values.detection_range = 15
	self._element.values.suspicion_range = 7
	self._element.values.detection_delay_min = 2
	self._element.values.detection_delay_max = 3
end

function EditorSecurityCamera:show_all_units_dialog()
    BeardLibEditor.managers.Dialog:show({
        title = "Decide what camera unit this element should handle",
        items = {},
        yes = "Apply",
        no = "Cancel",
        w = 600,
        h = 600,
    })
    self:load_all_units(BeardLibEditor.managers.Dialog._menu)
end

function EditorSecurityCamera:select_unit(unit, menu)
	self._element.values.camera_u_id = unit.unit_data and unit:unit_data().unit_id or nil
	self._camera_unit = unit.unit_data and unit or nil
	BeardLibEditor.managers.Dialog:hide()	  
end
 
function EditorSecurityCamera:load_all_units(menu, item)
    menu:ClearItems("select_buttons")
    local searchbox = menu:GetItem("searchbox") or menu:TextBox({
        name = "searchbox",
        text = "Search what: ",
        callback = callback(self, self, "load_all_units")         
    })     
    local selected_divider = menu:GetItem("selected_divider") or menu:Divider({
        name = "selected_divider",
        text = "Selected: ",
        size = 30,    
    })        
    local unselected_divider = menu:GetItem("unselected_divider") or menu:Divider({
        name = "unselected_divider",
        text = "Unselected: ",
        size = 30,    
    })     
    menu:Button({
        name = "no_unit",
        text = "None",
        label = "select_buttons",
        callback = callback(self, self, "select_unit", {})
    })    
     for k, unit in pairs(World:find_units_quick("all")) do
        if #menu._all_items < 200 then
            if unit:unit_data() and unit:base() and unit:base().security_camera and (unit:unit_data().name_id ~= "none" and not searchbox.value or searchbox.value == "" or string.match(unit:unit_data().name_id, searchbox.value or "") or string.match(unit:unit_data().unit_id, searchbox.value or "")) then
                menu:Button({
                    name = unit:unit_data().name_id,
                    text = unit:unit_data().name_id .. " [" .. (unit:unit_data().unit_id or "") .."]",
                    label = "select_buttons",
                    callback = callback(self, self, "select_unit", unit)
                })
            end
        end
    end
end
 
function EditorSecurityCamera:_build_panel()
	self:_create_panel()
    self._menu:Button({
        name = "choose_camera_unit",
        text = "Choose camera unit",
        help = "Decide what camera unit this element should handle",
        callback = callback(self, self, "show_all_units_dialog")
    })    		
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

function EditorSecurityCamera:update_editing()
	self:_find_camera_raycast()
	self:_raycast()
end

function EditorSecurityCamera:_find_camera_raycast()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(100000)
	local ray = World:raycast("ray", from, to, "slot_mask", 1)
	if not ray then
		return
	end
	if ray.unit:id() == -1 then
		return
	end
	if not ray.unit:base() or not ray.unit:base().security_camera then
		return
	end
	Application:draw(ray.unit, 0, 1, 0)
	return ray.unit
end

function EditorSecurityCamera:_raycast()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(100000)
	local ray = World:raycast(from, to, nil, 10)
	if ray and ray.position then
		Application:draw_sphere(ray.position, 10, 1, 1, 1)
		return ray.position
	end
	return nil
end
 
function EditorSecurityCamera:load_camera_unit(unit)
	self:_set_camera_unit(unit)
end

function EditorSecurityCamera:selected()
	EditorSecurityCamera.super.selected(self)
	self:_chk_units_alive()
	if self._camera_u_data then
		self:_align_camera_unit()
	end
end

function EditorSecurityCamera:_set_camera_unit(unit)
	if self._camera_u_data and self._camera_u_data.unit == unit or not self._camera_u_data and not unit then
		return
	end
	if self._camera_u_data then
		self._camera_u_data.unit:get_object(Idstring("CameraYaw")):set_local_rotation(self._camera_u_data.original_rot_yaw)
		self._camera_u_data.unit:get_object(Idstring("CameraPitch")):set_local_rotation(self._camera_u_data.original_rot_pitch)
		self._camera_u_data.unit:set_moving()
	end
	if unit then
		local orig_rot = self._object_original_rotations[unit:name():key()]
		if not orig_rot then
			local obj_yaw = unit:get_object(Idstring("CameraYaw"))
			local obj_pitch = unit:get_object(Idstring("CameraPitch"))
			local original_rot_yaw = obj_yaw:local_rotation()
			local original_rot_pitch = obj_pitch:local_rotation()
			self._object_original_rotations[unit:name():key()] = {yaw = original_rot_yaw, pitch = original_rot_pitch}
			orig_rot = self._object_original_rotations[unit:name():key()]
		end
		self._camera_u_data = {
			unit = unit,
			original_rot_yaw = orig_rot.yaw,
			original_rot_pitch = orig_rot.pitch
		}
		self._element.values.camera_u_id = unit:unit_data().unit_id
		self:_align_camera_unit()
	else
		self._camera_u_data = nil
		self._element.values.camera_u_id = nil
	end
end

function EditorSecurityCamera:_align_camera_unit()
	if self._element.values.apply_settings then
		local unit = self._camera_u_data.unit
		local obj_yaw = unit:get_object(Idstring("CameraYaw"))
		local obj_pitch = unit:get_object(Idstring("CameraPitch"))
		local new_yaw_rot = Rotation(180 + self._element.values.yaw, self._camera_u_data.original_rot_yaw:pitch(), self._camera_u_data.original_rot_yaw:roll())
		obj_yaw:set_local_rotation(new_yaw_rot)
		local new_pitch_rot = Rotation(self._camera_u_data.original_rot_pitch:yaw(), self._element.values.pitch, self._camera_u_data.original_rot_pitch:roll())
		obj_pitch:set_local_rotation(new_pitch_rot)
	else
		self._camera_u_data.unit:get_object(Idstring("CameraYaw")):set_local_rotation(self._camera_u_data.original_rot_yaw)
		self._camera_u_data.unit:get_object(Idstring("CameraPitch")):set_local_rotation(self._camera_u_data.original_rot_pitch)
	end
	self._camera_u_data.unit:set_moving()
end
