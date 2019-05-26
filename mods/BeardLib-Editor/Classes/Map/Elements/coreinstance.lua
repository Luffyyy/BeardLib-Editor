EditorInstanceInput = EditorInstanceInput or class(MissionScriptEditor)
EditorInstanceInput.SAVE_UNIT_POSITION = false
EditorInstanceInput.SAVE_UNIT_ROTATION = false
function EditorInstanceInput:create_element()
	EditorInstanceInput.super.create_element(self)
	self._element.class = "ElementInstanceInput"
	self._element.module = "CoreElementInstance"
	self._element.values.event = "none"
end

function EditorInstanceInput:_build_panel()
	self:_create_panel()
	self:StringCtrl("event")
end

EditorInstanceOutput = EditorInstanceOutput or class(EditorInstanceInput)
function EditorInstanceOutput:create_element(...)
	EditorInstanceOutput.super.create_element(self, ...)
	self._element.class = "ElementInstanceOutput"
	self._element.module = "CoreElementInstance"
end

EditorInstanceInputEvent = EditorInstanceInputEvent or class(MissionScriptEditor)
EditorInstanceInputEvent.SAVE_UNIT_POSITION = false
EditorInstanceInputEvent.SAVE_UNIT_ROTATION = false
function EditorInstanceInputEvent:init(...)
	local unit = EditorInstanceInputEvent.super.init(self, ...)
	self._type = "input"
	return unit
end

function EditorInstanceInputEvent:create_element()
	EditorInstanceInputEvent.super.create_element(self)
	self._element.class = "ElementInstanceInputEvent"
	self._element.module = "CoreElementInstance"
	self._element.values.event_list = {}
end

function EditorInstanceInputEvent:_draw_instance_link(instance_name)
	local instance = managers.world_instance:get_instance_data_by_name(instance_name)
	if type(instance) ~= "table" then
		return false
	end

	if self._type == "input" then
		Application:draw_arrow(self._unit:position(), instance.position, r, g, b, 0.2)
	else
		Application:draw_arrow(instance.position, self._unit:position(), r, g, b, 0.2)
	end
	return true
end

function EditorInstanceInputEvent:update(t, dt, instance_name)
	local r, g, b = self._unit:mission_element()._color:unpack()
	for i, data in ipairs(self._element.values.event_list) do
		if not self:_draw_instance_link(data.instance) then
			table.remove(self._element.values.event_list, i)
		end
	end
	EditorInstanceInputEvent.super.update(self, t, dt)
end

function EditorInstanceInputEvent:_get_events(instance_name)
	if self._type == "input" then
		return managers.world_instance:get_mission_inputs_by_name(instance_name)
	else
		return managers.world_instance:get_mission_outputs_by_name(instance_name)
	end
end

function EditorInstanceInputEvent:_build_panel()
    self:_create_panel()
    self:BuildInstancesManage("event_list", {values_name = "Event", value_key = "event", default_value = "none", key = "instance", orig = {instance = "", event = "none"}, combo_items_func = function(name)
        return self:_get_events(name)
    end})
end

EditorInstanceOutputEvent = EditorInstanceOutputEvent or class(EditorInstanceInputEvent)
function EditorInstanceOutputEvent:init(...)
	local unit = EditorInstanceOutputEvent.super.init(self, ...)
	self._type = "output"
	return unit
end

function EditorInstanceOutputEvent:create_element()
	EditorInstanceOutputEvent.super.create_element(self)
	self._element.class = "ElementInstanceOutputEvent"
	self._element.module = "CoreElementInstance"
end

EditorInstancePoint = EditorInstancePoint or class(MissionScriptEditor)
function EditorInstancePoint:create_element()
	EditorInstancePoint.super.create_element(self)
	self._element.class = "ElementInstancePoint"
	self._element.module = "CoreElementInstance"
end

function EditorInstancePoint:update(t, dt)
	if self._element.values.instance then
		if not EditorInstanceInputEvent._draw_instance_link(self, self._element.values.instance) then
			self._element.values.instance = nil
		end
	end
	EditorInstancePoint.super.update(self, t, dt)
end

function EditorInstancePoint:external_change_instance(instance)
	self._element.values.instance = instance
end

function EditorInstancePoint:_build_panel()
	self:_create_panel()
	local names = {}
	for _, name in ipairs(managers.world_instance:instance_names_by_script(self._element.script)) do
		if managers.world_instance:get_instance_data_by_name(name).mission_placed then
			table.insert(names, name)
		end
	end
	self:ComboCtrl("instance", names)
end

EditorInstanceSetParams = EditorInstanceSetParams or class(MissionScriptEditor)
function EditorInstanceSetParams:create_element()
	EditorInstanceSetParams.super.create_element(self)
	self._element.class = "ElementInstanceSetParams"
	self._element.module = "CoreElementInstance"
	self._element.values.params = {}
