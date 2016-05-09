ElementEditor = ElementEditor or class()

function ElementEditor:init(parent, menu)
    local path = BeardLibEditor.ModPath .. "Classes/EditorParts/Elements/"
    dofile(path .. "MissionScriptEditor.lua")
    for _, file in pairs(file.GetFiles(path)) do
        dofile(path .. file)
    end    
    self._parent = parent
    self._trigger_ids = {}
    self._menu = menu:NewMenu({
        name = "selected_element",
        text = "Selected element",
        help = "",
    })
end
function ElementEditor:enabled()
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring("g"), callback(self, self, "KeyGPressed")))
end

function ElementEditor:disabled()
    for _, id in pairs(self._trigger_ids) do
        Input:keyboard():remove_trigger(id)
    end

    self._trigger_ids = {}
end

function ElementEditor:set_element(element, add)
    local element_editor_class = rawget(_G, element.class:gsub("Element", "Editor"))
    local selected_element 
    if element_editor_class then
        local new = element_editor_class:new(element.id and element or nil)    
        if add then 
            new:add_to_mission()
        end
        selected_element = new._element
        new:_build_panel()
        self._parent._menu:SwitchMenu(self._parent._menu:GetItem("selected_element"))    
        self._current_script = new
    end
    self._parent._selected_element = selected_element
    local executors = managers.mission:get_executors_of_element(selected_element)
    if #executors > 0 then
        self._menu:Divider({
            text = "Executors",
            size = 30,
            color = Color.green,
        })
    end
    for _, element in pairs(executors) do
        self._menu:Button({
            name = element.editor_name,
            text = element.editor_name .. " [" .. (element.id or "") .."]",
            callback = callback(self, self, "set_element", element)
        })
    end    
end

function ElementEditor:add_element(name)
    self:set_element({class = name}, true)    
end
 
function ElementEditor:update(t, dt)
    if self._parent._selected_element and self._current_script.update then
        self._current_script:update(t, dt)
    end   
end
 
function ElementEditor:KeyGPressed(button_index, button_name, controller_index, controller, trigger_id)
    if Input:keyboard():down(Idstring("left ctrl")) then
        if self._parent._selected_element then
            self._parent:set_camera(self._parent._selected_element.values.position)
        end
    end
end