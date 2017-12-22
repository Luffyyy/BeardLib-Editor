MissionScriptEditor = MissionScriptEditor or class(EditorPart)
function MissionScriptEditor:init(element, old_element)
	self:init_basic(managers.editor, "MissionElement")
	self._menu = self:Manager("static")._holder
	MenuUtils:new(self)
	self._on_executed_units = {}
	self._draw_units = {}
	if element then
		self._element = element
	else
		self:create_element()
		if not self._element.editor_name then
			self._element.editor_name = string.underscore_name(self._element.class:gsub("Element", ""))
		end
		if old_element then
			table.merge(self._element, old_element)
		end
		return managers.mission:add_element(self._element)
	end
end

function MissionScriptEditor:create_element()		
	local cam = managers.viewport:get_current_camera()	
	self._element = {}	
	self._element.values = {}
	self._element.class = "MissionScriptElement"
	self._element.script = self._parent._current_script
	self._element.values.position = self._parent:cam_spawn_pos()
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
    self._links = self:Manager("static"):build_links(self._element.id, true, self._element)
    if #self._class_group._my_items == 0 then
    	self:RemoveItem(self._class_group)
    end
    self._unit = self:Manager("mission"):get_element_unit(self._element.id)
	self:get_on_executed_units()
	local executors = managers.mission:get_executors(self._element)
	self._executors_units = {}
	for _, element in pairs(executors) do
		local unit = self:Manager("mission"):get_element_unit(element.id)
		if alive(unit) then
			table.insert(self._executors_units, unit)
		end
	end
	local temp = clone(self._links)
	self._links = {}
	for _, element in pairs(self._links) do
		if not executors[element.id] then
			table.insert(self._links, element)
		end
	end
end

function MissionScriptEditor:get_on_executed_units()
    self._on_executed_units = {}
	for _, u in pairs(self._element.values.on_executed) do
		if self:Manager("mission"):get_element_unit(u.id) then
			table.insert(self._on_executed_units, self:Manager("mission"):get_element_unit(u.id))
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
	local SE = self:Manager("static")
	self._main_group = self:Group("Main")
	local quick_buttons = self:Group("QuickButtons")
	local transform = self:Group("Transform")
	local element = self._element.class:gsub("Element", "") .. ""
	self._class_group = self:Group(element) 
	SE:SetTitle(element)
	self:Button("DeselectElement", callback(self, self, "deselect_element"), {group = quick_buttons})    
	self:Button("DeleteElement", callback(SE, SE, "delete_selected_dialog"), {group = quick_buttons})
    self:Button("CreatePrefab", callback(SE, SE, "add_selection_to_prefabs"), {group = quick_buttons})
	self:Button("ExecuteElement", callback(managers.mission, managers.mission, "execute_element", self._element), {group = quick_buttons})
 	self:StringCtrl("editor_name", {help = "A name/nickname for the element, it makes it easier to find in the editor", data = self._element, group = self._main_group})
 	self:StringCtrl("id", {group = self._main_group, data = self._element, enabled = false})
 	self:ComboCtrl("script", table.map_keys(managers.mission._scripts), {data = self._element, group = self._main_group})
 	self._element.values.position = self._element.values.position or Vector3()
 	self._element.values.rotation = self._element.values.rotation or Rotation()
    local pos = self._element.values.position
    local rot = self._element.values.rotation
    rot = type(rot) == "number" and Rotation() or rot
    SE:AxisControls(callback(self, self, "set_element_position"), {group = transform})
    self:update_positions(pos, rot)
    self:NumberCtrl("trigger_times", {help = "Specifies how many times this element can be executed (0 = unlimited times)", group = self._main_group, floats = 0, min = 0})
    self:NumberCtrl("base_delay", {help = "Specifies a base delay that is added to each on executed delay", group = self._main_group, floats = 0, min = 0})
    self:NumberCtrl("base_delay_rand", {help = "Specifies an additional random time to be added to base delay(delay + rand)", group = self._main_group, floats = 0, min = 0, text = "Random Delay"})
 	self:BooleanCtrl("enabled", {help = "Should the element be enabled", group = self._main_group})
    self:BooleanCtrl("execute_on_startup", {help = "Should the element execute when game starts", group = self._main_group})
	local on_exec = {values_name = "Delay", value_key = "delay", default_value = 0, key = "id", orig = {id = 0, delay = 0}}
	self:BuildElementsManage("on_executed", on_exec, nil, nil, {
		group = self._main_group, help = "This list contains elements that this element will execute."
	})
	if self.ON_EXECUTED_ALTERNATIVES then
		local alts = clone(self.ON_EXECUTED_ALTERNATIVES)
		table.insert(alts, "none")
		on_exec = clone(on_exec)
		on_exec.values_name = "Alternative"
		on_exec.value_key = "alternative"
		on_exec.default_value = "none"
		on_exec.combo_items_func = function() return alts end 
		self:BuildElementsManage("on_executed", on_exec, nil, nil, {text = "Manage On Executed list / Alternative"})
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
	local SE = self:Manager("static")
	if not SE.x or not pos or not rot then
		return
	end
    SE:SetAxisControls(pos, rot)
    for i, control in pairs(self._axis_controls) do
    	SE[control]:SetStep(i < 4 and self._parent._grid_size or self._parent._snap_rotation)
    end
    self:update_element()  
