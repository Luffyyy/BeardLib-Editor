MissionEditor = MissionEditor or class(EditorPart)
function MissionEditor:init(parent, menu)
    local elements = file.GetFiles(BeardLibEditor.ElementsDir)
    if not elements then
        BeardLibEditor:log("[ERROR] MissionEditor class has failed to initialize[Missing elements]")
        return
    end
    for _, file in pairs(elements) do
        dofile(BeardLibEditor.ElementsDir .. file)
    end    
    self._units = {}
    self._parent = parent
    self._triggers = {}
end

function MissionEditor:units()
    return self._units
end

function MissionEditor:set_elements_vis()
    local enabled = self:Value("ShowElements")
    for _, unit in pairs(self:units()) do
        if unit:mission_element() then
            unit:mission_element():set_enabled(enabled)
            unit:set_enabled(enabled)
        end
    end
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
    local enabled = self:Value("ShowElements")
    unit:mission_element():set_enabled(enabled)
    unit:set_enabled(enabled)
end

function MissionEditor:remove_element_unit(unit)
    table.delete(self._units, unit)
end

function MissionEditor:get_editor_class(c)
    local clss = rawget(_G, c:gsub("Element", "Editor"))
    if not clss then
        BeardLibEditor:log("[Warning] Element class %s has no editor class(Report this)", c)
    end
    return clss
end

function MissionEditor:set_element(element)
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
        end
    else
        BeardLibEditor:log("[ERROR] Nil element!")
    end
end

function MissionEditor:add_element(name, add_to_selection, old_element)
    local clss = self:get_editor_class(name) 
    if clss then
        self:Manager("static"):set_selected_unit(clss:init(nil, old_element), add_to_selection)
    end
end
 
function MissionEditor:update(t, dt)
    self.super.update(self, t, dt)
    if self._parent:selected_unit() and self._parent:selected_unit().mission_element and self._current_script and self._current_script.update then
        self._current_script:update(t, dt)
    end   
end