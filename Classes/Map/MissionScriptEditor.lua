MissionScriptEditor = MissionScriptEditor or class(EditorPart)
MissionScriptEditor.CLASS = "MissionScriptElement"
function MissionScriptEditor:init(element, old_element)
	self:init_basic(managers.editor, "MissionElement")
	self._on_executed_units = {}
	self._draw_units = {}
	if element then
		self._element = element
	else
		self:create_element()
		if not self._element.editor_name then
			self._element.editor_name = self:GetPart("mission"):get_name_id(self._element.class, old_element and old_element.from_name_id or nil)
		end
		if old_element then
			old_element.from_name_id = nil
			table.merge(self._element, old_element)
		end
		return managers.mission:add_element(self._element)
	end
	self._hed = self._element.values
end

function MissionScriptEditor:create_element()
	self._element = {}
	self._element.values = {}
	self._element.class = self.CLASS
	if self.MODULE then
		self._element.module = self.MODULE
	end
	self._element.script = self._parent._current_script
	self._element.values.position = self._parent:GetSpawnPosition()
	self._element.values.rotation = Rotation()
	self._element.values.enabled = true
	self._element.values.execute_on_startup = false
	self._element.values.base_delay = 0
	self._element.values.trigger_times = 0
	self._element.values.on_executed = {}
	self._hed = self._element.values
end

function MissionScriptEditor:work()
	local static = self:GetPart("static")
	self._holder = static._holder
	ItemExt:add_funcs(self, self._holder)

	static:clear_menu()
	self:_build_panel()
    self._links = static:build_links(self._element.id, BLE.Utils.LinkTypes.Element, self._element)
    if #self._class_group._my_items == 0 then
    	self:RemoveItem(self._class_group)
    end
    self._unit = self:GetPart("mission"):get_element_unit(self._element.id)
	self:get_on_executed_units()
	local executors = managers.mission:get_executors(self._element)
	self._executors_units = {}
	for _, element in pairs(executors) do
		local unit = self:GetPart("mission"):get_element_unit(element.id)
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
	self._holder:AlignItems(true)
end

function MissionScriptEditor:build_instance_links()
	self:GetPart("static"):build_links(self._element.id, BLE.Utils.LinkTypes.Element, self._element)
end

function MissionScriptEditor:get_on_executed_units()
    self._on_executed_units = {}
	for _, u in pairs(self._element.values.on_executed) do
		if self:GetPart("mission"):get_element_unit(u.id) then
			table.insert(self._on_executed_units, self:GetPart("mission"):get_element_unit(u.id))
		end
		if u.delay_rand == 0 then u.delay_rand = nil end
	end
end

function MissionScriptEditor:_build_panel()
	self:_create_panel()
end

