QuickAccess = QuickAccess or class()
function QuickAccess:init(parent, menu)
    self._parent = parent

    local normal = not Global.editor_safe_mode
    local size = BLE.Options:GetValue("QuickAccessToolbarSize")
    local align_method = BLE.Options:GetValue("GUIOnRight") and "grid" or "grid_from_right"

    self._menu = menu:Menu({
        name = "Toolbar",
        auto_foreground = true,
        scrollbar = false,
        visible = self:value("QuickAccessToolbar"),
        position = BLE.Options:GetValue("GUIOnRight") and "TopLeft" or "TopRight",
        align_method = align_method,
        w = size * 5,
        private = {offset = 0}
    })

    self._values = {
        {name = "SnapRotation", rect = {416, 18, 32, 32}, w = 2, max = 360, default = 90, help = "Sets the amount(in degrees) that the unit will rotate", help2 = "Reset snap rotation to 90 degrees"},
        {name = "GridSize", rect = {466, 18, 28, 28}, w = 3, max = 10000, default = 100, help = "Sets the amount(in centimeters) that the unit will move", help2 = "Reset grid size to 100 centimeters"}
    }

    self._toggles = {
        {name = "IgnoreFirstRaycast", rect = {451, 115, 42, 42}, help = "Ignore First Raycast"},
        {name = "ShowElements", rect = {464, 64, 32, 32}, help = "Show Elements"},
        {name = "EditorUnits", rect = {416, 64, 32, 32}, help = "Draw editor units"},
        {name = "rotation_widget_toggle", rect = {0, 128, 64, 64}, callback = ClassClbk(self, "toggle_widget", "rotation"), help = "Toggle Rotation Widget", enabled = normal and self._parent._has_fix},
        {name = "move_widget_toggle", rect = {64, 128, 64, 64}, callback = ClassClbk(self, "toggle_widget", "move"), help = "Toggle Move Widget", enabled = normal and self._parent._has_fix}
    }

    self._buttons = {
        {name = "GeneralOptions", rect = {321, 449, 62, 62}, callback = "open_options", help = "General Options"},
        {name = "Deselect", rect = {99, 3, 26, 26}, callback = "deselect_unit", help = "Deselect", enabled = normal and self._parent._has_fix},
        {name = "TeleportPlayer", rect = {368, 16, 32, 32}, callback = "drop_player", help = "Teleport Player To Camera Position", enabled = normal and self._parent._has_fix},
        {name = "TeleportToSelection", rect = {368, 64, 32, 32}, callback = "to_selection", help = "Teleport Camera To Selection", enabled = normal and self._parent._has_fix},
        {name = "LocalTransform", rect = {390, 118, 36, 36}, callback = "toggle_local_move", help = "Local Transform Orientation", enabled = normal and self._parent._has_fix}
    }

    local opt = {size = size, h = size, offset = 0, background_color = BLE.Options:GetValue("ToolbarBackgroundColor"), align_method = align_method}

    self:build_values(self._menu:holder("Values", opt))
    opt.offset = {0, 2}
    self:build_toggles(self._menu:holder("Toggles", opt))
    self:build_buttons(self._menu:holder("Buttons", opt))
end

function QuickAccess:build_values(parent)
    for _, value in pairs(self._values) do
        local t = self:NumberBox(parent, value.name, value)
    end
end

function QuickAccess:NumberBox(parent, name, params)

    local width = (parent:H()) * 2.5
    local icon_w = parent:H() * 0.9

    local holder = parent:holder(name.."_panel", {
        offset = 2,
        w = width,
        size = parent:H(),
        h = parent:H(),
        align_method = "grid_from_right"
    })

    holder:numberbox(name, ClassClbk(self, "SetOptionValue"), self:value(name), {offset = 0, w = (width-icon_w)*0.9, size = holder:H() * 0.75, h = holder:H() * 0.9, text_offset = 0, min = 1, max = params.max, floats = 0, text = false, help = params.help, background_color = BLE.Options:GetValue("ToolbarButtonsColor")})
    holder:tb_imgbtn(name.."_icon", ClassClbk(self, "ResetNumberBox", name, params.default), nil, params.rect, {offset = 0, border_bottom = true, size = holder:H() * 0.9, help = params.help2, background_color = BLE.Options:GetValue("ToolbarButtonsColor")})
