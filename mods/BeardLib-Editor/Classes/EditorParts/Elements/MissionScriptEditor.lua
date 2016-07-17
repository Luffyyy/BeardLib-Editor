MissionScriptEditor = MissionScriptEditor or class()
MissionScriptEditor.SAVE_UNIT_POSITION = true
MissionScriptEditor.SAVE_UNIT_ROTATION = true
MissionScriptEditor.RANDOMS = nil

function MissionScriptEditor:init(element)
	self._editor = BeardLibEditor.managers.MapEditor
	self._editor_menu = self._editor._menu
	self._elements_menu = self._editor.managers.UnitEditor._menu
	if element then 
		self._element = element
	else
		self:create_element()
	end	
	self._on_executed_units = {}
end
function MissionScriptEditor:add_to_mission()
	return managers.mission:add_element(self._element)
end
function MissionScriptEditor:create_element()		
	local cam = managers.viewport:get_current_camera()	
	self._element = {}	
	self._element.values = {}
	self._element.class = "MissionScriptElement"	
	self._element.editor_name = "NewElement"
	self._element.id = math.random(99999)
	self._element.values.position = cam:position() + cam:rotation():y()
	self._element.values.rotation = Rotation(0,0,0)
	self._element.values.enabled = true
	self._element.values.execute_on_startup = false
	self._element.values.base_delay = 0
	self._element.values.trigger_times = 0
	self._element.values.on_executed = {}
end
function MissionScriptEditor:_build_panel()
	self:_create_panel()
end
function MissionScriptEditor:_create_panel()
	self._elements_menu:ClearItems()    
    self._elements_menu:Divider({
        text = "Class: " .. tostring(self._element.class),
    })

    local quick_buttons = self._elements_menu:ItemsGroup({
        name = "quick_buttons",
        text = "Quick actions",
    })
    local other = self._elements_menu:ItemsGroup({
        name = "other",
        text = "Other",
    })       
    local transform = self._elements_menu:ItemsGroup({
        name = "unit_transform",
        text = "Transform",
    })     
    self._class_group = self._elements_menu:ItemsGroup({
        name = "class_items",
        text = string.pretty(tostring(self._element.class):gsub("Element", ""), true),
    })           
    self._elements_menu:Button({
        name = "deselect_element",
        text = "Deselect element",
        callback = callback(self, self, "deselect_element"),
        group = quick_buttons,
    })     
    local UnitEditor = self._editor.managers.UnitEditor
    self._elements_menu:Button({
        name = "delete_element",
        text = "Delete element",
        callback = callback(UnitEditor, UnitEditor, "delete_selected"),
        group = quick_buttons,
    })    
    self._elements_menu:Button({
        name = "execute_element",
        text = "Execute element",
        callback = callback(managers.mission, managers.mission, "execute_element", self._element),
        group = quick_buttons,
    })
	self:_build_value_checkbox("enabled", "Should the element be enabled", other)
	self._elements_menu:TextBox({
		name = "editor_name",
		text = "Editor Name: ",
		value = self._element.editor_name,
		help = "A name for the element(used to find the element more easily)",
		callback = callback(self, self, "set_element_name"),
        group = other,
	})
    local position = self._element.values.position
    local rotation = self._element.values.rotation
    rotation = type(rotation) == "number" and Rotation(0,0,0) or rotation
	self:_build_value_slider("position_x", {value = position and position.x or 0, callback = callback(self, self, "set_element_position")}, "The x position of the element", transform)
	self:_build_value_slider("position_y", {value = position and position.y or 0, callback = callback(self, self, "set_element_position")}, "The y position of the element", transform)
	self:_build_value_slider("position_z", {value = position and position.z or 0, callback = callback(self, self, "set_element_position")}, "The z position of the element", transform)	
	self:_build_value_slider("rotation_y", {value = rotation and rotation:yaw() or 0, callback = callback(self, self, "set_element_position")}, "The yaw rotation of the element", transform)
	self:_build_value_slider("rotation_p", {value = rotation and rotation:pitch() or 0, callback = callback(self, self, "set_element_position")}, "The pitch rotation of the element", transform)
	self:_build_value_slider("rotation_r", {value = rotation and rotation:pitch() or 0, callback = callback(self, self, "set_element_position")}, "The roll rotation of the element", transform)	
	self:_build_value_checkbox("execute_on_startup", "should the element execute when game starts", other)
	self:_build_value_number("trigger_times", {floats = 0, min = 0}, "Specifies how many time this element can be executed (0 mean unlimited times)", other)
	local base_delay_ctrlr = self:_build_value_number("base_delay", {floats = 0, min = 0,}, "Specifies a base delay that is added to each on executed delay", other)
	local base_delay_rand_ctrlr = self:_build_value_number("base_delay_rand", {floats = 0, min = 0}, "Specifies an additional random time to be added to base delay (delay + rand)", other, "Random delay")
	combo_items = {}
	for _, exec_table in pairs(self._element.values.on_executed) do
		table.insert(combo_items, exec_table.id)
	end	   
	self:_build_element_list("on_executed", nil, callback(self, self, "select_element_on_executed"))
