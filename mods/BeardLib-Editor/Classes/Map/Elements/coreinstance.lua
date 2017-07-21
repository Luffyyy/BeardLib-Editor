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
	if self._type == "input" then
		Application:draw_arrow(self._unit:position(), managers.world_instance:get_instance_data_by_name(instance_name).position, r, g, b, 0.2)
	else
		Application:draw_arrow(managers.world_instance:get_instance_data_by_name(instance_name).position, self._unit:position(), r, g, b, 0.2)
	end
end

function EditorInstanceInputEvent:update(t, dt, instance_name)
	local r, g, b = self._unit:mission_element()._color:unpack()
	for _, data in ipairs(self._element.values.event_list) do
		self:_draw_instance_link(data.instance)
	end
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
		EditorInstanceInputEvent._draw_instance_link(self, self._element.values.instance)
	end
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
		EditorInstanceInputEvent._draw_instance_link(self, self._element.values.instance)
	end
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
    	self:Divider("No instance selected", {color = false, group = self._instance_menu})
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
        local use = self:Toggle("use_"..name, callback(self, self, "_on_gui_toggle_use"), self._element.values.params[name] and true or false, {
            text = "Using Variable", value_ctrlr = value_ctrlr, var_name = name, help = "Toggle use of variable on/off", group = self._instance_menu
        })
        value_ctrlr:SetEnabled(use:Value())
    end
    if #self._instance_menu._my_items == 0 then
    	self:Divider("No parameters", {color = false, group = self._instance_menu})
    end
end

function EditorInstanceSetParams:_on_gui_toggle_use(menu, item)
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
	self._instance_menu = self:DivGroup("Instance Params")
	self:_build_from_params()
end

function EditorInstanceSetParams:set_element_data(menu, item, ...)
	if item.name == "instance" then
		if item:SelectedItem() == "none" then
			item:SetSelectedItem()
		end
		self:_check_change_instance(item:SelectedItem())
		self:_build_from_params()
		return
	end
	EditorInstanceSetParams.super.set_element_data(self, menu, item, ...)
end