end

function QuickAccess:build_toggles(parent)
    for _, toggle in pairs(self._toggles) do
        local t = self:Toggle(parent, toggle, "textures/editor_icons_df")

        if toggle.name:match("_widget_toggle") then
            self:update_widget_toggle(t)
        elseif not toggle.callback then
            self:UpdateToggle(toggle.name, self:value(toggle.name))
        end
    end
end

function QuickAccess:Toggle(parent, params, tx)
    local item = parent:tb_imgbtn(params.name, params.callback or ClassClbk(self, "ToggleOptionValue", params.name), nil, params.rect, {
        offset = 0,
        size = parent:H(),
        help = params.help,
        enabled = params.enabled,
        disabled_alpha = 0.2,
        enabled_color = 1,
        background_color = BLE.Options:GetValue("ToolbarButtonsColor")
    })
    return item
end

function QuickAccess:build_buttons(parent)
    for _, button in pairs(self._buttons) do
        parent:tb_imgbtn(button.name, ClassClbk(self, button.callback), nil, button.rect, {
            offset = 0,
            help = button.help,
            enabled = button.enabled,
            disabled_alpha = 0.2,
            background_color = BLE.Options:GetValue("ToolbarButtonsColor")
        })
    end
end

function QuickAccess:SetVisible(visible)
    self._menu:SetVisible(visible)
end

function QuickAccess:SetOptionValue(item)
    local opt = BLE.Utils:GetPart("opt")
    local name, value = item:Name(), item:Value()
    item = opt:GetItem(name)
    item:SetValue(value, true)
end

function QuickAccess:ToggleOptionValue(name, item)
    local opt = BLE.Utils:GetPart("opt")

    local op_item = opt:GetItem(name)
    local value = not op_item:Value()
    op_item:SetValue(value, true)

    item.img:set_alpha(value and 1 or 0.5)
    item:SetEnabled(item.enabled)
    item:SetBorder({bottom = value})
end

function QuickAccess:UpdateToggle(name, val)
    local item = self._menu:GetItem(name)

    item.img:set_alpha(val and 1 or 0.5)
    item:SetBorder({bottom = val})
end
function QuickAccess:UpdateNumberBox(name)
    local inputItem = self._menu:GetItem(name)
    local value = self:value(name)
    inputItem:SetValue(value)
end
function QuickAccess:ResetNumberBox(name, val)
    local inputItem = self._menu:GetItem(name)
    inputItem:SetValue(val)
    self:SetOptionValue(inputItem)
end

function QuickAccess:toggle_widget(name, item)
    if ctrl() then return end
    item = item or self._menu:GetItem(name.."_widget_toggle")
    local menu = item.parent
    if not item.enabled then return end

    self._parent["toggle_"..name.."_widget"](self._parent)
    self._parent:use_widgets(self._parent:selected_unit() ~= nil)
    self:update_widget_toggle(item)
end

function QuickAccess:update_widget_toggle(item)
    local name = item.name:gsub("_widget_toggle", "")
    local enabled = self._parent[name.."_widget_enabled"](self._parent)
    
    item:SetBorder({bottom = enabled})
    item.img:set_alpha(enabled and 1 or 0.5)
end

function QuickAccess:update_local_move(val)
    local buttonItem = self._menu:GetItem("LocalTransform")

    local rect = val and {390, 118, 36, 36} or {336, 112, 32, 32}
    buttonItem.img:set_image("textures/editor_icons_df", unpack(rect))
    buttonItem:SetHelp((val and "Local" or "Global") .. " Transform Orientation")
end

function QuickAccess:update_grid_size() self:UpdateNumberBox("GridSize") end
function QuickAccess:update_snap_rotation() self:UpdateNumberBox("SnapRotation") end
function QuickAccess:toggle_local_move() self._parent:toggle_local_move() end
function QuickAccess:deselect_unit() BLE.Utils:GetPart("static"):deselect_unit() end
function QuickAccess:drop_player() game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0)) end
function QuickAccess:to_selection() return BLE.Utils:GetPart("static"):KeyFPressed() end
function QuickAccess:open_options() BLE.Menu:set_enabled(true) end
function QuickAccess:enabled() return self:value("QuickAccessToolbar") end
function QuickAccess:value(n) return BLE.Options:GetValue("Map/" .. n, "Value") end