end
function MissionScriptEditor:update_positions(pos, rot)
	local pos_x = self._elements_menu:GetItem("position_x")
	local pos_y = self._elements_menu:GetItem("position_y")
	local pos_z = self._elements_menu:GetItem("position_z")
	local rot_yaw = self._elements_menu:GetItem("rotation_y")
	local rot_pitch = self._elements_menu:GetItem("rotation_p")
	local rot_roll = self._elements_menu:GetItem("rotation_r")
    if pos and pos_x then
        pos_x:SetValue(pos.x or 0, false, true)
        pos_y:SetValue(pos.y or 0, false, true)
        pos_z:SetValue(pos.z or 0, false, true)    
        pos_x:SetStep(self._editor._grid_size)
	    pos_y:SetStep(self._editor._grid_size)
	    pos_z:SetStep(self._editor._grid_size)
    end
    if rot and rot_yaw then
        rot_yaw:SetValue(rot or 0, false, true)
        rot_pitch:SetValue(rot or 0, false, true)
        rot_roll:SetValue(rot or 0, false, true) 
	    rot_yaw:SetStep(self._editor._snap_rotation)
	    rot_pitch:SetStep(self._editor._snap_rotation)
	    rot_roll:SetStep(self._editor._snap_rotation)           
    end          
end
function MissionScriptEditor:deselect_element()
    self._editor.managers.UnitEditor:build_default_menu()
    self._editor._selected_element = nil
    self._editor.managers.SpawnSearch:refresh_search()    
end
function MissionScriptEditor:add_help_text(data)
end
function MissionScriptEditor:_add_help_text(text)
    self:add_help_text(help)
end
 
function MissionScriptEditor:remove_add_element_dialog(params)
    BeardLibEditor.managers.Dialog:show({
        title = "Add an element to " .. params.value_name .." list",
        callback = callback(self, self, "apply_elements", params.value_name),
        items = {},
        yes = "Apply",
        no = "Cancel",
        w = 600,
        h = 600,
    })
    self._selected_elements = clone(self._element.values[params.value_name])
    self:load_all_mission_elements(params)
end
 
