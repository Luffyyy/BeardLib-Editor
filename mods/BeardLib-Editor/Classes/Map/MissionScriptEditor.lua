MissionScriptEditor = MissionScriptEditor or class(EditorPart)
function MissionScriptEditor:init(element)
	self:init_basic(managers.editor, "MissionElement")
	self._menu = self:Manager("static")._holder
	MenuUtils:new(self)
	self._on_executed_units = {}
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
    self._links = self:Manager("static"):build_links(self._element.id, true)
    if #self._class_group._my_items == 0 then
    	self:RemoveItem(self._class_group)
    end
    self._unit = self:Manager("mission"):get_element_unit(self._element.id)
    self._on_executed_units = {}
	for _, u in pairs(self._element.values.on_executed) do
		table.insert(self._on_executed_units, self:Manager("mission"):get_element_unit(u.id))
	end
	local executors = managers.mission:get_executors(self._element)
	self._executors_units = {}
	for _, element in pairs(executors) do
		table.insert(self._executors_units, self:Manager("mission"):get_element_unit(element.id))
	end

	local temp = clone(self._links)
	self._links = {}
	for _, element in pairs(self._links) do
		if not executors[element.id] then
			table.insert(self._links, element)
		end
	end
end

function MissionScriptEditor:_build_panel()
	self:_create_panel()
end

function MissionScriptEditor:_create_panel()
	if alive(self._main_group) then
		return
	end
	self._main_group = self:Group("Main")	
	local quick_buttons = self:Group("QuickButtons")
	local transform = self:Group("Transform")
	self._class_group = self:Group(self._element.class:gsub("Element", "") .. "") 
	self:Button("DeselectElement", callback(self, self, "deselect_element"), {group = quick_buttons})    
	local SE = self:Manager("static")
	self:Button("DeleteElement", callback(SE, SE, "delete_selected"), {group = quick_buttons})
	self:Button("ExecuteElement", callback(managers.mission, managers.mission, "execute_element", self._element), {group = quick_buttons})
 	self:BooleanCtrl("enabled", {help = "Should the element be enabled", group = self._main_group})
 	self:StringCtrl("editor_name", {help = "A name/nickname for the element, it makes it easier to find in the editor", data = self._element, group = self._main_group})
 	self:ComboCtrl("script", table.map_keys(managers.mission._scripts), {data = self._element, group = self._main_group})
 	self._element.values.position = self._element.values.position or Vector3()
 	self._element.values.rotation = self._element.values.rotation or Rotation()
    local pos = self._element.values.position
    local rot = self._element.values.rotation
    rotation = type(rotation) == "number" and Rotation() or rotation
    self:AxisControls(callback(self, self, "set_element_position"), {group = transform})
    self:update_positions(pos, rot)
    self:BooleanCtrl("execute_on_startup", {help = "Should the element execute when game starts", group = self._main_group})
    self:NumberCtrl("trigger_times", {help = "Specifies how many time this element can be executed (0 = unlimited times)", group = self._main_group, floats = 0, min = 0})
    self:NumberCtrl("base_delay", {help = "Specifies a base delay that is added to each on executed delay", group = self._main_group, floats = 0, min = 0})
    self:NumberCtrl("base_delay_rand", {help = "Specifies an additional random time to be added to base delay(delay + rand)", group = self._main_group, floats = 0, min = 0, text = "Random Delay"})
	self:ComboBox("OnExecutedList", callback(self, self, "update_on_executed_list"), {}, 1, {group = self._main_group})
	self:NumberBox("SelectedElementDelay", callback(self, self, "set_selected_on_executed_element_delay"), nil, {control_slice = 2.5, floats = 0, min = 0, group = self._main_group})  		
	self:BuildElementsManage("on_executed", {key = "id", orig = {id = 0, delay = 0}}, nil, callback(self, self, "update_on_executed_list"), self._main_group)
	self:update_on_executed_list()
end

function MissionScriptEditor:update_on_executed_list()
	local on_executed_items = {}
	local on_executed = self._menu:GetItem("OnExecutedList")
	local selected_item = on_executed:SelectedItem()
	local selected_element_delay = self._menu:GetItem("SelectedElementDelay")
	for _, element in pairs(self._element.values.on_executed) do
		local element = managers.mission:get_mission_element(element.id)  
		if element then		
			table.insert(on_executed_items, element.editor_name .. "[" .. element.id .. "]")
		end
	end		
	on_executed:SetItems(on_executed_items)
	on_executed:SetSelectedItem(selected_item)
	local value = self._menu:GetItem("OnExecutedList"):Value()
	if value then
		selected_element_delay:SetValue(self._element.values.on_executed[value].delay)
	end
