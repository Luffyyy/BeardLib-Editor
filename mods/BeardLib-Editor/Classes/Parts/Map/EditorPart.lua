EditorPart = EditorPart or class()
function EditorPart:init(parent, menu, name, opt)
    self:init_basic(parent, name)
    self._menu = menu:Menu(table.merge({
        name = name,
        control_slice = 1.75,
        items_size = 18,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,        
        scroll_width = 4,
        visible = false,
        w = 300,
        h = self:Manager("menu"):get_menu_h()
    }, opt or {}))    
    MenuUtils:new(self)
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom() + 1) 
    self:build_default_menu()
end

function EditorPart:bind(key, clbk)
    table.insert(self._trigger_ids, Input:keyboard():add_trigger(Idstring(key), callback(self, self, "key_pressed", clbk)))
end

function EditorPart:key_pressed(clbk)
    if not self._parent._menu:Focused() and not shift() and not alt() then
        clbk()
    end 
end

function EditorPart:selected_unit()
    return self._parent:selected_unit()
end

function EditorPart:selected_units()
    return self._parent:selected_units()
end

function EditorPart:init_basic(parent, name)
    self._name = name
    self._parent = parent    
    self._pen = Draw:pen(Color(0.15, 1, 1, 1))
    self._brush = Draw:brush(Color(0.15, 1, 1, 1))   
    self._trigger_ids = {}
    self._axis_controls = {"x", "y", "z", "yaw", "pitch", "roll"}
    self._shape_controls = {"width", "height", "depth", "radius"}
end

function EditorPart:Enabled()
    return self._menu:Visible()
end

function EditorPart:Switch()
    self:Manager("menu"):SwitchMenu(self._menu)
end

function EditorPart:Value(v)
    return BeardLibEditor.Options:GetValue("Map/" .. v)
end

function EditorPart:Manager(n)
    return managers.editor.managers[n]
end 

function EditorPart:build_default_menu()
    self._menu:ClearItems()
    self._menu:Divider({
        name = "Title",
        items_size = 24,
        offset = 0,
        marker_color = self._menu.marker_highlight_color,
        text = string.pretty2(self._menu.name)
    })
end

function EditorPart:SetTitle(title)
    self:GetItem("Title"):SetText(title or self._menu.name)
end

function EditorPart:disable()
    for _, id in pairs(self._trigger_ids) do
        Input:keyboard():remove_trigger(id)
    end
    self._trigger_ids = {}
end