function MissionScriptEditor:load_all_mission_elements(params)
	if not params then
		return
	end
	local menu = BeardLibEditor.managers.Dialog._menu
    menu:ClearItems("select_buttons")
    menu:ClearItems("unselect_buttons")
    local searchbox = menu:GetItem("searchbox") or menu:TextBox({
        name = "searchbox",
        text = "Search what: ",
        callback = callback(self, self, "load_all_mission_elements", params)         
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
	for i, v in pairs(self._selected_elements) do
		local element = managers.mission:get_mission_element(type(v) == "number" and v or v.id)
		if element then
	        local new = menu:GetItem(element.id) or menu:Button({
	            name = element.id, 
	            text = element.editor_name .. " [" .. element.id .."]",
	            label = "unselect_buttons",
	            color = element.values.enabled and Color.green or Color.red,
	            index = menu:GetItem("selected_divider"):Index() + 1,
	            callback = function() 
	            	self:unselect_element(i, params)
	        	end
	        })		
	    end
	end    
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do            
                    if #menu._items < 120 and (not searchbox.value or searchbox.value == "" or string.match(element.editor_name, searchbox.value) or string.match(element.id, searchbox.value)) or string.match(element.class, searchbox.value) then
                    	if not menu:GetItem(element.id) and (not params.classes or table.contains(params.classes, element.class)) then
	                        menu:Button({
	                            name = element.editor_name, 
	                            text = element.editor_name .. " [" .. element.id .."]",
	                            label = "select_buttons",
	                            color = element.values.enabled and Color.green or Color.red,
	                            callback = function() 
	                            	if params.select_callback then
	                            		params.select_callback(element.id, params) 
	                            	else 
	                            		self:select_element(element.id, params)
	                            	end
	                        	end
	                        })    
	                    end        
                    end
                end
            end
        end
    end
end

function MissionScriptEditor:select_element_on_executed(id, params)
	table.insert(self._selected_elements, {delay = 0, id = id}) 
	self:load_all_mission_elements(params)
end

function MissionScriptEditor:select_element(id, params)
	table.insert(self._selected_elements, id) 
	self:load_all_mission_elements(params)
end

function MissionScriptEditor:unselect_element(i, params)
	table.remove(self._selected_elements, i)
	self:load_all_mission_elements(params)
end

function MissionScriptEditor:set_element_data(menu, item)
	self._element.values[item.name] = item.SelectedItem and item:SelectedItem() or item.value
	self._element.values[item.name] = tonumber(self._element.values[item.name]) or self._element.values[item.name]
	if item.name == "base_delay_rand" then
		self._element.values[item.name] = self._element.values[item.name] > 0 and self._element.values[item.name] or nil
	end
end
function MissionScriptEditor:set_element_position(menu)
	self._element.values.position = Vector3(menu:GetItem("position_x").value, menu:GetItem("position_y").value, menu:GetItem("position_z").value)
	self._element.values.rotation = Rotation(menu:GetItem("rotation_y").value, menu:GetItem("rotation_p").value, menu:GetItem("rotation_r").value)
end
function MissionScriptEditor:set_element_name(menu, item)
	self._element.editor_name = item.value
end
function MissionScriptEditor:apply_elements(value_name)
	self._element.values[value_name] = self._selected_elements
	combo_items = {}
	for _, element in pairs(self._selected_elements) do
		table.insert(combo_items, type(element) == "number" and element or element.id)
	end
end
function MissionScriptEditor:_build_value_combobox(value_name, options, tooltip, group, custom_name)
	local combo = self._elements_menu:ComboBox({
		name = value_name,
		text = string.pretty(custom_name or value_name, true) .. ":",
	  	help = tooltip,
	  	items = options,
	  	value = table.get_key(options, self._element.values[value_name]),
        group = group or self._class_group,    
	  	callback = callback(self, self, "set_element_data"),
	})
	return combo
end
function MissionScriptEditor:_build_value_number(value_name, options, tooltip, group, custom_name)
	local num = self._elements_menu:TextBox({
		name = value_name,
		text = string.pretty(custom_name or value_name, true) .. ":",
	  	help = tooltip or "Set a number value",
	  	value = options.value or self._element.values[value_name],
	  	filter = "number",
		min = options.min,
		max = options.max,
        floats = options.floats,
        group = group or self._class_group,    
	  	callback = options.callback or callback(self, self, "set_element_data"),
	})
	return num
end
function MissionScriptEditor:_build_value_text(value_name, tooltip, group, custom_name)
	local num = self._elements_menu:TextBox({
		name = value_name,
		text = string.pretty(custom_name or value_name, true) .. ":",
	  	help = tooltip,
	  	value = self._element.values[value_name],
        group = group or self._class_group,        
	  	callback = callback(self, self, "set_element_data"),
	})
	return num
end
function MissionScriptEditor:_build_value_slider(value_name, options, tooltip, group, custom_name)
	local slider = self._elements_menu:Slider({
		name = value_name,
		text = string.pretty(custom_name or value_name, true) .. ":",
	  	help = tooltip or "Set a number value",
	  	value = options.value or self._element.values[value_name],
		min = options.min,
		max = options.max,
        floats = options.floats,
        group = group or self._class_group,
	  	callback = options.callback or callback(self, self, "set_element_data"),
	})
	return slider
end
function MissionScriptEditor:_build_value_checkbox(value_name, tooltip, group, custom_name)
	local toggle = self._elements_menu:Toggle({
		name = value_name,
		text = string.pretty(custom_name or value_name, true) .. ":",
		value = self._element.values[value_name],
	  	help = tooltip or "Click to toggle",
        group = group or self._class_group,    
	  	callback = callback(self, self, "set_element_data"),
	})
	return toggle
end
function MissionScriptEditor:_build_text(text)
	local div = self._elements_menu:Toggle({
		name = text,
		text = string.pretty(text),
		size = 30,
	})
	return div
end

function MissionScriptEditor:_build_unit_list(value_name, select_callback, id_key, update_callback)
    self._elements_menu:Button({
        name = "remove_add_element",
        text = "Add/Remove an unit to " .. value_name .. " list",
        callback = callback(self, self, "remove_add_units_dialog", {value_name = value_name, select_callback = select_callback, id_key = id_key}),
        group = self._elements_menu:GetItem("quick_buttons")
    })     	
	self._elements_menu:Button({
		name = "add_selected_units",
		text = "Add selected unit(s) to " .. value_name,
        callback = function()
            self:add_selected_units(value_name)
            if update_callback then
                update_callback()
            end
        end,        
        group = self._elements_menu:GetItem("quick_buttons")    
	})
	self._elements_menu:Button({
		name = "remove_selected_units",
		text = "Remove selected unit(s) from " .. value_name,
		callback = function()
            self:remove_selected_units(value_name)
            if update_callback then
                update_callback()
            end
        end,
        group = self._elements_menu:GetItem("quick_buttons")
	})	

end

function MissionScriptEditor:_build_element_list(value_name, classes, select_callback)
	if type(value_name) ~= "string" then
		log(tostring( value_name ))
		return
	end
    self._elements_menu:Button({
        name = "remove_add_element",
        text = "Add/Remove an element to " .. value_name .. " list" ,
        callback = callback(self, self, "remove_add_element_dialog", {value_name = value_name, classes = classes, select_callback = select_callback}),
        group = self._elements_menu:GetItem("quick_buttons"),
    })     
end

function MissionScriptEditor:apply_units(value_name)
	self._element.values[value_name] = self._selected_units
end

function MissionScriptEditor:add_selected_units(value_name, clbk)
	for k, unit in pairs(self._editor.managers.UnitEditor._selected_units) do
		if unit:unit_data() and not table.has(self._element.values[value_name], unit:unit_data().unit_id) then
			table.insert(self._element.values[value_name], unit:unit_data().unit_id)
		end
	end
    if clbk then
        clbk()
    end
end

function MissionScriptEditor:remove_selected_units(value_name)
	for k, unit in pairs(self._editor.managers.UnitEditor._selected_units) do
		if unit:unit_data() then
			table.delete(self._element.values[value_name], unit:unit_data().unit_id)
		end
	end
    if clbk then
        clbk()
    end   
end

function MissionScriptEditor:remove_add_units_dialog(params)
    BeardLibEditor.managers.Dialog:show({
        title = "Add an unit to " .. params.value_name,
        callback = callback(self, self, "apply_units", params.value_name),
        items = {},
        yes = "Apply",
        no = "Cancel",
    })
    local unit_ids = clone(self._element.values[params.value_name])
    self._selected_units = unit_ids
    self:load_all_units(params)
end
 
function MissionScriptEditor:select_unit(id, params)
	table.insert(self._selected_units, id) 
	self:load_all_units(params)
end

function MissionScriptEditor:unselect_unit(id, params)
	table.remove(self._selected_units, table.get_key(self._selected_units, id))
	self:load_all_units(params)
end

function MissionScriptEditor:load_all_units(params)
	local menu = BeardLibEditor.managers.Dialog._menu
    menu:ClearItems("select_buttons")
    menu:ClearItems("unselect_buttons")

    local searchbox = menu:GetItem("searchbox") or menu:TextBox({
        name = "searchbox",
        text = "Search what: ",
        callback = callback(self, self, "load_all_units", params)         
    })     
    local selected_divider = menu:GetItem("selected_divider") or menu:Divider({
        name = "selected_divider",
        text = "Selected: ",
    })        
    local unselected_divider = menu:GetItem("unselected_divider") or menu:Divider({
        name = "unselected_divider",
        text = "Unselected: ",
    })     
	for i, unit_id in pairs(self._selected_units) do
		if type(unit_id) ~= "number" and params.id_key then
			unit_id = unit_id[params.id_key]
		else
			BeardLibEditor:log("Failed getting unit")
		end
		local unit = managers.worlddefinition:get_unit(unit_id)
		if unit then
	        local new = menu:GetItem(unit_id) or menu:Button({
	            name = unit_id, 
	            text = unit:unit_data().name_id .. " [" .. unit_id .."]",
	            label = "unselect_buttons",
	            color = unit:enabled() and Color.green or Color.red,
	            index = menu:GetItem("selected_divider"):Index() + 1,
	            callback = function() 
	            	self:unselect_unit(unit_id, params)
	        	end
	        })		
	    else
	    	BeardLibEditor:log("Failed getting unit %s", tostring( unit_id ))
	    end
	end    

    for _, unit in pairs(World:find_units_quick("all")) do
    	if unit:unit_data() and not menu:GetItem(unit:unit_data().unit_id) then
	        if #menu._items < 200 and (not searchbox.value or searchbox.value == "" or string.match(unit:unit_data().name_id, searchbox.value) or string.match(unit:unit_data().unit_id, searchbox.value)) then
	            menu:Button({
	                name = unit:unit_data().unit_id, 
	                text = unit:unit_data().name_id .. " [" .. unit:unit_data().unit_id .."]",
	                label = "select_buttons",
	                color = unit:enabled() and Color.green or Color.red,
                    callback = function() 
                    	if params.select_callback then
                    		params.select_callback(unit:unit_data().unit_id, params) 
                    	else 
                    		self:select_unit(unit:unit_data().unit_id, params)
                    	end
                	end
	            })    
	        end
	    end
    end
end