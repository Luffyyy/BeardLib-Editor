local function assert_value(getter, value, message)
    local v = getter(value)
    assert(v ~= nil, string.format("%s with name %s doesn't exist!", message, value))

    return v
end

EditorPart = EditorPart or class()
EditorPart._triggers = {}

local Part = EditorPart
function Part:init(parent, menu, name, opt, mopt)
    self:init_basic(parent, name)
    opt = opt or {}
    mopt = mopt or {}

    local boxes_color = BLE.Options:GetValue("BoxesBackgroundColor")

    self._menu = menu:DivGroup(table.merge({
        name = name,
        text = string.pretty2(name),
        inherit_values = {
            full_bg_color = boxes_color,
        },
        auto_foreground = true, 
        scrollbar = false,
        visible = false,
        auto_height = false,
        private = {
            offset = 0,
            size = BLE.Options:GetValue("MapEditorFontSize") * 1.335,
            background_color = BLE.Options:GetValue("AccentColor"),
            full_bg_color = BLE.Options:GetValue("BackgroundColor"),
        },
        position = function(item)
            if BLE.Options:GetValue("GUIOnRight") then
                item:SetPositionByString("Right")
            end
            item:Panel():set_world_bottom(item:Panel():parent():world_bottom() + 1)
        end,
        w = BLE.Options:GetValue("MapEditorPanelWidth"),
        h = self:GetPart("menu"):get_menu_h() - 1
    }, mopt))
    ItemExt:add_funcs(self)
    if opt.make_tabs then
        self._tabs = self._menu:holder("Tabs", table.merge({
            align_method = "centered_grid",
            full_bg_color = BLE.Options:GetValue("BoxesBackgroundColor"),
            offset = 0,
            inherit_values = {offset = 6},
        }, opt.tabs_opt))
        if type(opt.make_tabs) == "function" then
            opt.make_tabs(self._tabs)
        end
    end

    self._holder = self._menu:pan("Holder", table.merge({
        offset = 0,
        auto_height = false,
        full_bg_color = BLE.Options:GetValue("BackgroundColor"),
        inherit_values = {
            offset = {6, 4},
            full_bg_color = boxes_color,
        },
        stretch_to_bottom = true,
        scroll_width = 4
    }, opt))
    ItemExt:add_funcs(self, self._holder)
    self:build_default_menu()
    self:make_collapse_all_button()
    self._menu:AlignItems(true)
end

function Part:make_collapse_all_button()
    local tb = self._menu:GetToolbar()
    tb:tb_imgbtn("CollapseAll", ClassClbk(self, "collapse_all", false), nil, BLE.Utils.EditorIcons.collapse_all)
    self._help = tb:tb_imgbtn("Help", nil, nil, BLE.Utils.EditorIcons.help, {visible = false})
end

function Part:show_help(clbk)
    if self._help then
        self._help:SetVisible(true)
        self._menu:AlignItems(true)
        self._help:SetCallback(clbk)
    end
end

function Part:collapse_all(menu)
    for _, item in pairs((menu or self._holder):Items()) do
        if item.type_name == "Group" and not item.divider_type then --Do not collapse DivGroups so they won't get stuck.
            item:CloseGroup()
        end
        if item.menu_type then
            self:collapse_all(item)
        end
    end
end

function Part:bind(opt, clbk, in_dialogs)
    local trigger = self._parent:bind(opt, clbk, in_dialogs)
    if trigger then
        table.insert(self._triggers, trigger)
    end
end

function Part:update()

end

function Part:init_basic(parent, name)
    self._name = name
    self._parent = parent    
    self._pen = Draw:pen(Color(1, 1, 1))
    self._brush = Draw:brush(Color(1, 1, 1))
    self._brush:set_font(Idstring("fonts/font_large_mf"), 16)
    self._brush:set_render_template(Idstring("OverlayVertexColorTextured"))

    self._axis_controls = {"x", "y", "z", "yaw", "pitch", "roll"}
    self._shape_controls = {"width", "height", "depth", "radius"}
end

function Part:Switch(no_anim)
    if self:GetPart("menu"):is_tab_enabled(self.manager_name) then
        self:GetPart("menu"):Switch(self, no_anim)
    end
end
function Part:bind_opt(opt, clbk, in_dialogs) self:bind("Input/"..opt, clbk, in_dialogs) end
function Part:selected_unit() return self._parent:selected_unit() end
function Part:selected_units() return self._parent:selected_units() end
function Part:enabled() return self._enabled end
function Part:value(n) return BLE.Options:GetValue("Map/" .. n, "Value") end
function Part:set_value(n, v) return BLE.Options:SetValue("Map/" .. n, v) end
function Part:part(n) return assert_value(ClassClbk(BLE.Utils, "GetPart"), n, "Part") end
function Part:layer(l) return assert_value(ClassClbk(BLE.Utils, "GetLayer"), l, "Layer") end
function Part:clear_menu()
    if self._help then
        self._help:SetVisible(false)
    end
    self._holder:ClearItems()
end
function Part:build_default_menu()
    self:clear_menu()
    self:build_default()
end
function Part:build_default() end
function Part:set_title(title) self._menu:SetText(title or self._menu.name) end
function Part:get_title() return self._menu:Text() end
function Part:enable()
    self._enabled = true
end
function Part:disable()
    self._enabled = false
    for _, trigger in pairs(self._triggers) do
        self._parent:unbind(trigger.opt)
    end
    self._triggers = {}
end

-- Aliases
Part.Enabled = Part.enabled
Part.Val = Part.value
Part.GetPart = Part.part
Part.GetLayer = Part.layer
Part.SetTitle = Part.set_title