function MissionScriptEditor:_create_panel()
	if alive(self._main_group) then
		return
	end
	self._holder:ClearItems()

	local SE = self:GetPart("static")
	SE:show_help(ClassClbk(self, "open_wiki"))
	self._main_group = self._holder:group("Main", {align_method = "grid"})
	local quick_buttons = self._holder:group("QuickActions", {align_method = "grid"})
	local transform = self._holder:group("Transform")
	local element = self._element.class:gsub("Element", "") .. ""
	self._class_group = self._holder:group(element)
	SE:SetTitle(element)
	quick_buttons:s_btn("Deselect", ClassClbk(self, "deselect_element"))    
	quick_buttons:s_btn("Delete", ClassClbk(SE, "delete_selected_dialog"))
    quick_buttons:s_btn("CreatePrefab", ClassClbk(SE, "add_selection_to_prefabs"))
	quick_buttons:s_btn("Execute", ClassClbk(managers.mission, "execute_element", self._element))
	if self.test_element then
		quick_buttons:s_btn("Test", ClassClbk(self, "test_element"))
		quick_buttons:s_btn("StopTesting", ClassClbk(self, "stop_test_element"))
	end

	self:StringCtrl("editor_name", {group = self._main_group, help = "A name/nickname for the element, it makes it easier to find in the editor", data = self._element})
	self:ColorCtrl("editor_color", {
		group = self._main_group, return_hex = true,
		help = "A unique color for this element for debugging purposes. Uses default if empty.", data = self._element, allow_empty = true, use_alpha = false
	})
	self._main_group:GetToolbar():lbl("ID", {text = "ID "..self._element.id, size_by_text = true, offset = 6})
 	self:ComboCtrl("script", table.map_keys(managers.mission._scripts), {group = self._main_group, data = self._element})
 	self._element.values.position = self._element.values.position or Vector3()
 	self._element.values.rotation = self._element.values.rotation or Rotation()
    local pos = self._element.values.position
    local rot = self._element.values.rotation
	rot = type(rot) == "number" and Rotation() or rot
	SE:build_grab_button(transform)
	transform:Vec3Rot("", ClassClbk(self, "set_element_position"))
    self:update_positions(pos, rot)
    self:NumberCtrl("trigger_times", {help = "Specifies how many times this element can be executed (0 = unlimited times)", group = self._main_group, floats = 0, min = 0})
    self:NumberCtrl("base_delay", {help = "Specifies a base delay that is added to each on executed delay", group = self._main_group, floats = 2, min = 0})
    self:NumberCtrl("base_delay_rand", {help = "Specifies an additional random time to be added to base delay(delay + rand)", group = self._main_group, floats = 2, min = 0, text = "Random Delay"})
 	self:BooleanCtrl("enabled", {help = "Should the element be enabled", group = self._main_group, size_by_text = true})
    self:BooleanCtrl("execute_on_startup", {help = "Should the element execute when game starts", group = self._main_group, size_by_text = true})
	self:BooleanCtrl("debug", {help = "Should display a debug message when this element is executed (Only when the \"Element Executions\" debug option is set to elements with debug flag)", group = self._main_group, size_by_text = true})
	local on_exec = {values = {{name = "Random Delay", key = "delay_rand"}, {name = "Delay", key = "delay"}}, key = "id", orig = {id = 0, delay = 0, delay_rand = 0}}
	if self.ON_EXECUTED_ALTERNATIVES then
		on_exec.orig.alternative = "none"
		local alts = clone(self.ON_EXECUTED_ALTERNATIVES)
		table.insert(alts, "none")
		on_exec.combo_items_func = function() return alts end 
		table.insert(on_exec.values, {name = "Alternative", key = "alternative"})
	end
	self:BuildElementsManage("on_executed", on_exec, nil, ClassClbk(self, "get_on_executed_units"), {
		group = self._main_group,
		help = "This list contains elements that this element will execute.",
		skip_script_check = self.SKIP_SCRIPT_CHECK
	})
	if self.USES_POINT_ORIENTATION then
		local orientation = self._class_group:pan("PointOrientation", {align_method = "grid", offset = 0, full_bg_color = false})
		self:BuildElementsManage("orientation_elements", nil, nil, nil, {group = orientation})
		self:BooleanCtrl("disable_orientation_on_use", {group = orientation, help = "Should the orientation element be disabled after using it", size_by_text = true})
		self:BooleanCtrl("use_orientation_sequenced", {group = orientation, text = "Use sequenced", help = "Pick orientation elements in list order instead of randomly", size_by_text = true})
		orientation:separator()
	end

	if self.INSTANCE_VAR_NAMES then
		self:BuildInstanceVariables()
	end
end

function MissionScriptEditor:open_wiki()
	local url = "https://wiki.modworkshop.net/books/payday-2/page/mission-elements-%28wip%29#bkmrk-"..self._element.class:gsub("Element", ""):lower()
	os.execute('start "" "'..url..'"')
end

function MissionScriptEditor:set_selected_on_executed_element_delay(item)
	local value = self._holder:GetItem("OnExecutedList"):Value()
	if value then
		self._element.values.on_executed[value].delay = item:Value()
		self:update_element()
	end
end

function MissionScriptEditor:update_positions(pos, rot)
	local SE = self:GetPart("static")
	if not pos or not rot then
		return
	end
	SE:SetItemValue("Position", pos)
	SE:SetItemValue("Rotation", rot)
    self:update_element(true)