end

function EditorInstanceSetParams:update(t, dt)
	if self._element.values.instance then
		if not EditorInstanceInputEvent._draw_instance_link(self, self._element.values.instance) then
			self._element.values.instance = nil
		end
	end
	EditorInstanceSetParams.super.update(self, t, dt)
end

function EditorInstanceSetParams:_check_change_instance(new_instance)
	if not self._element.values.instance or not next(self._element.values.params) then
		self._element.values.instance = new_instance
		return
	end
	local new_folder = managers.world_instance:get_instance_data_by_name(new_instance).folder
	local folder = managers.world_instance:get_instance_data_by_name(self._element.values.instance).folder
	if new_folder == folder then
		self._element.values.instance = new_instance
		return
	end
	BeardLibEditor.Utils:YesNoQuestion("This will change the instance from " .. self._element.values.instance .. " to " .. new_instance .. "and will reset the params", function()
		self._element.values.params = {}
		self._element.values.instance = new_instance
		self:_build_from_params()
	end,
	function() self:GetItem("instance"):SetSelectedItem(self._element.values.instance) end)
end

function EditorInstanceSetParams:_build_from_params()
    self._instance_menu:ClearItems()
    if not self._element.values.instance then
    	self._instance_menu:divider("No instance selected", {color = false})
        return
    end
    local params = managers.world_instance:get_instance_params_by_name(self._element.values.instance)
    for _, data in ipairs(params) do
        local value_ctrlr
        local name = data.var_name
        local opt = {data = self._element.values.params, group = self._instance_menu}
        if data.type == "number" then
            value_ctrlr = self:NumberCtrl(name, opt)
        elseif data.type == "enemy" then
            value_ctrlr = self:PathCtrl(name, "unit", 12)
        elseif data.type == "civilian" then
        	value_ctrlr = self:PathCtrl(name, "unit", 21)
        elseif data.type == "objective" then
            value_ctrlr = self:ComboCtrl(name, managers.objectives:objectives_by_name(), opt)
        elseif data.type == "enemy_spawn_action" then
            value_ctrlr = self:ComboCtrl(name, clone(CopActionAct._act_redirects.enemy_spawn), opt)
        elseif data.type == "civilian_spawn_state" then
            value_ctrlr = self:ComboCtrl(name, clone(CopActionAct._act_redirects.civilian_spawn), opt)
        elseif data.type == "special_objective_action" then
            value_ctrlr = self:ComboCtrl(name, clone(CopActionAct._act_redirects.SO), opt)
        end
        local use = self._instance_menu:tickbox("use_"..name, ClassClbk(self, "_on_gui_toggle_use"), self._element.values.params[name] and true or false, {
            text = "Using Variable", value_ctrlr = value_ctrlr, var_name = name, help = "Toggle use of variable on/off"
        })
        value_ctrlr:SetEnabled(use:Value())
    end
    if #self._instance_menu._my_items == 0 then
    	self._instance_menu:divider("No parameters", {color = false})
    end
end

function EditorInstanceSetParams:_on_gui_toggle_use(item)
    local use = item:Value()
    item.value_ctrlr:SetEnabled(use)
    local orig_value = item.value_ctrlr:Value()
    self._element.values.params[item.var_name] = use and (tonumber(orig_value) or orig_value) or nil
end

function EditorInstanceSetParams:_build_panel()
	self:_create_panel()
	local names = {}
	for _, name in ipairs(managers.world_instance:instance_names_by_script(self._element.script)) do
		table.insert(names, name)
	end
	table.insert(names, "none")
	table.sort(names)

	self:ComboCtrl("instance", names)
	self:BooleanCtrl("apply_on_execute")
	self._instance_menu = self:divgroup("Instance Params")
	self:_build_from_params()
end

function EditorInstanceSetParams:set_element_data(item, ...)
	if item.name == "instance" then
		if item:SelectedItem() == "none" then
			item:SetSelectedItem()
		end
		self:_check_change_instance(item:SelectedItem())
		self:_build_from_params()
		return
	end
	EditorInstanceSetParams.super.set_element_data(self, item, ...)
end

EditorInstanceParams = EditorInstanceParams or class(MissionScriptEditor)
EditorInstanceParams.TYPES = {"number","enemy","objective","civilian","enemy_spawn_action","civilian_spawn_state","special_objective_action"}

function EditorInstanceParams:create_element(...)
	EditorInstanceParams.super.create_element(self)
	self._element.class = "ElementInstanceParams"
	self._element.module = "CoreElementInstance"

	self._element.values.params = {}
end

