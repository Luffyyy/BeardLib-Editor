EditorAccessCamera = EditorAccessCamera or class(MissionScriptEditor) --wip.
EditorAccessCamera._text_options = {"debug_none"}
function EditorAccessCamera:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAccessCamera"
	self._element.values.text_id = "debug_none"	
	self._camera_unit = nil
	self._element.values.yaw_limit = 25
	self._element.values.pitch_limit = 25
	self._element.values.camera_u_id = nil	
end
function EditorAccessCamera:_add_text_options()
	self._text_options = {"debug_none"}
	for _, id_string in ipairs(managers.localization:ids("strings/hud")) do
		local s = id_string:s()
		if string.find(s, "cam_") then
			table.insert(self._text_options, s)
		end
	end
	for _, id_string in ipairs(managers.localization:ids("strings/wip")) do
		local s = id_string:s()
		if string.find(s, "cam_") then
			table.insert(self._text_options, s)
		end
	end
end
function EditorAccessCamera:_set_text()
	self._text:set_value(managers.localization:text(self._element.values.text_id))
end
  
function EditorAccessCamera:set_element_data(params, ...)
	EditorAccessCamera.super.set_element_data(self, params, ...)
	if params.value == "text_id" then
		self:_set_text()
	end
end
 
function EditorAccessCamera:show_all_units_dialog()
    BeardLibEditor.managers.Dialog:show({
        title = "Decide what camera unit this element should handle",
        items = {},
        no = "Cancel",
        w = 600,
        h = 600,
    })
    self:load_all_units(BeardLibEditor.managers.Dialog._menu)
end

function EditorAccessCamera:select_unit(unit, menu)
	self._element.values.camera_u_id = unit.unit_data and unit:unit_data().unit_id or nil
	self._camera_unit = unit.unit_data and unit or nil
	BeardLibEditor.managers.Dialog:hide()	  
end
 
function EditorAccessCamera:load_all_units(menu, item)
    menu:ClearItems("select_buttons")
    local searchbox = menu:GetItem("searchbox") or menu:TextBox({
        name = "searchbox",
        text = "Search what: ",
        callback = callback(self, self, "load_all_units")         
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

function EditorAccessCamera:_build_panel()
	self:_create_panel()
    self._menu:Button({
        name = "choose_camera_unit",
        text = "Choose camera unit",
        help = "Decide what camera unit this element should handle",
        callback = callback(self, self, "show_all_units_dialog")
    })    	
	self:ComboCtrl("text_id", self._text_options, {help = "Select a text id from the combobox"})
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