end

function MissionScriptEditor:add_draw_units(draw)
	draw.update_units = draw.update_units or callback(self, self, "update_draw_units", draw)
	draw.update_units()
	draw.units = draw.units or {}
	table.insert(self._draw_units, draw)
end

function MissionScriptEditor:update_draw_units(draw)
	draw.units = {}
	for k, v in pairs(self._element.values[draw.key]) do
		local id = v
		if type(id) == "table" then
			id = id[draw.id_key]
		end
		if type(id) == "number" then
			local unit = managers.worlddefinition:get_unit(id)
			if alive(unit) then
				draw.units[unit:unit_data().unit_id] = unit
			else
				table.remove(self._element.values[draw.key], k)
			end
		end
	end
end

function MissionScriptEditor:update(t, dt)
	self:draw_links()
	for _, draw in pairs(self._draw_units) do
		for id, unit in pairs(draw.units) do
			if not alive(unit) then
				if draw.update_units then
					draw.update_units()
				end
				return
			else
				self:draw_link({
					from_unit = self._unit,
					to_unit = unit,
					r = draw.r or 0,
					g = draw.g or 1,
					b = draw.b or 0
				})
				Application:draw(unit, draw.r or 0, draw.g or 1, draw.b or 0)
			end
		end
	end
end

function MissionScriptEditor:draw_links()
	if not alive(self._unit) then
		return
	end
	self:draw_link_on_executed()
	for _, unit in pairs(self._executors_units) do
		self:draw_link_exec(unit, self._unit)
	end
	self:draw_elements(self._links, true)
	self:draw_elements(self._element.values.orientation_elements)
	self:draw_elements(self._element.values.rules_elements)
	self:draw_elements(self._element.values.elements)
end

function MissionScriptEditor:draw_elements(elements, is_link)
	if not elements then
		return
	end
	for k, id in ipairs(elements) do
		local unit = self:Manager("mission"):get_element_unit(id)
		if alive(unit) then
			if self:should_draw_link(selected_unit, unit) then
				local r, g, b = unit:mission_element()._color:unpack()
				self:draw_link({
					from_unit = is_link and self._unit or unit,
					to_unit = is_link and unit or self._unit,
					r = r,
					g = g,
					b = b
				})
			end
		else
			elements[k] = nil
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
    if text then
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
end

function MissionScriptEditor:draw_link(params)
	params.draw_flow = true -- managers.editor:layer("Mission"):visualize_flow()
	Application:draw_link(params)
end

function MissionScriptEditor:get_delay_string(id, element)
	element = element or self._element
	local exec = self:get_on_executed(id, element)
	if exec then
		local delay = element.values.base_delay + exec.delay
		local text = string.format("%.2f", delay)
		if element.values.base_delay_rand or exec.delay_rand then
			local delay_max = delay + (exec.delay_rand or 0)
			delay_max = delay_max + (element.values.base_delay_rand and element.values.base_delay_rand or 0)
			text = text .. "-" .. string.format("%.2f", delay_max) .. ""
		end
		return text
	else
		return false
	end
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
	self:Manager("static"):build_links(self._element.id, true, self._element)
end