function EditorInstanceParams:_add_var_dialog(text)
	local typ
	BLE.InputDialog:Show(
        {
            title = "Add Variable",
			text = text or "",
			create_items = function(menu)
				typ = menu:combobox("Type", nil, self.TYPES)
			end,
            callback = function(name)
				if not name or name == "" then
					BLE.Dialog:Show({title = "ERROR!", message = "Variable name cannot be empty!", callback = ClassClbk(self, "_add_var_dialog", name)})
                    return
				end
				for _, data in ipairs(self._element.values.params) do
					if data.var_name == name then
						BLE.Dialog:Show({title = "ERROR!", message = "Variable name already exists!", callback = ClassClbk(self, "_add_var_dialog", name)})
						return
					end
				end
				
				local type = typ:SelectedItem()
				if not type then
					BLE.Dialog:Show({title = "ERROR!", message = "Variables must have a type!", callback = ClassClbk(self, "_add_var_dialog", name)})
					return
				end
			
				local default_value = nil
			
				if type == "number" then
					default_value = 0
				elseif type == "enemy" then
					default_value = "units/payday2/characters/ene_swat_1/ene_swat_1"
				elseif type == "civilian" then
					default_value = ""
				elseif type == "objective" then
					default_value = managers.objectives:objectives_by_name()[1]
				elseif type == "enemy_spawn_action" then
					default_value = clone(CopActionAct._act_redirects.enemy_spawn)[1]
				elseif type == "civilian_spawn_state" then
					default_value = CopActionAct._act_redirects.civilian_spawn[1]
				elseif type == "special_objective_action" then
					default_value = CopActionAct._act_redirects.SO[1]
				end
			
				local data = {
					var_name = name,
					type = type,
					default_value = default_value
				}
			
				table.insert(self._element.values.params, data)
				self:_build_var_panel(data)
            end
        }
    )
end

function EditorInstanceParams:_remove_var_name(var_name, item)
	for i, data in ipairs(self._element.values.params) do
		if data.var_name == var_name then
			table.remove(self._element.values.params, i)

			if self._panels[i] then
				local rem_data = table.remove(self._panels, i)
				rem_data.item:Destroy()
				item:Destroy()
			end

			return
		end
	end
end

function EditorInstanceParams:_build_var_panel(data)
	self._panels = self._panels or {}

	if data.type == "number" then
		self:_build_number(data)
	elseif data.type == "enemy" then
		self:_build_pathbox(data, 12)
	elseif data.type == "civilian" then
		self:_build_pathbox(data, 21)
	elseif data.type == "objective" then
		self:_build_combobox(data, managers.objectives:objectives_by_name())
	elseif data.type == "enemy_spawn_action" then
		self:_build_combobox(data, clone(CopActionAct._act_redirects.enemy_spawn))
	elseif data.type == "civilian_spawn_state" then
		self:_build_combobox(data, clone(CopActionAct._act_redirects.civilian_spawn))
	elseif data.type == "special_objective_action" then
		self:_build_combobox(data, clone(CopActionAct._act_redirects.SO))
	end
end

function EditorInstanceParams:_build_remove_var(item)
	self._pan:tb_imgbtn("RemoveVariable", ClassClbk(self, "_remove_var_name", item.name), nil, BLE.Utils:GetIcon("cross"), {
		offset = item.offset, size = 22
	})
	table.insert(self._panels, {var_name = item.var_name, item = item})
end

function EditorInstanceParams:_build_number(data)
	self:_build_remove_var(self._pan:numberbox(data.var_name, ClassClbk(self, "_set_default_var_name", data), data.default_value, {
		floats = 0, help = "Set a default number variable.", shrink_width = 0.91
	}))
end

function EditorInstanceParams:_build_combobox(data, options)
	self:_build_remove_var(self._pan:combobox(data.var_name, ClassClbk(self, "_set_default_var_name", data), options, data.default_value, {
		shrink_width = 0.91, control_slice = 0.65
	}))
end

function EditorInstanceParams:_build_pathbox(data, slot)
	self:_build_remove_var(self._pan:pathbox(data.var_name, ClassClbk(self, "_set_default_var_name", data), data.default_value, "unit", {
		slot = slot, shrink_width = 0.91
	}))
end


function EditorInstanceParams:_set_default_var_name(data, item)
	local value = item:Value()
	data.default_value = tonumber(value) or value
end

function EditorInstanceParams:_build_panel()
	self:_create_panel()
	self._class_group:button("AddVariable", ClassClbk(self, "_add_var_dialog", false), nil, BLE.Utils:GetIcon("plus"))
	self._pan = self._class_group:pan("Params", {align_method = "grid"})
	for _, data in ipairs(self._element.values.params) do
		self:_build_var_panel(data)
	end
end