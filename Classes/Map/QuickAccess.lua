QuickAccess = QuickAccess or class()
function QuickAccess:init(parent, menu)
    self._parent = parent

    local normal = not Global.editor_safe_mode
    local size = BLE.Options:GetValue("QuickAccessToolbarSize")
    local toolbar_position = BLE.Options:GetValue("ToolbarPosition")
    local reversed = BLE.Options:GetValue("GUIOnRight")
   
    if toolbar_position == 1 then
        position = reversed and "TopLeft" or "TopRight"
    elseif toolbar_position == 2 then
        position = "CenterTop"
        reversed = false
    elseif toolbar_position == 3 then
        position = "CenterBottom"
        reversed = false
    end

    self._menu = menu:Menu({
        name = "Toolbar",
        auto_foreground = true,
        scrollbar = false,
        visible = self:value("QuickAccessToolbar"),
        position = position,
        align_method = toolbar_position > 1 and "reversed_grid" or "reversed",
        private = {offset = 0}
    })

    local icons = BLE.Utils.EditorIcons
    self._values = {
        {name = "SnapRotation", rect = icons.snap_rotation, reversed = reversed, max = 360, default = 90, help = "Sets the amount(in degrees) that the unit will rotate", help2 = "Reset snap rotation to 90 degrees"},
        {name = "GridSize", rect = icons.grid, reversed = not reversed, max = 10000, default = 100, help = "Sets the amount(in centimeters) that the unit will move", help2 = "Reset grid size to 100 centimeters"}
    }

    self._toggles = {
        {name = "IgnoreFirstRaycast", rect = icons.ignore_raycast, offset = reversed and 0, help = "Ignore First Raycast"},
        {name = "ShowElements", rect = icons.show_elements, help = "Show Elements"},
        {name = "EditorUnits", rect = icons.editor_units, help = "Draw editor units"},
        {name = "rotation_widget_toggle", rect = icons.rotation_widget, callback = ClassClbk(self, "toggle_widget", "rotation"), help = "Toggle Rotation Widget", enabled = normal and self._parent._has_fix},
        {name = "move_widget_toggle", rect = icons.move_widget, offset = reversed and {2,0} or 0, callback = ClassClbk(self, "toggle_widget", "move"), help = "Toggle Move Widget", enabled = normal and self._parent._has_fix}
    }

    self._buttons = {
        {name = "GeneralOptions", rect = icons.settings_gear, offset = reversed and 0, callback = "open_options", help = "General Options"},
        {name = "Deselect", rect = icons.cross_box, callback = "deselect_unit", help = "Deselect", enabled = normal and self._parent._has_fix},
        {name = "TeleportPlayer", rect = icons.teleport, callback = "drop_player", help = "Teleport Player To Camera Position", enabled = normal and self._parent._has_fix},
        {name = "TeleportToSelection", rect = icons.teleport_selection, items = {}, callback = "open_teleport_menu", help = "Teleport Camera To...", enabled = normal and self._parent._has_fix},
        {name = "LocalTransform", rect = icons.local_transform, offset = reversed and {2,0} or 0, callback = "toggle_local_move", help = "Local Transform Orientation", enabled = normal and self._parent._has_fix}
    }

    local opt = {h = size, offset = {0, 2}, background_color = BLE.Options:GetValue("ToolbarBackgroundColor"), align_method = reversed and "grid" or "reversed_grid"}
    if toolbar_position == 2 then
        opt.offset = {2, 0}
    elseif toolbar_position == 3 then
        opt.offset = {2, 1}
    end

    self:build_buttons(self._menu:holder("Buttons", opt))
    self:build_toggles(self._menu:holder("Toggles", opt))
    if toolbar_position == 3 then
        opt.offset = {0, 1}
    else
        opt.offset = 0
    end
    self:build_values(self._menu:holder("Values", opt))

    self:AlignItems(self._menu, toolbar_position > 1)
    self._menu:AlignItems()
end

function QuickAccess:build_values(parent)
    for _, value in pairs(self._values) do
        local t = self:NumberBox(parent, value.name, value)
    end
    
    self:AlignItems(parent)
end