end

function MissionScriptEditor:set_selected_on_executed_element_delay(menu, item)
	local value = self._menu:GetItem("OnExecutedList"):Value()
	if value then
		self._element.values.on_executed[value].delay = item:Value()
		self:update_element()
	end
end

function MissionScriptEditor:update_positions(pos, rot)
	if not self.x or not pos or not rot then
		return
	end
    self:SetAxisControls(pos, rot)
    for i, control in pairs(self._axis_controls) do
    	self[control]:SetStep(i < 4 and self._parent._grid_size or self._parent._snap_rotation)
    end
    self:update_element()  
end

function MissionScriptEditor:update(t, dt)
	self:draw_links()
end

function MissionScriptEditor:draw_links()
	self:draw_link_on_executed()
	for _, unit in pairs(self._executors_units) do
		self:draw_link_exec(unit, self._unit)
	end
	self:draw_elements(self._links, true)
	self:draw_elements(self._element.values.orientation_elements)
	self:draw_elements(self._element.values.rules_elements)
end

function MissionScriptEditor:draw_elements(elements, is_link)
	if not elements then
		return
	end
	for _, id in ipairs(elements) do
		local unit = self:Manager("mission"):get_element_unit(id)
		if self:should_draw_link(selected_unit, unit) then
			local r, g, b = unit:mission_element()._color:unpack()
			self:_draw_link({
				from_unit = is_link and self._unit or unit,
				to_unit = is_link and unit or self._unit,
				r = r,
				g = g,
				b = b
			})
		end
	end
end

function MissionScriptEditor:should_draw_link(unit)
	local selected_unit = self:selected_unit()
	return unit == selected_unit or self._unit == selected_unit
end

function MissionScriptEditor:draw_link_on_executed()
    local selected_unit = self:selected_unit()
    local unit_sel = self._unit == selected_unit
    for _, unit in ipairs(self._on_executed_units) do
        if alive(unit) then
            if unit_sel or unit == selected_unit then
            	self:draw_link_exec(self._unit, unit)
            end
        else
            table.delete(self._on_executed_units, unit)
        end
    end
end

function MissionScriptEditor:draw_link_exec(element_unit, unit)
    local dir = mvector3.copy(unit:position())
    mvector3.subtract(dir, element_unit:position())
    local vec_len = mvector3.normalize(dir)
    local offset = math.min(50, vec_len)
    mvector3.multiply(dir, offset)
    local text = self:get_delay_string(unit:mission_element().element.id, element_unit:mission_element().element)
    local alternative = self:get_on_executed(unit:mission_element().element.id, element_unit:mission_element().element).alternative
    if alternative then
        text = text .. " - " .. alternative .. ""
    end

    self._brush:center_text(element_unit:position() + dir, text, managers.editor:camera_rotation():x(), -managers.editor:camera_rotation():z())
    local element_col = element_unit:mission_element()._color
	self._brush:set_color(element_col)
    local r, g, b = element_col:unpack()
    self:draw_link({
        from_unit = element_unit,
        to_unit = unit,
        r = r * 0.75,
        g = g * 0.75,
        b = b * 0.75
    })
end

function MissionScriptEditor:draw_link(params)
	params.draw_flow = true -- managers.editor:layer("Mission"):visualize_flow()
	Application:draw_link(params)
end

function MissionScriptEditor:get_delay_string(id, element)
	element = element or self._element
	local delay = element.values.base_delay + self:get_on_executed(id, element).delay
	local text = string.format("%.2f", delay)
	if element.values.base_delay_rand or self:get_on_executed(id, element).delay_rand then
		local delay_max = delay + (self:get_on_executed(id, element).delay_rand or 0)
		delay_max = delay_max + (element.values.base_delay_rand and element.values.base_delay_rand or 0)
		text = text .. "-" .. string.format("%.2f", delay_max) .. ""
	end
	return text
end

function MissionScriptEditor:get_on_executed(id, element)
	return self:get({id_key = "id", tbl_key = "on_executed"}, id, element)
end

function MissionScriptEditor:get(table_data, id, element)
	element = element or self._element
	local id_key = table_data.id_key
	local tbl = element.values[table_data.tbl_key]
	for _, v in ipairs(tbl) do
		if (id_key and v[id_key] == id) or v == id then
			return v
		end
	end
