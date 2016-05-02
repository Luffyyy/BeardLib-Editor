ElementEditor = ElementEditor or class()

function ElementEditor:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "selected_element",
        text = "Selected element",
        help = "",
    })

    self:InitItems()
end

function ElementEditor:InitItems()
    self._menu:TextBox({
        name = "element_editor_name",
        text = "Name:",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:TextBox({
        name = "element_id",
        text = "id:",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:ComboBox({
        name = "element_class",
        text = "Class:",
        items = self._parent._mission_elements,
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Slider({
        name = "element_position_x",
        text = "Position x",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Slider({
        name = "element_position_y",
        text = "Position y",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Slider({
        name = "element_position_z",
        text = "Position z",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Slider({
        name = "element_rotation_y",
        text = "Rotation yaw",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Slider({
        name = "element_rotation_p",
        text = "Rotation pitch",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Slider({
        name = "element_rotation_r",
        text = "Rotation roll",
        help = "",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Table({
        name = "element_values",
        text = "Values:",
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Table({
        name = "element_on_executed",
        text = "On executed:",
        add = false,
        callback = callback(self, self, "set_element_data"),
    })
    self._menu:Button({
        name = "element_add_to_on_executed",
        text = "Add to element to execute",
        help = "",
        callback = callback(self, self, "show_add_element_dialog"),
    })
    self._menu:Divider({
        text = "Executors",
        size = 30,
        color = Color.green,
    })
end


function ElementEditor:set_element(element)
    self._selected_element = element
    self._menu:GetItem("element_editor_name"):SetValue(element and element.editor_name or "")
    self._menu:GetItem("element_id"):SetValue(element and element.id or "")
    self._menu:GetItem("element_class"):SetValue(element and table.get_key(self._mission_elements, element.class) or 1)
    self._menu:GetItem("element_position_x"):SetValue(element and element.values.position and element.values.position.x or 0)
    self._menu:GetItem("element_position_y"):SetValue(element and element.values.position and element.values.position.y or 0)
    self._menu:GetItem("element_position_z"):SetValue(element and element.values.position and element.values.position.z or 0)
    self._menu:GetItem("element_rotation_y"):SetValue(element and element.values.rotation and element.values.rotation:yaw() or 0)
    self._menu:GetItem("element_rotation_p"):SetValue(element and element.values.rotation and element.values.rotation:pitch() or 0)
    self._menu:GetItem("element_rotation_r"):SetValue(element and element.values.rotation and element.values.rotation:roll() or 0)
    self._menu:GetItem("element_values"):SetValue(element and element.values or {})
    self._menu:GetItem("element_on_executed"):SetValue(element and element.values.on_executed or {})

    local menu = self._menu:GetItem("selected_element")
    menu:ClearItems("temp")

    for k, v in pairs(element.values) do
        if type(v) == "table" and k ~= "on_executed" then
            menu:Table({
                name = "element_" .. k,
                text = k,
                index = 11,
                label = "temp",
                items = v,
                callback = callback(self, self, "set_element_data"),
            })
        end
    end
    for _, element in pairs(managers.mission:get_executors_of_element(element)) do
        menu:Button({
            name = element.editor_name,
            text = element.editor_name .. " [" .. (element.id or "") .."]",
            label = "temp",
            callback = callback(self, self, "_select_element", element)
        })
    end

end


function ElementEditor:set_element_data(menu, item)
    if self._selected_element then
        for k,v in pairs(menu:GetItem("element_values").items) do
            self._selected_element.values[k] = v
        end
        self._selected_element.values.on_executed = {}
        for i=1, (table.size(menu:GetItem("element_on_executed").items) / 2) do
            table.insert(self._selected_element.values.on_executed, {})
        end
        for k,v in pairs(menu:GetItem("element_on_executed").items) do
            local split = string.split(k, ":")
            local i = tonumber(split[1])
            if #split == 2 then
                if self._selected_element.values.on_executed[i] then
                    self._selected_element.values.on_executed[i][split[2]] = tonumber(v)
                end
            end
        end
        self._selected_element.values.position = Vector3(menu:GetItem("element_position_x").value, menu:GetItem("element_position_y").value, menu:GetItem("element_position_z").value)
        self._selected_element.values.rotation = Rotation(menu:GetItem("element_rotation_y").value, menu:GetItem("element_rotation_p").value, menu:GetItem("element_rotation_r").value)
        self._selected_element.editor_name = menu:GetItem("element_editor_name").value
    end
end

function ElementEditor:show_add_element_dialog(menu, item)
    local items = {
        {
            name = "id",
            text = "id:",
            value = "",
            filter = "number",
            type = "TextBox",
        },
        {
            name = "delay",
            text = "Delay:",
            value = "0",
            filter = "number",
            type = "TextBox",
        }
    }
    BeardLibEditor.managers.Dialog:show({
        title = "Add element to on executed",
        callback = callback(self, self, "add_element_callback"),
        items = items,
        yes = "Add",
        no = "Close",
    })
end

function ElementEditor:add_element_callback(items)
    local on_executed = self._menu:GetItem("element_on_executed")
    local i = (table.size(on_executed.items) / 2) + 1
    on_executed:Add(i .. ":" .. "id", items[1].value)
    on_executed:Add(i .. ":" .. "delay", items[2].value)
    if on_executed.callback then
        on_executed.callback(on_executed.parent, on_executed)
    end
end
