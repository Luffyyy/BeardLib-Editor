MissionEditor = MissionEditor or class(EditorPart)
function MissionEditor:units() return self._units end
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

function MissionEditor:set_elements_vis()
    local enabled = self:Value("ShowElements") and not Global.editor_safe_mode
    local draw_script = self:Value("DrawOnlyElementsOfCurrentScript")
    for _, unit in pairs(self:units()) do
        local element_unit = unit:mission_element()
        if element_unit then
            element_unit:set_enabled(enabled and (not draw_script or element_unit.element.script == self._parent._current_script))
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
    unit:mission_element():set_enabled(false)
end

function MissionEditor:remove_element_unit(unit)
    table.delete(self._units, unit)
end

function MissionEditor:get_editor_class(c)
    local clss = rawget(_G, c:gsub("Element", "Editor"))
    if not clss then
        EditorActionMessage = EditorActionMessage or class(MissionScriptEditor)
        BeardLibEditor:log("[Warning] Element class %s has no editor class(Report this)", c)
    end
    return clss
end

function MissionEditor:alert_missing_element_editor(c)
    BeardLibEditor.Utils:QuickDialog({title = "Well that's embarrassing..", no = "No", message = "Seems like there is no editor class for this element, report this to us?"}, {{"Yes", function()
        local url = "https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues/new?labels[]=bug&title=No editor class for the element "..c:gsub("Element", "")
        os.execute('start "" "'..url..'"')
    end}})
end

function MissionEditor:set_element(element)
    self:Manager("static")._built_multi = false
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
        self:alert_missing_element_editor(element.class)
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

function MissionEditor:add_element(name, add_to_selection, old_element)
    local clss = self:get_editor_class(name) 
    if clss then
        local unit = clss:init(nil, old_element)
        if unit then
            self:set_elements_vis()
            self:Manager("static"):set_selected_unit(unit, add_to_selection)
        end
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