end

function MissionScriptEditor:deselect_element()
    self:Manager("static"):build_default_menu()
    self._parent._selected_element = nil
end

function MissionScriptEditor:update_element(old_script)
	managers.mission:set_element(self._element, old_script)
	local unit = self:selected_unit()
	if alive(unit) and unit.element then
		unit:set_position(self._element.values.position)
		unit:set_rotation(self._element.values.rotation)
	end
end

function MissionScriptEditor:set_element_data(menu, item)
	local old_script = self._element.script
	function set_element_data()
		local data = self:ItemData(item)
		data[item.name] = item.SelectedItem and item:SelectedItem() or item:Value()
		data[item.name] = tonumber(data[item.name]) or data[item.name]
		if item.name == "base_delay_rand" then
			data[item.name] = data[item.name] > 0 and data[item.name] or nil
		end
		self:update_element(old_script)	
	end
	if item.name == "script" and item:SelectedItem() ~= old_script then
		BeardLibEditor.Utils:YesNoQuestion("This will move the element to a diffeent mission script, the id will be changed and all executors will be removed!", function()
			set_element_data()
		end)
	else
		set_element_data()
	end
end

function MissionScriptEditor:set_element_position(menu)
	self._element.values.position = self:AxisControlsPosition()
	self._element.values.rotation = self:AxisControlsRotation()
	self:update_element()
end

function MissionScriptEditor:BuildUnitsManage(value_name, table_data, update_clbk, group)
	self:Button("Manage"..value_name.."List", callback(self, self, "OpenUnitsManageDialog", {value_name = value_name, update_clbk = update_clbk, table_data = table_data}), {text = "Manage "..value_name.." List", group = group or self._class_group})
end

function MissionScriptEditor:BuildElementsManage(value_name, table_data, classes, update_clbk, group)
	self:Button("Manage"..value_name.."List", callback(self, self, "OpenElementsManageDialog", {value_name = value_name, update_clbk = update_clbk, table_data = table_data, classes = classes}), {text = "Manage "..value_name.." List", group = group or self._class_group})
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

function MissionScriptEditor:ManageElementIdsClbk(params, final_selected_list)
	local current_list = self._element.values[params.value_name] or {}
	self._element.values[params.value_name] = {}
	for _, data in pairs(final_selected_list) do
		local unit = data.unit
		local element = data.element
		local id = unit and unit:unit_data().unit_id or element.id
		if params.table_data then	    	
			local add 	
    		for _, v in pairs(current_list) do
            	if type(v) == "table" and v[params.table_data.key] == id then
            		add = v
            		break
            	end
            end
            if not add then
            	add = clone(params.table_data.orig)
            	add[params.table_data.key] = id
            end
			table.insert(self._element.values[params.value_name], add)
		else
			table.insert(self._element.values[params.value_name], id)
		end 
	end
	if params.update_clbk then
		params.update_clbk(params.value_name)
	end
end

function MissionScriptEditor:OpenElementsManageDialog(params)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name] or {}
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
                	if not params.classes or table.contains(params.classes, element.class) then     
                		table.insert(list, data)
                	end
                end
            end
        end
    end
	BeardLibEditor.managers.SelectDialog:Show({
	    selected_list = selected_list,
	    list = list,
	    callback = params.callback or callback(self, self, "ManageElementIdsClbk", params)
	})
	self:update_element()
end

function MissionScriptEditor:OpenUnitsManageDialog(params)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name] or {}
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
    	if (not params.units or table.contains(params.units, ud.name)) and (not params.check_unit or params.check_unit(unit)) then
    		table.insert(list, data)
    	end
    end
	BeardLibEditor.managers.SelectDialog:Show({
	    selected_list = selected_list,
	    list = list,
	    callback = params.callback or callback(self, self, "ManageElementIdsClbk", params)
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

function MissionScriptEditor:ListSelectorOpen(params)
    BeardLibEditor.managers.SelectDialog:Show({
        selected_list = params.selected_list,
        list = params.list,
        callback = function(list) 
 			params.data[params.value_name] = #list > 0 and list or nil
        end
    })
end

function MissionScriptEditor:ListSelector(value_name, list, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	local data = self:ItemData(opt)
	self:Button(value_name, callback(self, self, "ListSelectorOpen", {value_name = value_name, selected_list = data[value_name], list = list, data = data}), opt)
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
