EditorPart = EditorPart or class()
local Part = EditorPart
function Part:init(parent, menu, name, opt, mopt)
    self:init_basic(parent, name)
    opt = opt or {}
    mopt = mopt or {}
    self._menu = menu:Menu(table.merge({
        name = name,
        control_slice = 0.5,
        items_size = 18,
        offset = {4, 2},
        auto_foreground = true,
        background_color = BeardLibEditor.Options:GetValue("BackgroundColor"),
        scrollbar = false,
        visible = false,
        w = 300,
        h = self:Manager("menu"):get_menu_h()
    }, mopt))
    self._menu.highlight_color = self._menu.foreground:with_alpha(0.1)
    MenuUtils:new(self)
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom() + 1)
    if not opt.no_title then
        self:Divider("Title", {items_size = 24, offset = 0, background_color = BeardLibEditor.Options:GetValue("AccentColor"), text = string.pretty2(name)})
    end
    self._holder = self:Menu("Holder", table.merge({private = {offset = {0, 1}}, auto_height = false, h = self._menu.h - (opt.no_title and 4 or 32), scroll_width = 6}, opt))
    MenuUtils:new(self, self._holder)
    self:build_default_menu()
end

function Part:bind(opt, clbk, in_dialogs)
    local key
    if opt:match("Input") then
        key = BeardLibEditor.Options:GetValue(opt)
    else
        key = opt
    end
    if key then
        local trigger = BeardLib.Utils.Input:TriggerDataFromString(key, clbk)
        trigger.in_dialogs = in_dialogs
        table.insert(self._triggers, trigger)
    end
end

function Part:update()
    local allowed = not BeardLib.managers.dialog:DialogOpened()
    local not_focused = not (self._parent._menu:Focused() or BeardLib.managers.dialog:Menu():Typing())
    for _, trigger in pairs(self._triggers) do
        if not_focused and (allowed or trigger.in_dialogs) and BeardLib.Utils.Input:Triggered(trigger) then
            trigger.clbk()
        end
    end
end

function Part:init_basic(parent, name)
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

function Part:bind_opt(opt, clbk, in_dialogs) self:bind("Input/"..opt, clbk, in_dialogs) end
function Part:selected_unit() return self._parent:selected_unit() end
function Part:selected_units() return self._parent:selected_units() end
function Part:Enabled() return self._menu:Visible() end
function Part:Switch() self:Manager("menu"):Switch(self) end
function Part:Value(v) return BeardLibEditor.Options:GetValue("Map/" .. v) end
function Part:Manager(n) return managers.editor.managers[n] end 
function Part:build_default_menu() self:ClearItems() end
function Part:SetTitle(title) self._menu:GetItem("Title"):SetText(title or self._menu.name) end
function Part:disable() self._triggers = {} end