function MissionScriptEditor:set_element_data(menu, item)
	if not item then
		return
	end
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
			self:Manager("mission"):set_elements_vis()
		end)
	else
		set_element_data()
	end
	if item.name == "editor_name" and alive(self._unit) then
		self._unit:mission_element():update_text()
	end
end

function MissionScriptEditor:set_element_position(menu)
	local SE = self:Manager("static")
	self._element.values.position = SE:AxisControlsPosition()
	self._element.values.rotation = SE:AxisControlsRotation()
	self:update_element()
end

function MissionScriptEditor:BuildUnitsManage(value_name, table_data, update_clbk, opt)
	opt = opt or {}
	local group = opt.group
	opt.group = nil
	self:Button("Manage"..value_name.."List", callback(self, self, "OpenUnitsManageDialog", {
		value_name = value_name,
		update_clbk = update_clbk, 
		check_unit = opt.check_unit,
		not_table = opt.not_table,
		units = opt.units,
		single_select = opt.single_select,
		need_name_id = opt.need_name_id, 
		table_data = table_data
	}), table.merge({text = "Manage "..string.pretty(value_name, true).." List(units)", help = "Decide which units are in this list", group = group or self._class_group}, opt))
end

function MissionScriptEditor:BuildInstancesManage(value_name, table_data, update_clbk, opt)
	opt = opt or {}
	local group = opt.group
	opt.group = nil
	self:Button("Manage"..value_name.."List", callback(self, self, "OpenInstancesManageDialog", {
		value_name = value_name, 
		update_clbk = update_clbk, 
		table_data = table_data
	}), table.merge({text = "Manage "..string.pretty(value_name, true).." List(instances)", help = "Decide which instances are in this list", group = group or self._class_group}, opt))
end

function MissionScriptEditor:BuildElementsManage(value_name, table_data, classes, update_clbk, opt)
	opt = opt or {}
	local group = opt.group
	opt.group = nil
	self:Button("Manage"..value_name.."List", callback(self, self, "OpenElementsManageDialog", {
		value_name = value_name, 
		update_clbk = update_clbk,
		single_select = opt.single_select,
		not_table = opt.not_table,
		table_data = table_data,
		classes = classes
	}), table.merge({text = "Manage "..string.pretty(value_name, true).." List(elements)", help = "Decide which elements are in this list", group = group or self._class_group}, opt))
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
    self._element.values[params.value_name] = not params.not_table and {} or nil
    for _, data in pairs(final_selected_list) do
        local id
        local value
        if type(data) == "table" then
            local unit = data.unit
            local element = data.element
            local instance = data.instance
            id = (unit and (params.need_name_id and unit:unit_data().name_id or unit:unit_data().unit_id)) or instance or element and element.id
            value = data.value
        else
            id = data
        end
        if params.table_data then           
			local add = data.orig_tbl
            if not add then
                add = clone(params.table_data.orig)
                add[params.table_data.key] = id
            end
            if value and params.table_data.value_key then
                add[params.table_data.value_key] = value
            end
            if params.not_table then
            	self._element.values[params.value_name] = add
            else
            	table.insert(self._element.values[params.value_name], add)
            end
        elseif params.not_table then
        	self._element.values[params.value_name] = id
        else
            table.insert(self._element.values[params.value_name], id)
        end
    end
    if params.update_clbk then
        params.update_clbk(params.value_name)
	end
	self:update_element()
end

function MissionScriptEditor:OpenElementsManageDialog(params)
    local selected_list = {}
    local list = {}
    local current_list = self._element.values[params.value_name] or {}
    current_list = type(current_list) ~= "table" and {current_list} or current_list
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                    if element.id ~= self._element.id then
                        local data = {
                            name =  element.editor_name .. " - " .. element.class:gsub("Element", "") .. " [" .. element.id .."]",
                            element = element,
                        }
                        if params.table_data then
                            for _, v in pairs(current_list) do
                                if type(v) == "table" and v[params.table_data.key] == element.id then
									if params.table_data.value_key then
										data.value = v[params.table_data.value_key] or params.table_data.orig[params.table_data.value_key] or params.table_data.default_value
									else
										data.value = nil
									end
									data.orig_tbl = v
									table.insert(selected_list, clone(data or {}))
                                end
                            end
                        elseif table.contains(current_list, element.id) then 
							table.insert(selected_list, data)
                        end
                        if not params.classes or table.contains(params.classes, element.class) then
                            if params.table_data and params.table_data.value_key then
                                data.value = params.table_data.orig[params.table_data.value_key] or params.table_data.default_value
							end
							data.orig_tbl = nil
                            table.insert(list, data)
                        end
                    end
                end
            end
        end
    end
    BeardLibEditor.managers.SelectDialogValue:Show({
        selected_list = selected_list,
        list = list,
        values_name = params.table_data and params.table_data.values_name,
		combo_items_func = params.table_data and params.table_data.combo_items_func,
        single_select = params.single_select,
        allow_multi_insert = NotNil(params.allow_multi_insert, true),
        not_table = params.not_table,
        callback = params.callback or callback(self, self, "ManageElementIdsClbk", params)
    })
    self:update_element()