end

function MissionScriptEditor:add_draw_units(draw)
	draw.update_units = draw.update_units or ClassClbk(self, "update_draw_units", draw)
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
	if not alive(self._unit) then
		return
	end

	self:draw_links(t, dt, self:selected_unit(), self:selected_units())
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

	if self.update_selected then
		self:update_selected(t, dt)
	end
end

function MissionScriptEditor:draw_links(t, dt, selected_unit, selected_units)
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
	if not elements or self.WEIRD_ELEMENTS_VALUE then
		return
	end
	local selected_unit = self:selected_unit()
	for k, id in ipairs(elements) do
		local unit = self:GetPart("mission"):get_element_unit(id)
		if alive(unit) then
			if self:_should_draw_link(selected_unit, unit) then
				local r, g, b = unit:mission_element():get_link_color()
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

function MissionScriptEditor:_should_draw_link(unit)
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

		self._brush:set_color(Color.white)
	    self._brush:center_text(element_unit:position() + dir, text, managers.editor:camera_rotation():x(), -managers.editor:camera_rotation():z())
	    local element_col = element_unit:mission_element()._color
		self._brush:set_color(element_col:contrast())
	    self:draw_link({
	        from_unit = element_unit,
	        to_unit = unit,
	        r = 1,
	        g = 1,
	        b = 1
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
    self:GetPart("static"):build_default_menu()
    self._parent._selected_element = nil
end

function MissionScriptEditor:update_element(position_only, old_script)
	local unit = self:selected_unit()
	if alive(unit) and unit.element then
		unit:set_position(self._element.values.position)
		unit:set_rotation(self._element.values.rotation)
		if self._element.editor_color and self._element.editor_color:len() > 0 then
			local color = Color:from_hex(self._element.editor_color)
			if color ~= unit._color then
				unit:mission_element():set_color(color)
				unit:mission_element():select()
			end
		end
	end
	if not position_only then
		self:get_on_executed_units()
		managers.mission:set_element(self._element, old_script)
		self:GetPart("static"):build_links(self._element.id, BLE.Utils.LinkTypes.Element, self._element)
	end
end

function MissionScriptEditor:set_element_data(item)
	if not item then
		return
	end
	local old_script = self._element.script
	local function set_element_data()
		local data = self:ItemData(item)
		data[item.name] = item.SelectedItem and item:SelectedItem() or item:Value()
		data[item.name] = item.type_name ~= "ColoredTextBox" and tonumber(data[item.name]) or data[item.name]
		if item.name == "base_delay_rand" then
			data[item.name] = data[item.name] > 0 and data[item.name] or nil
		end
		self:update_element(false, old_script)
	end
	if item.name == "script" and item:SelectedItem() ~= old_script then
		BLE.Utils:YesNoQuestion("This will move the element to a different mission script, the id will be changed and all links will be removed!", function()
			set_element_data()
			self:GetPart("mission"):set_elements_vis()
			self:GetItem("ID"):SetText("ID "..self._element.id)
		end)
	else
		set_element_data()
	end
	if item.name == "editor_name" and alive(self._unit) then
		self._unit:mission_element():update_text()
	end
end

function MissionScriptEditor:set_element_position(menu)
	local SE = self:GetPart("static")
	self._element.values.position = self._holder:GetItem("Position"):Value()
	self._element.values.rotation = self._holder:GetItem("Rotation"):Value()
	self:update_element(true)
end

function MissionScriptEditor:BuildUnitsManage(value_name, table_data, update_clbk, opt)
	opt = opt or {}
	local group = opt.group
	local text = opt.text
	opt.group = nil
	local button = (group or self._class_group):button("Manage"..value_name.."List", ClassClbk(self, "OpenUnitsManageDialog", {
		value_name = value_name,
		update_clbk = update_clbk, 
		check_unit = opt.check_unit,
		not_table = opt.not_table,
		units = opt.units,
		single_select = opt.single_select,
		need_name_id = opt.need_name_id,
		combo_free_typing = opt.combo_free_typing,
		ignore_unit_id = opt.ignore_unit_id,
		table_data = table_data
	}), table.merge({text = "Manage "..string.pretty(value_name, true).." List(units)", help = "Decide which units are in this list"}, opt))
	if not group then
		local list = self._main_group:GetItem("OpenManageLists") or self._holder:popup("OpenManageLists", {text = false, size = 20, scrollbar = false, position = function(item)
			item:SetPosition(0,0)
		end})
		list:tb_btn(value_name, button.on_callback, {
			text = text or "Manage "..string.pretty(value_name, true)
		})
	end
	return button
end

function MissionScriptEditor:BuildInstancesManage(value_name, table_data, update_clbk, opt)
	opt = opt or {}
	local group = opt.group
	local text = opt.text
	opt.group = nil
	local button = (group or self._class_group):button("Manage"..value_name.."List", ClassClbk(self, "OpenInstancesManageDialog", {
		value_name = value_name, 
		update_clbk = update_clbk, 
		table_data = table_data
	}), table.merge({text = "Manage "..string.pretty(value_name, true).." List(instances)", help = "Decide which instances are in this list"}, opt))
	if not group then
		local list = self._main_group:GetItem("OpenManageLists") or self._holder:popup("OpenManageLists", {text = false, size = 20, scrollbar = false, position = function(item)
			item:SetPosition(0,0)
		end})
		list:tb_btn(value_name, button.on_callback, {
			text = text or "Manage "..string.pretty(value_name, true)
		})
	end
	return button
end

function MissionScriptEditor:BuildElementsManage(value_name, table_data, classes, update_clbk, opt)
	opt = opt or {}
	local group = opt.group
	local text = opt.text
	opt.group = nil
	local button = (group or self._class_group):button("Manage"..value_name.."List", ClassClbk(self, "OpenElementsManageDialog", {
		value_name = value_name,
		skip_script_check = opt.skip_script_check,
		update_clbk = update_clbk,
		single_select = opt.single_select,
		not_table = opt.not_table,
		table_data = table_data,
		classes = classes,
		nil_on_empty = opt.nil_on_empty
	}), table.merge({text = "Manage "..string.pretty(value_name, true).." List(elements)", help = "Decide which elements are in this list"}, opt))
	if not group then
		local list = self._holder:GetItem("OpenManageLists") or self._holder:popup("OpenManageLists", {text = false, size = 20, scrollbar = false, position = function(item)
			item:SetPosition(0,0)
		end})
		list:tb_btn(value_name, button.on_callback, {
			text = text or "Manage "..string.pretty(value_name, true)
		})
	end
	return button
end

function MissionScriptEditor:open_managed_list()
	local list = self._holder:GetItem("OpenManageLists")
	if not list then
		return
	end
	if #list:Items() > 1 then
		if list.opened then
			list:Close()
		else
			list:Open()
			list._popup_menu:set_position(managers.mouse_pointer._mouse:position())
		end
	else
		list:Items()[1]:RunCallback()
	end
end

function MissionScriptEditor:open_on_executed_list()
	local list = self._holder:GetItem("Manageon_executedList")
	if list then
		list:RunCallback()
	end
end

function MissionScriptEditor:BuildInstanceVariables()
	local options = {}
	local elements = self:GetPart("mission"):units()
	local has_params = false
	for _, unit in pairs(elements) do
        local element_unit = unit:mission_element()
        if element_unit and element_unit.element.class == "ElementInstanceParams" then
			for _, param in ipairs(element_unit.element.values.params) do
				options[param.type] = options[param.type] or {"not_used"}
				table.insert(options[param.type], param.var_name)
				has_params = true
			end
        end
    end

	if not has_params then
		return
	end

	self._instance_group = self._holder:group("Instance Variables")
	for _, data in ipairs(self.INSTANCE_VAR_NAMES) do
		local opt = self:BasicCtrlInit(data.value)
		local value = self._element.values.instance_var_names and self._element.values.instance_var_names[data.value] or "not_used"
		local items = options[data.type] or {"not_used"}
		self._instance_group:combobox(data.value, ClassClbk(self, "set_instance_var_name"), items, table.get_key(items, value))
	end
end

function MissionScriptEditor:set_instance_var_name(item)
	local value = item:SelectedItem()
	value = value ~= "not_used" and value or nil
	self._element.values.instance_var_names = self._element.values.instance_var_names or {}
	self._element.values.instance_var_names[item:Name()] = value
	self._element.values.instance_var_names = next(self._element.values.instance_var_names) and self._element.values.instance_var_names or nil
	self:update_element(true)
end

function MissionScriptEditor:add_selected_units(value_name, clbk)
	for k, unit in pairs(self:GetPart("static")._selected_units) do
		if unit:unit_data() and not table.has(self._element.values[value_name], unit:unit_data().unit_id) then
			table.insert(self._element.values[value_name], unit:unit_data().unit_id)
		end
	end
    if clbk then
        clbk()
    end
end

function MissionScriptEditor:remove_selected_units(value_name, clbk)
	for k, unit in pairs(self:GetPart("static")._selected_units) do
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
	local tdata = params.table_data
    for i, data in pairs(final_selected_list) do
        local id
        local values
        if type(data) == "table" then
            local unit = data.unit
            local element = data.element
            local instance = data.instance
            id = (unit and (params.need_name_id and unit:unit_data().name_id or unit:unit_data().unit_id)) or instance or element and element.id
			values = data.values
		else
            id = data
		end
        if tdata then
			local add = data.orig_tbl
            if not add then
				add = clone(tdata.orig)
				add[tdata.key] = id
            end
			if values and tdata.values then
				for i, value in pairs(tdata.values) do
					add[value.key] = values[i]
				end
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

	if params.nil_on_empty and table.size(self._element.values[params.value_name]) == 0 then
		self._element.values[params.value_name] = nil
	end

    if params.update_clbk then
        params.update_clbk(params.value_name)
	end
	self:update_element()
end

function MissionScriptEditor:OpenElementsManageDialog(params)
	local elements = {}
	for _, mission in pairs(managers.mission._missions) do
        for name, script in pairs(mission) do
            if script.elements and (params.skip_script_check or name == self._element.script) then
                for _, element in pairs(script.elements) do
                    if element.id ~= self._element.id then
						table.insert(elements, element)
					end
				end
			end
		end
	end

	self:OpenManageListDialog(params, elements, 
		function(element)
			return element.editor_name .. " - " .. element.class:gsub("Element", "") .. " [" .. element.id .."]"
		end,
		function(element)
			return not params.classes or table.contains(params.classes, element.class)
		end
	)
end

function MissionScriptEditor:OpenUnitsManageDialog(params)
	local units = World:find_units_quick("disabled", "all")
	units = table.filter_list(units, function(unit)
		local ud = unit:unit_data()
		if not ud then
			return false
		end
		return not ud.instance and (params.ignore_unit_id or ud.unit_id ~= 0) and (not params.check_unit or params.check_unit(unit))
	end)
	local static = self:part("static")
	self:OpenManageListDialog(params, units,
		function(unit)
			local ud = unit:unit_data()
			local groups = static:get_groups_from_unit(unit)
			local groups_str
			if next(groups) then
				groups_str = "Groups: "
				for i, grp in ipairs(groups) do
					groups_str = groups_str .. grp.name .. (i < #groups and "|" or "")
				end
			end

			return string.format("%s [%s] %s", ud.name_id, ud.unit_id or "", groups_str or "")
		end,
		function(unit)
			return (not params.units or table.contains(params.units, unit:unit_data().name))
		end
	)
end

function MissionScriptEditor:OpenInstancesManageDialog(params)
	self:OpenManageListDialog(params, managers.world_instance:instance_names_by_script(self._element.script), 
		function(instance) return instance end,
		function(element) return true end
	)
end

local UNIT = "unit"
local INSTANCE = "instance"
local ELEMENT = "element"

function MissionScriptEditor:OpenManageListDialog(params, objects, name_func, check_object)
	local selected_list = {}
	local list = {}
	local current_list = self._element.values[params.value_name] or {}
	current_list = type(current_list) ~= "table" and {current_list} or current_list
	local tdata = params.table_data
	if tdata and tdata.values_name then
		tdata.values = {{name = tdata.values_name, key = tdata.value_key}}
	end
	local is_unit
	local is_element
	local obj = objects[1]
	local object_id_key
	if obj and type(obj) ~= "string" then
		if obj.unit_data then
			is_unit = true
		elseif obj.script then
			is_element = true
		end
	end
	for k, object in pairs(objects) do
		if (not is_unit or alive(object)) then
			local id
			local object_key = UNIT
			if is_element then
				object_key = ELEMENT
				id = object.id
			elseif is_unit then
				if params.need_name_id then
					id = object:unit_data().name_id
				else
					id = object:unit_data().unit_id
				end
			else
				id = object
				object_key = INSTANCE
			end
			local entry = {name = name_func(object), [object_key] = object, _index = 1}

			--Adding units which are selected.
			if tdata then
				for i, element_v in pairs(current_list) do
					if type(element_v) == "table" and element_v[tdata.key] == id then
						if #tdata.values > 0 then
							entry.values = {}
						end
						for _, value in pairs(tdata.values) do
							table.insert(entry.values, element_v[value.key] or tdata.orig[value.key] or tdata.default_value)
						end
						entry.orig_tbl = element_v
						entry._index = i
						table.insert(selected_list, clone(entry))
					end
				end
			elseif table.contains(current_list, id) then
				entry._index = table.get_key(current_list, id)
				table.insert(selected_list, entry)
			end

			--Adding all units to be selectable.
			if check_object(object) then
				if tdata and tdata.values then
					if #tdata.values > 0 then
						entry.values = {}
					end
					for _, value in pairs(tdata.values) do
						table.insert(entry.values, tdata.orig[value.key] or tdata.default_value)
					end
				end
				entry.orig_tbl = nil
				table.insert(list, entry)
			end
	 	end
	end

	table.sort(selected_list, function(a,b)
		return a._index < b._index
	end)
	table.sort(list, function(a,b)
		return a._index < b._index
	end)

	BLE.SelectDialogValue:Show({
	    selected_list = selected_list,
		list = list,
		entry_values = tdata and tdata.values,
		combo_items_func = tdata and tdata.combo_items_func,
		allow_multi_insert = NotNil(params.allow_multi_insert, true),
		need_name_id = params.need_name_id,
		single_select = params.single_select,
		combo_free_typing = NotNil(params.combo_free_typing, true),
		not_table = params.not_table,
		callback = params.callback or ClassClbk(self, "ManageElementIdsClbk", params)
	})
	self:update_element()
end

function MissionScriptEditor:BasicCtrlInit(value_name, opt)
	opt = opt or {}
	opt.group = opt.group or self._class_group
	opt.text = opt.text or string.pretty(value_name, true)
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
	opt.text = text
    return (opt.group or self._class_group):divider(text, opt)
end

function MissionScriptEditor:ListSelectorOpen(params)
    BLE.SelectDialog:Show({
        selected_list = params.selected_list,
        list = params.list,
        callback = params.callback or function(list) 
 			params.data[params.value_name] = #list > 0 and list or nil
        end
    })
end

function MissionScriptEditor:ListSelector(value_name, list, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	local data = self:ItemData(opt)
	return (opt.group or self._holder):button(value_name, ClassClbk(self, "ListSelectorOpen", {value_name = value_name, selected_list = data[value_name], list = list, data = data}), opt)
end

function MissionScriptEditor:NumberCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return (opt.group or self._holder):numberbox(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:BooleanCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return (opt.group or self._holder):tickbox(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:ColorCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return (opt.group or self._holder):colorbox(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:StringCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
    return (opt.group or self._holder):textbox(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:ComboCtrl(value_name, items, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	local value = self:ItemData(opt)[value_name]
	return (opt.group or self._holder):combobox(value_name, ClassClbk(self, "set_element_data"), items, opt and opt.free_typing and value or table.get_key(items, value), opt)
end

function MissionScriptEditor:FSPathCtrl(value_name, typ, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	return (opt.group or self._holder):fs_pathbox(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], typ, opt)
end

function MissionScriptEditor:PathCtrl(value_name, typ, check_match, check_not_match, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	opt.check = function(unit)
		if unit:match("husk") then
			return false
		end
		local check_match_tbl = type(check_match) == "table" and check_match or {check_match}
		local check_not_match_tbl = type(check_not_match) == "table" and check_not_match or {check_not_match}
		for _, check in pairs(check_match_tbl) do
			if not unit:match(check) then
				return false
			end
		end
		for _, check in pairs(check_not_match_tbl) do
			if unit:match(check) then
				return false
			end
		end
		return true
	end
	opt.not_close = true
    return (opt.group or self._holder):pathbox(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], typ, opt)
end

function MissionScriptEditor:Vector3Ctrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	local value = self:ItemData(opt)[value_name]
	return (opt.group or self._holder):Vector3(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:RotationCtrl(value_name, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	local value = self:ItemData(opt)[value_name]
	return (opt.group or self._holder):Rotation(value_name, ClassClbk(self, "set_element_data"), self:ItemData(opt)[value_name], opt)
end

function MissionScriptEditor:Info(text, color, opt)
	opt = opt or {}
	opt.group = opt.group or self._class_group
	return (opt.group or self._holder):info(text, color)
end

function MissionScriptEditor:Alert(text, color, opt)
	opt = opt or {}
	opt.group = opt.group or self._class_group
	return (opt.group or self._holder):alert(text, color)
end

-- TODO: maybe add linking to other stuff like units with sequence elements
-- TODO: Allow hot key to be changed
function MissionScriptEditor:link_selection(unit)
	if alive(unit) and unit:mission_element() then
		local on_executed = self._element.values.on_executed
		local element = unit:mission_element().element

		--Is unit already linked? Unlink.
		for i, u in pairs(self._element.values.on_executed) do
			if u.id == element.id then
				table.remove(on_executed, i)
				self:update_element()
				return
			end
		end

		-- No? Add it!
		table.insert(on_executed, {id = element.id, delay = 0})

		self:update_element()
	end
end

function MissionScriptEditor:link_managed(unit)
	if alive(unit) then
		local values = self._element.values
		if values.unit_ids and unit:unit_data() then
			local ud = unit:unit_data()
			self:AddOrRemoveManaged("unit_ids", ud.unit_id)
		elseif values.elements and unit:mission_element() then
			local element = unit:mission_element().element
			if self.ELEMENT_FILTER and not table.contains(self.ELEMENT_FILTER, element.class) then
				return
			end
			self:AddOrRemoveManaged("elements", element.id)
		elseif self.USES_POINT_ORIENTATION and unit:mission_element() then
			local element = unit:mission_element().element
			self:AddOrRemoveManaged("orientation_elements", element.id)
		end
	end
end

function MissionScriptEditor:AddOrRemoveManaged(value_name, data, params, clbk)
	params = params or {}
	local tdata
	local id
	if type(data) == "table" then
		local unit = data.unit
		local element = data.element
		local instance = data.instance
		id = (unit and (params.need_name_id and unit:unit_data().name_id or unit:unit_data().unit_id)) or instance or (element and element.id)
		tdata = data
	else
		id = data
	end

	if not params.not_table then
		self._element.values[value_name] = self._element.values[value_name] or {}
		local current_value = self._element.values[value_name]
		local add = id
		if tdata and tdata.orig then
			add = clone(tdata.orig)
			add[tdata.key] = id

			for i, value in ipairs(self._element.values[value_name]) do
				if value[tdata.key] == id then
					add = value
					break
				end

			end
		end

		if table.contains(current_value, add) then
			table.delete(self._element.values[value_name], add)
		else
			table.insert(self._element.values[value_name], add)
		end
	else
		if self._element.values[value_name] == id then
			self._element.values[value_name] = nil
		else
			self._element.values[value_name] = id
		end
	end
	if clbk then clbk(value_name) end
	self:update_element()
end