function QuickAccess:NumberBox(parent, name, params)

    local width = self._menu:Items()[1]:W() / 2

    local holder = parent:holder(name.."_panel", {
        offset = 0,
        w = width,
        size = parent:H(),
        h = parent:H(),
        align_method = params.reversed and "grid" or "grid_from_right_reversed"
    })

    holder:tb_imgbtn(name.."_icon", ClassClbk(self, "ResetNumberBox", name, params.default), nil, params.rect, {offset = 0, border_bottom = true, size = holder:H(), help = params.help2, background_color = BLE.Options:GetValue("ToolbarButtonsColor")})
    holder:numberbox(name, ClassClbk(self, "SetOptionValue"), self:value(name), {offset = 0, w = (width-parent:H())-1, size = holder:H() * 0.75, h = holder:H(), text_offset = 0, min = 1, max = params.max, floats = 0, text = false, help = params.help, background_color = BLE.Options:GetValue("ToolbarButtonsColor")})
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

    self:AlignItems(parent)
end

function QuickAccess:Toggle(parent, params, tx)
    local item = parent:tb_imgbtn(params.name, params.callback or ClassClbk(self, "ToggleOptionValue", params.name), nil, params.rect, {
        w = parent:H(),
        h = parent:H(),
        offset = params.offset or {2, 0},
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
        local item = parent:tb_imgbtn(button.name, ClassClbk(self, button.callback), nil, button.rect, {
            w = parent:H(),
            h = parent:H(),
            offset = button.offset or {2, 0},
            help = button.help,
            enabled = button.enabled,
            disabled_alpha = 0.2,
            items = button.items,
            context_font_size = 23,
            background_color = BLE.Options:GetValue("ToolbarButtonsColor")
        })
        if button.items then
            item._list:hide()
        end
    end

    self:AlignItems(parent)
end

function QuickAccess:AlignItems(panel, additive)
    local max_w = 0
    local function align(item)
        if additive then
            max_w = max_w + item:W()+2
        else
            max_w = item:Right()
        end
        
    end

    local items = panel:Items()
    if panel.align_method == "reversed_grid" then
        for i=#items, 1, -1 do
            align(items[i])
        end
    else
        for i=1, #items do
            align(items[i])
        end
    end
    panel:SetSize(max_w)
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
    if item then
        item.img:set_alpha(val and 1 or 0.5)
        item:SetBorder({bottom = val})
    end
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

    local rect = val and BLE.Utils.EditorIcons.local_transform or BLE.Utils.EditorIcons.global_transform
    buttonItem.img:set_image("textures/editor_icons_df", unpack(rect))
    buttonItem:SetHelp((val and "Local" or "Global") .. " Transform Orientation")
end

function QuickAccess:update_grid_size() self:UpdateNumberBox("GridSize") end
function QuickAccess:update_snap_rotation() self:UpdateNumberBox("SnapRotation") end
function QuickAccess:toggle_local_move() self._parent:toggle_local_move() end
function QuickAccess:deselect_unit() BLE.Utils:GetPart("static"):deselect_unit() end
function QuickAccess:drop_player() game_state_machine:current_state():freeflight_drop_player(self._parent._camera_pos, Rotation(self._parent._camera_rot:yaw(), 0, 0)) end

function QuickAccess:open_teleport_menu(item) 
    local items = {"default"}
    local bookmarks = managers.worlddefinition and managers.worlddefinition._world_data and managers.worlddefinition._world_data.camera_bookmarks
    if bookmarks then
        for name, data in pairs(bookmarks) do
           if data and type(data) == "table" then
                table.insert(items, 1, name)
            end
        end
    end
    if BLE.Utils:GetPart("static")._selected_units[1] then
        table.insert(items, #items+1, " -Selection- ")
    end
    item.items = items
    item.ContextMenuCallback = item.ContextMenuCallback or function(self, item)
        if item == " -Selection- " then
            BLE.Utils:GetPart("static"):KeyFPressed() 
        else
            BLE.Utils:GetPart("world"):get_layer("main"):jump_to_bookmark(item)
        end
        return
    end

    item._list:update_search()
    item._list:show()
    item._list:reposition()
end

function QuickAccess:open_options()
    BLE.Menu:select_page("options")
    BLE.Menu:set_enabled(true)
end
function QuickAccess:enabled() return self:value("QuickAccessToolbar") end
function QuickAccess:value(n) return BLE.Options:GetValue("Map/" .. n, "Value") end