MissionEditor = MissionEditor or class(EditorPart)
function MissionEditor:units() return self._units end
function MissionEditor:init(parent, menu)
    local elements = file.GetFiles(BLE.ElementsDir)
    if not elements then
        BLE:log("[ERROR] MissionEditor class has failed to initialize[Missing elements]")
        return
    end
    for _, file in pairs(elements) do
        dofile(BLE.ElementsDir .. file)
    end
    for _, element in pairs(BLE._config.MissionElements) do
        local class_name = element:gsub('Element', 'Editor')
        if not rawget(_G, class_name) and not rawget(_G, element.."Editor") then
            local c = class(MissionScriptEditor)
            c.CLASS = element
            rawset(_G, class_name, c)
        end
    end
    self._units = {}
    self._parent = parent
    self._triggers = {}
    self._name_ids = {}
end

function MissionEditor:enable()
    MissionEditor.super.enable(self)
    self:bind_opt("OpenManageList", ClassClbk(self, "open_managed_list"))
    self:bind_opt("OpenOnExecutedList", ClassClbk(self, "open_on_executed_list"))
end

function MissionEditor:set_elements_vis(vis)
    local enabled = NotNil(vis, self:Val("ShowElements") and not Global.editor_safe_mode)
    local draw_script = self:Val("DrawOnlyElementsOfCurrentScript")
    for _, unit in pairs(self:units()) do
        local element_unit = alive(unit) and unit:mission_element()
        if element_unit then
            element_unit:set_enabled(enabled and (not draw_script or element_unit.element.script == self._parent._current_script))
        end
    end
end

function MissionEditor:get_name_id(clss, name)
    local class_name = self:make_class_name(clss)
    self._name_ids[class_name] = self._name_ids[class_name] or {}
    local t = self._name_ids[class_name]
    local start_number = 1
	if name then
		local sub_name = name
		for i = string.len(name), 0, -1 do
			local sub = string.sub(name, i, string.len(name))
			sub_name = string.sub(name, 0, i)
			if tonumber(sub) and tonumber(sub) < 10000 then
				start_number = tonumber(sub)
			else
				break
			end
		end
		name = sub_name
	else
        name = class_name .. '_'
    end

	for i = start_number, 10000 do
		i = (i < 10 and "00" or i < 100 and "0" or "") .. i
		local name_id = name .. i
        if not t[name_id] then --Saved in MissionManager.
			return name_id
		end
	end
end

function MissionEditor:make_class_name(clss)
    return string.underscore_name(clss:gsub("Element", ""))
end

function MissionEditor:remove_name_id(clss, name_id)
    local class_name = self:make_class_name(clss)
	if self._name_ids[class_name] and self._name_ids[class_name][name_id] then
		self._name_ids[class_name][name_id] = self._name_ids[class_name][name_id] - 1
		if self._name_ids[class_name][name_id] == 0 then
			self._name_ids[class_name][name_id] = nil
		end
	end
end

function MissionEditor:set_name_id(clss, name_id, old_name_id)
    local class_name = self:make_class_name(clss)
    if old_name_id then
        self:remove_name_id(clss, old_name_id)
    end

    self._name_ids[class_name] = self._name_ids[class_name] or {}
    self._name_ids[class_name][name_id] = (self._name_ids[class_name][name_id] or 0) + 1
end

function MissionEditor:remove_script()
    if self._current_script then
        if self._current_script.destroy then
            self._current_script:destroy()
        end
        self._current_script = nil
    end
end

function MissionEditor:get_element_unit(id)
    for _, unit in pairs(self._units) do
        if unit:mission_element().element.id == id then
            return unit
        end
    end
end

function MissionEditor:add_element_unit(unit)
    table.insert(self._units, unit)
    unit:mission_element():set_enabled(false)
end

function MissionEditor:remove_element_unit(unit)
    table.delete(self._units, unit)
end

function MissionEditor:get_editor_class(c)
    local clss = rawget(_G, c .. "Editor") or rawget(_G, c:gsub("Element", "Editor"))
    if not clss then
        EditorActionMessage = EditorActionMessage or class(MissionScriptEditor)
    end
    return clss
end

function MissionEditor:alert_missing_element_editor(c)
    BLE.Utils:QuickDialog({title = "Well that's embarrassing..", no = "No", message = "Seems like there is no editor class for this element, report this to us?"}, {{"Yes", function()
        local url = "https://github.com/Luffyyy/BeardLib-Editor/issues/new?labels[]=bug&title=No editor class for the element "..c:gsub("Element", "")
        os.execute('start "" "'..url..'"')
    end}})
end

function MissionEditor:set_element(element)
	self:GetPart("static")._built_multi = false
    if element then
        local clss = self:get_editor_class(element.class)
		if clss then
            local script = clss:new(element)
			script._element.class = element.class
			script:work()
            self._current_script = script
            if not self._parent:selected_unit() then
                self._current_script = nil
			end
        else
			self:alert_missing_element_editor(element.class)
        end
    end
end

function MissionEditor:mouse_busy()
    if self._current_script and self._current_script.mouse_busy and self._current_script:mouse_busy() then
        return true
    end
end

function MissionEditor:mouse_pressed(...)
    if self._current_script and self._current_script.mouse_pressed and self._current_script:mouse_pressed(...) then
        return true
    end
end

function MissionEditor:mouse_released(...)
    if self._current_script and self._current_script.mouse_released and self._current_script:mouse_released(...) then
        return true
    end
end

function MissionEditor:open_managed_list()
    if self._current_script and self._current_script.open_managed_list then
        self._current_script:open_managed_list()
    end
end

function MissionEditor:open_on_executed_list()
    if self._current_script and self._current_script.open_on_executed_list then
        self._current_script:open_on_executed_list()
    end
end

function MissionEditor:add_element(name, add_to_selection, old_element, no_select)
    local clss = self:get_editor_class(name)
    if clss then
        if old_element then
            old_element.from_name_id = old_element.editor_name
            old_element.editor_name = nil
        end
        local unit = clss:init(nil, old_element)
        if unit then
			self:set_elements_vis()
			if not no_select then
				self:GetPart("static"):set_selected_unit(unit, add_to_selection)
			end
		end
        self:GetPart("select"):get_menu("element"):add_object(unit:mission_element().element)
		return unit
    else
        self:alert_missing_element_editor(name)
    end
end

function MissionEditor:update(t, dt)
    self.super.update(self, t, dt)
    if self._parent:selected_unit() and self._parent:selected_unit().mission_element and self._current_script and self._current_script.update then
        self._current_script:update(t, dt)
    end
end

function MissionEditor:disabled_update(t, dt)
    if self:Val("ShowElements") and self:Val("VisualizeDisabledElements") then
        unit_disabled = Draw:brush(Color(0.15, 1, 0, 0))

        for _, unit in pairs(self:units()) do
            local element_unit = alive(unit) and unit:mission_element()
            if element_unit and element_unit:visible() and not managers.mission:element_enabled(element_unit.element) and unit:num_bodies() > 0 then
                unit_disabled:body(unit:body(0))
            end
        end
    end
end