end

function MissionScriptEditor:OpenUnitsManageDialog(params)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name] or {}
	current_list = type(current_list) ~= "table" and {current_list} or current_list
    for k, unit in pairs(managers.worlddefinition._all_units) do
    	if alive(unit) then
	 		local ud = unit:unit_data()
			 if ud and not ud.instance then
				local data = {
					name = tostring(unit:unit_data().name_id) .. " [" .. (unit:unit_data().unit_id or "") .."]",
					unit = unit,
				}
				if params.table_data then
					for _, v in pairs(current_list) do
						if type(v) == "table" and v[params.table_data.key] == ud.unit_id then
							if params.table_data.value_key then
								data.value = v[params.table_data.value_key] or params.table_data.orig[params.table_data.value_key] or params.table_data.default_value
							else
								data.value = nil
							end
							data.orig_tbl = v
							table.insert(selected_list, clone(data or {}))
						end
					end
				elseif table.contains(current_list, ud.unit_id) then
					table.insert(selected_list, data)
				end
				if (not params.units or table.contains(params.units, ud.name)) and (not params.check_unit or params.check_unit(unit)) then
					if params.table_data and params.table_data.value_key then
						data.value = params.table_data.orig[params.table_data.value_key] or params.table_data.default_value
					end
					data.orig_tbl = nil
					table.insert(list, data)
				end
			end
	 	end
    end
	BeardLibEditor.managers.SelectDialogValue:Show({
	    selected_list = selected_list,
	    list = list,
		values_name = params.table_data and params.table_data.values_name,
		combo_items_func = params.table_data and params.table_data.combo_items_func,
		allow_multi_insert = NotNil(params.allow_multi_insert, true),
		need_name_id = params.need_name_id,
		single_select = params.single_select,
		not_table = params.not_table,
		callback = params.callback or callback(self, self, "ManageElementIdsClbk", params)
	})
	self:update_element()
end

function MissionScriptEditor:OpenInstancesManageDialog(params)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name] or {}
	current_list = type(current_list) ~= "table" and {current_list} or current_list
    for k, instance in pairs(managers.world_instance:instance_names_by_script(self._element.script)) do
 		local data = {
	   		name = instance,
	   		instance = instance,
 		}
		if params.table_data then
			for _, v in pairs(current_list) do
				if type(v) == "table" and v[params.table_data.key] == instance then
                    if params.table_data.value_key and params.table_data.orig[params.table_data.value_key] then
                        data.value = v[params.table_data.value_key] or params.table_data.orig[params.table_data.value_key]
                    end
			 		table.insert(selected_list, data)
				end
			end
		else
			if table.contains(current_list, data) then
				table.insert(selected_list, data)
			end
		end
        if params.table_data and params.table_data.value_key and params.table_data.orig[params.table_data.value_key] then
            data.value = data.value or params.table_data.orig[params.table_data.value_key]
        end
		table.insert(list, data)
	end
	BeardLibEditor.managers.SelectDialogValue:Show({
		selected_list = selected_list,
		list = list,
		values_name = params.table_data and params.table_data.values_name,
		combo_items_func = params.table_data and params.table_data.combo_items_func,
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

function MissionScriptEditor:PathCtrl(value_name, type, check_slot, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return self:PathItem(value_name, callback(self, self, "set_element_data"), self:ItemData(opt)[value_name], type, true, function(unit)
   	    return (not check_slot or BeardLibEditor.Utils:InSlot(unit, check_slot)) and not unit:match("husk")
	end, true, opt)
end