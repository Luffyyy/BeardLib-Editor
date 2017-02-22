MissionScriptEditor = MissionScriptEditor or class(EditorPart)
function MissionScriptEditor:init(element)
	self:init_basic(managers.editor, "MissionElement")
	self._menu = self:Manager("static")._menu
	if element then 
		self._element = element
	else
		self:create_element()
		return managers.mission:add_element(self._element)
	end	
end

function MissionScriptEditor:create_element()		
	local cam = managers.viewport:get_current_camera()	
	self._element = {}	
	self._element.values = {}
	self._element.class = "MissionScriptElement"	
	self._element.editor_name = "New Element"
	self._element.id = math.random(99999) -- Todo: generate id instead of makinga a random one 
	self._element.values.position = cam:position() + cam:rotation():y()
	self._element.values.rotation = Rotation()
	self._element.values.enabled = true
	self._element.values.execute_on_startup = false
	self._element.values.base_delay = 0
	self._element.values.trigger_times = 0
	self._element.values.on_executed = {}
end

function MissionScriptEditor:work()
	self.super.build_default_menu(self)
	self:_build_panel()
    local executors = managers.mission:get_links(self._element)       
    if #executors > 0 then 
        self:Group("Links")
        for _, element in pairs(executors) do
            self:Button(element.editor_name .. " [" .. (element.class or "") .."]", callback(self, self, "set_element", element), {group = executors_group})
        end 
    end
    if #self._class_group.items == 0 then
    	self._menu:RemoveItem(self._class_group)
    end
end

function MissionScriptEditor:_build_panel()
	self:_create_panel()
end

function MissionScriptEditor:_create_panel()
	local main = self:Group("Main")	
	local quick_buttons = self:Group("QuickButtons")
	local transform = self:Group("Transform")
	self._class_group = self:Group(self._element.class:gsub("Element", "") .. "") 
	self:Button("DeselectElement", callback(self, self, "deselect_element"), {group = quick_buttons})    
	local SE = self:Manager("static")
	self:Button("DeleteElement", callback(SE, SE, "delete_selected"), {group = quick_buttons})
	self:Button("ExecuteElement", callback(managers.mission, managers.mission, "execute_element", self._element), {group = quick_buttons})
 	self:BooleanCtrl("enabled", {help = "Should the element be enabled", group = main})
 	self:StringCtrl("editor_name", {help = "The element's editor name to be used to find quickly find it in the editor.", data = self._element, group = main})
 	self._element.values.position = self._element.values.position or Vector3()
 	self._element.values.rotation = self._element.values.rotation or Rotation()
    local pos = self._element.values.position
    local rot = self._element.values.rotation
    rotation = type(rotation) == "number" and Rotation() or rotation
    self._axis = {"x", "y", "z"}
    self._rot_axis = {"yaw", "pitch", "roll"}
    for _, axis in pairs(self._axis) do
        self[axis] = self:NumberBox(string.pretty(axis, true), callback(self, self, "set_element_position"), pos[axis], {group = transform, step = self._parent._grid_size})
    end    
    for _, axis in pairs(self._rot_axis) do
        self[axis] = self:NumberBox(string.pretty(axis, true), callback(self, self, "set_element_position"), rot[axis](rot), {group = transform})
    end
    self:BooleanCtrl("execute_on_startup", {help = "Should the element execute when game starts", group = main})
    self:NumberCtrl("trigger_times", {help = "Specifies how many time this element can be executed (0 = unlimited times)", group = main, floats = 0, min = 0})
    self:NumberCtrl("base_delay", {help = "Specifies a base delay that is added to each on executed delay", group = main, floats = 0, min = 0})
    self:NumberCtrl("base_delay_rand", {help = "Specifies an additional random time to be added to base delay(delay + rand)", group = main, floats = 0, min = 0, text = "Random Delay"})
	self:BuildElementsManage("on_executed", {key = "id", orig = {id = 0, delay = 0}})
end

function MissionScriptEditor:update_positions(pos, rot)
	if not self.x then
		return
	end
    if pos then
    	for _, axis in pairs(self._axis) do
    		self[axis]:SetValue(pos[axis] or 0, false, true)
    		self[axis]:SetStep(self._parent._grid_size)
    	end
    end
    if rot then
    	for _, axis in pairs(self._rot_axis) do
    		self[axis]:SetValue(rot[axis](rot) or 0, false, true)
    		self[axis]:SetStep(self._parent._snap_rotation)
    	end      
    end          
end

function MissionScriptEditor:deselect_element()
    self:Manager("static"):build_default_menu()
    self._parent._selected_element = nil
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

function MissionScriptEditor:update_element()
	managers.mission:set_element(self._element)
end

function MissionScriptEditor:set_element_data(menu, item)
	local data = self:ItemData(item)
	data[item.name] = item.SelectedItem and item:SelectedItem() or item:Value()
	data[item.name] = tonumber(data[item.name]) or data[item.name]
	if item.name == "base_delay_rand" then
		data[item.name] = data[item.name] > 0 and data[item.name] or nil
	end
	self:update_element()
end
function MissionScriptEditor:set_element_position(menu)
	self._element.values.position = Vector3(self.x:Value(), self.y:Value(), self.z:Value())
	self._element.values.rotation = Rotation(self.yaw:Value(), self.pitch:Value(), self.roll:Value())
	self:update_element()
end

function MissionScriptEditor:apply_elements(value_name)
	self._element.values[value_name] = self._selected_elements
	self:update_element()
end

