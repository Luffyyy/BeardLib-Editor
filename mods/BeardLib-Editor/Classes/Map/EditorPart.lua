EditorPart = EditorPart or class()
function EditorPart:init(parent, menu, name, opt)
    self:init_basic(parent, name)
    self._menu = menu:Menu(table.merge({
        name = name,
        control_slice = 1.75,
        items_size = 18,
        offset = {4, 1},
        background_color = BeardLibEditor.Options:GetValue("BackgroundColor"),
        scrollbar = false,
        visible = false,
        w = 300,
        h = self:Manager("menu"):get_menu_h()
    }, opt or {}))
    MenuUtils:new(self)
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom() + 1) 
    self:Divider("Title", {items_size = 24, offset = 0, marker_color = BeardLibEditor.Options:GetValue("AccentColor"), text = string.pretty2(name)})
    self._holder = self:Menu("Holder", {automatic_height = false, h = self._menu.h - 24, scroll_width = 4})
    MenuUtils:new(self, self._holder)
    self:build_default_menu()
end

function EditorPart:bind_opt(opt, clbk)
    self:bind("Input/"..opt, clbk)
end

function EditorPart:bind(opt, clbk)
    local key
    if opt:match("Input") then
        key = BeardLibEditor.Options:GetValue(opt)
    else
        key = opt
    end
    if key then
        table.insert(self._triggers, BeardLib.Utils.Input:TriggerDataFromString(key, clbk))
    end
end

function EditorPart:update() 
    --and not shift() and not alt()
    local In = BeardLib.Utils.Input
    if not self._parent._menu:Focused() then
        for _, trigger in pairs(self._triggers) do
            if BeardLib.Utils.Input:Triggered(trigger) then
                trigger.clbk()
            end
        end
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
    self._pen = Draw:pen(Color(1, 1, 1))
    self._brush = Draw:brush(Color(1, 1, 1))
    self._brush:set_font(Idstring("fonts/font_large_mf"), 16)
    self._brush:set_render_template(Idstring("OverlayVertexColorTextured"))

    self._triggers = {}
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
    self:ClearItems()
end

function EditorPart:SetTitle(title)
    self._menu:GetItem("Title"):SetText(title or self._menu.name)
end

function EditorPart:disable()
    self._triggers = {}
end