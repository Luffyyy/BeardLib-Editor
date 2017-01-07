EditorPart = EditorPart or class()
function EditorPart:init(parent, menu, name)
    self:init_basic(parent, name)
    self._menu = menu:NewMenu({
        name = name,
        control_slice = 1.75,
        items_size = 18,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,        
        visible = false,
        w = 300,
    })    
    self._menu:SetSize(nil, self._menu:Panel():h() - 43)    
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom() + 1) 

    self:build_default_menu()
end

function EditorPart:init_basic(parent, name)
    self._name = name
    self._parent = parent    
    self._pen = Draw:pen(Color(0.15, 1, 1, 1))
    self._brush = Draw:brush(Color(0.15, 1, 1, 1))   
    self._trigger_ids = {}
end

function EditorPart:Switch()
    self:Manager("UpperMenu"):SwitchMenu(self._menu)
end

function EditorPart:Value(v)
    return BeardLibEditor.Options:GetValue("Map/" .. v)
end

function EditorPart:Manager(n)
    return self._parent.managers[n]
end 

function EditorPart:build_default_menu()
    self._menu:ClearItems()
    self._menu:Divider({
        items_size = 24,
        marker_color = self._menu.marker_highlight_color,
        text = string.pretty2(self._menu.name)
    })
end

function EditorPart:disable()
    for _, id in pairs(self._trigger_ids) do
        Input:keyboard():remove_trigger(id)
    end
    self._trigger_ids = {}
end

function EditorPart:Divider(name, opt)
    opt = opt or {}
    return self._menu:Divider(table.merge({
        name = name,
        text = string.pretty2(name),
        color = self._menu.marker_highlight_color,
    }, opt))
end

function EditorPart:Group(name, opt)
    opt = opt or {}
    return self._menu:ItemsGroup(table.merge({
        name = name,
        text = string.pretty2(name),
    }, opt))
end

function EditorPart:Button(name, callback, opt)
    opt = opt or {}
    return self._menu:Button(table.merge({
        name = name,
        text = string.pretty2(name),
        callback = callback,
    }, opt))
end

function EditorPart:SmallButton(name, callback, parent, opt)    
    opt = opt or {}
    return self._menu:Button(table.merge({
        name = name,
        text = string.pretty2(name),
        callback = callback,
        size_by_text = true,
        position = "TopRight",
        align = "center",
        override_parent = parent,
    }, opt))
end

function EditorPart:ComboBox(name, callback, items, value, opt)
    opt = opt or {}
    return self._menu:ComboBox(table.merge({
        name = name,
        text = string.pretty2(name),
        value = value,
        items = items,
        callback = callback,
    }, opt))
end

function EditorPart:TextBox(name, callback, value, opt)
    opt = opt or {}
    return self._menu:TextBox(table.merge({
        name = name,
        text = string.pretty2(name),
        callback = callback,
        value = value
    }, opt))
end

function EditorPart:Slider(name, callback, value, opt)
    opt = opt or {}
    return self._menu:Slider(table.merge({
        name = name,
        text = string.pretty2(name),
        value = value,
        callback = callback,
    }, opt))
end

function EditorPart:NumberBox(name, callback, value, opt)
    opt = opt or {}
    return self._menu:NumberBox(table.merge({
        name = name,
        text = string.pretty2(name),
        value = value,
        callback = callback,
    }, opt))
end

function EditorPart:Toggle(name, callback, value, opt)    
    opt = opt or {}
    return self._menu:Toggle(table.merge({
        name = name,
        text = string.pretty2(name),
        value = value,
        callback = callback,
    }, opt))
end