function MissionScriptEditor:BuildUnitsManage(value_name, table_data)
    self._menu:Button({
        name = "remove_add_element",
        text = "Add/Remove an unit to " .. value_name .. " list",
        callback = callback(self, self, "OpenUnitsManageDialog", {value_name = value_name, table_data = table_data}),
        group = self._menu:GetItem("QuickButtons")
    })     	
	self._menu:Button({
		name = "add_selected_units",
		text = "Add selected unit(s) to " .. value_name,
        callback = function()
            self:add_selected_units(value_name)
        end,        
        group = self._menu:GetItem("QuickButtons")    
	})
	self._menu:Button({
		name = "remove_selected_units",
		text = "Remove selected unit(s) from " .. value_name,
		callback = function()
            self:remove_selected_units(value_name)
        end,
        group = self._menu:GetItem("QuickButtons")
	})	
end

function MissionScriptEditor:BuildElementsManage(value_name, table_data, classes)
	if type(value_name) ~= "string" then
		log(tostring( value_name ))
		return
	end
    self._menu:Button({
        name = "remove_add_element",
        text = "Add/Remove an element to " .. value_name .. " list" ,
        callback = callback(self, self, "OpenElementsManageDialog", {value_name = value_name, table_data = table_data}),
        group = self._menu:GetItem("quick_buttons"),
    })     
end

function MissionScriptEditor:add_selected_units(value_name, clbk)
	for k, unit in pairs(self:Manager("static")._selected_units) do
		if unit:unit_data() and not table.has(self._element.values[value_name], unit:unit_data().unit_id) then
			table.insert(self._element.values[value_name], unit:unit_data().unit_id)
		end
	end
    if clbk then
        clbk()
    end
end

function MissionScriptEditor:remove_selected_units(value_name)
	for k, unit in pairs(self:Manager("static")._selected_units) do
		if unit:unit_data() then
			table.delete(self._element.values[value_name], unit:unit_data().unit_id)
		end
	end
    if clbk then
        clbk()
    end   
end

function MissionScriptEditor:OpenElementsManageDialog(params)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name]
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                	local data = {
                		name = element.editor_name .. " [" .. element.id .."]",
                		element = element,
                	}
                	if params.table_data then
                		for _, v in pairs(current_list) do
                			if type(v) == "table" and v[params.table_data.key] == element.id then
						 		table.insert(selected_list, data)
                			end
                		end
                	else
				 		if table.contains(current_list, element.id) then 
				 			table.insert(selected_list, data)
				 		end                   		
                	end                 
                	table.insert(list, data)
                end
            end
        end
    end
	managers.editor._select_list:Show({
	    selected_list = selected_list,
	    list = list,
	    callback = params.callback or function(final_selected_list)
	    	self._element.values[params.value_name] = {}
	    	for _, data in pairs(final_selected_list) do
	    		if params.table_data then	    	
	    			local add 	
		    		for _, v in pairs(current_list) do
	                	if type(v) == "table" and v[params.table_data.key] == data.element.id then
	                		add = v
	                		break
	                	end
	                end
	                if not add then
	                	add = clone(params.table_data.orig)
	                	add[params.table_data.key] = data.element.id
	                end
	    			table.insert(self._element.values[params.value_name], add)
	    		else
	    			table.insert(self._element.values[params.value_name], data.element.id)
	    		end 
	    	end
	    end
	})
	self:update_element()
end

function MissionScriptEditor:OpenUnitsManageDialog(params)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name]
    for k, unit in pairs(managers.worlddefinition._all_units) do
 		local ud = unit:unit_data()
 		local data = {
	   		name = tostring(unit:unit_data().name_id) .. " [" .. (unit:unit_data().unit_id or "") .."]",
	   		unit = unit, 			
 		}
    	if params.table_data then
    		for _, v in pairs(current_list) do
    			if type(v) == "table" and v[params.table_data.key] == ud.unit_id then
			 		table.insert(selected_list, data)
    			end
    		end
    	else
	 		if table.contains(current_list, ud.unit_id) then 
	 			table.insert(selected_list, data)
	 		end                   		
    	end                 
    	table.insert(list, data)
    end
	managers.editor._select_list:Show({
	    selected_list = selected_list,
	    list = list,
	    callback = params.callback or function(final_selected_list)
	    	self._element.values[params.value_name] = {}
	    	for _, data in pairs(final_selected_list) do
	    		local unit = data.unit
	    		local id = unit:unit_data().unit_id
	    		if params.table_data then	    	
	    			local add 	
		    		for _, v in pairs(current_list) do
	                	if type(v) == "table" and v[params.table_data.key] == id then
	                		add = v
	                	end
	                end
	                if not add then
	                	add = params.table_data.orig
	                	add[params.table_data.key] = id
	                end
	    			table.insert(self._element.values[params.value_name], add)
	    		else
	    			table.insert(self._element.values[params.value_name], id)
	    		end 
	    	end
	    end
	})
	self:update_element()
end

function MissionScriptEditor:BasicCtrlInit(value_name, opt)
	opt = opt or {}
	opt.group = opt.group or self._class_group
	opt.text = string.pretty(value_name, true)
	return opt
end

function MissionScriptEditor:ItemData(item)
	if not item then
		log(debug.traceback())
	end
	return item.data or self._element.values
end

function MissionScriptEditor:Text(text, opt)
	opt = opt or {}
	opt.group = opt.group or self._class_group
    return self:Divider(text, opt)
end

function MissionScriptEditor:NumberCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return self:NumberBox(value_name, callback(self, self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:BooleanCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return self:Toggle(value_name, callback(self, self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:StringCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return self:TextBox(value_name, callback(self, self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:ComboCtrl(value_name, items, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return self:ComboBox(value_name, callback(self, self, "set_element_data"), items, table.get_key(items, self:ItemData(opt)[value_name]), opt)
end
