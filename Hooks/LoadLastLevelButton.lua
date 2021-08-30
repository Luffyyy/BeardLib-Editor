Hooks:PostHook(BLTNotificationsGui, "_setup", "BLESetup", function(self)
    self._beardlib_editor_menu = self._beardlib_panel:bitmap({
        name = "BeardlibEditorMenu",
        texture = "textures/editor_icons_df",
        texture_rect = {304, 48, 48, 48},
        w = 28,
        h = 28,
        y = 8,
        x = self._beardlib_achievements:right() + 4,
        color = self._beardlib_accent
    })
    local data = BLE.Options:GetValue("LastLoaded")
    if data then
        self._beardlib_editor_startlast = self._beardlib_panel:bitmap({
            name = "RestartLastEditorHeist",
            texture = "textures/editor_icons_df",
            texture_rect = {64, 64, 32, 32},
            w = 28,
            h = 28,
            y = 8,
            x = self._beardlib_editor_menu:right() + 4,
            color = self._beardlib_accent
        })
    end
end)

local mouse_move = BLTNotificationsGui.mouse_moved
function BLTNotificationsGui:mouse_moved(o, x, y)
    if not self._enabled then
        return
    end

    if alive(self._beardlib_editor_startlast) and alive(self._beardlib_editor_menu) then
        if self._beardlib_editor_startlast:inside(x,y) or self._beardlib_editor_menu:inside(x,y) then
            return true, "link"
        end
    end
    return mouse_move(self, x, y)
end

local mouse_press = BLTNotificationsGui.mouse_pressed
function BLTNotificationsGui:mouse_pressed(button, x, y)
    if not self._enabled or button ~= Idstring("0") then
        return
    end
    if BLE and not BLE._disabled then
        if alive(self._beardlib_editor_startlast) and self._beardlib_editor_startlast:inside(x,y) then
            local data = BLE.Options:GetValue("LastLoaded")
            if data and data.name then
                -- Why one place we levels/../world and in other we don't? Honestly dunno right now lol
                if tweak_data.levels[data.name] or (data.instance and BeardLib.managers.MapFramework._loaded_instances["levels/"..data.name.."/world"]) then
                    BLE.LoadLevel:load_level(data)
                else
                    BeardLib.Managers.Dialog:Simple():Show({title = managers.localization:text("mod_assets_error"), message = "Level \"" .. data.name .. "\" not found.", force = true})
                end
            end
            return true
        end
        if alive(self._beardlib_editor_menu) and self._beardlib_editor_menu:inside(x,y) then
            BLE.Menu:set_enabled(true)
            return true
        end
    end
    return mouse_press(self, button, x, y)
end
