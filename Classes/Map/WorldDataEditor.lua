WorldDataEditor = WorldDataEditor or class(EditorPart)
local WData = WorldDataEditor
function WData:init(parent, menu)
    self._opened = {}
    WData.super.init(self, parent, menu, "World", {make_tabs = ClassClbk(self, "make_tabs")})
    self.layers = {
        main = MainLayerEditor:new(self),
        environment = EnvironmentLayerEditor:new(self),
        sound = SoundLayerEditor:new(self), 
        portal = PortalLayerEditor:new(self),
        ai = AiLayerEditor:new(self),
        brush = BrushLayerEditor:new(self),
    }
end

function WData:data()
    return managers.worlddefinition and managers.worlddefinition._world_data
end

function WData:get_layer(name)
    return self.layers[name]
end

function WData:destroy()
    for _, layer in pairs(self.layers) do
        layer:destroy()
    end
end

function WData:loaded_continents(continents, current_continent)
    self:GetPart("mission"):set_elements_vis()

    for name, manager in pairs(self.layers) do
        if manager.loaded_continents then
            manager:loaded_continents()
        end
        if manager.build_menu then
            manager:build_menu()
        end
    end

    self.layers.main:set_visible(true)
    self._loaded = true
end

function WData:unit_spawned(unit)
    for _, manager in pairs(self.layers) do
        if manager.unit_spawned then
            manager:unit_spawned(unit)
        end
	end
end

function WData:unit_deleted(unit)
    for _, manager in pairs(self.layers) do
        if manager.unit_deleted then
            manager:unit_deleted(unit)
        end
    end
end

function WData:do_spawn_unit(unit, data)
    for _, manager in pairs(self.layers) do
        if manager.is_my_unit and manager:is_my_unit(unit:id())  then
            return manager:do_spawn_unit(unit, data)
        end
    end
end

function WData:can_unit_be_selected(unit)
    local layer = self.layers[self._current_layer]
    return layer and layer.is_my_unit and layer:is_my_unit(unit) and layer:can_unit_be_selected(unit) or false
end

function WData:is_world_unit(unit)
    unit = unit:id()
    for _, manager in pairs(self.layers) do
        if manager.is_my_unit and manager:is_my_unit(unit) then
            return true
        end
    end
    return false
end

function WData:build_unit_menu()
    local selected_unit = self:selected_unit()
    local unit_ids = selected_unit:name():id()
    for _, manager in pairs(self.layers) do
        if manager.build_unit_menu and manager:is_my_unit(unit_ids) then
            manager:build_unit_menu()
        end
    end
end

function WData:update_positions()
    local selected_unit = self:selected_unit()
    if selected_unit then
        for _, manager in pairs(self.layers) do
            if manager.save and manager:is_my_unit(selected_unit:name():id()) then
                manager:save()
            end
        end
    end
end

function WData:make_tabs(tabs)
    local managers = {"main", "environment", "sound", "portal", "ai", "brush"}
    self._current_layer = self._current_layer or "main"
    for i, name in pairs(managers) do
        self._tabs:s_btn(name, ClassClbk(self, "open_tab", name:lower()), {
            enabled = not Global.editor_safe_mode,
            text = name == "ai" and "AI" or string.capitalize(name),
            border_bottom = i == 1
        })
    end
end

function WData:open_tab(name, item)
    item = item or self._tabs:GetItem(name)
    self._current_layer = name
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = tab.name == item.name})
    end
    for layer_name, manager in pairs(self.layers) do
        if manager.set_visible then
            manager:set_visible(name == layer_name)
        end
    end
end

function WData:build_groups_layer_menu()
    local tx  = "textures/editor_icons_df"

    local groups = self:pan("Groups", {offset = 2, auto_align = false})
    local continents = managers.worlddefinition._continent_definitions
    local icons = BLE.Utils.EditorIcons

    for _, continent in pairs(self._parent._continents) do
        if continents[continent].editor_groups then
            for _, editor_group in pairs(continents[continent].editor_groups) do
                if editor_group.units then
                    local group = groups:group(editor_group.name, {text = editor_group.name, auto_align = false, max_height = 400, inherit_values = {size = self._menu.size * 0.8}, closed = true})
                    local toolbar = group:GetToolbar({auto_align = false})
                    toolbar:tb_imgbtn("Remove", function() 
                        BLE.Utils:YesNoQuestion("This will delete the group", function()
                            self:GetPart("static"):remove_group(nil, editor_group)
                            self:build_menu("groups")
                        end)
                    end, nil, icons.cross, {highlight_color = Color.red})
                    toolbar:tb_imgbtn("Rename", function()
                        BLE.InputDialog:Show({title = "Group Name", text = group.name, callback = function(name)
                            self:GetPart("static"):set_group_name(nil, editor_group, name)
                            self:build_menu("groups")
                        end})
                    end, nil, icons.pen)
                    toolbar:tb_imgbtn("SelectGroup", ClassClbk(self:GetPart("static"), "select_group", editor_group), nil, icons.select)
                    toolbar:tb_imgbtn("SetVisible", function(item) 
                        self:GetPart("static"):toggle_group_visibility(editor_group) 
                        item.enabled_alpha = editor_group.visible and 1 or 0.5
                        item:SetEnabled(item.enabled)
                    end, nil, icons.eye, {enabled_alpha = editor_group.visible ~= nil and (editor_group.visible and 1 or 0.5) or 1})

                    for _, unit_id in pairs(editor_group.units) do
                        local unit = managers.worlddefinition:get_unit(unit_id)
                        if alive(unit) then
                            group:button(tostring(unit_id), ClassClbk(self._parent, "select_unit", unit), {text = unit:unit_data().name_id  .. "(" .. tostring(unit_id) .. ")"})
                        end
                    end
                end
            end
        else
            continents[continent].editor_groups = {}
        end
    end
    groups:AlignItems(true)
    if #groups:Items() == 0 then
        self:divider("No groups found in the map.")
    end
end

function WData:reset()
    for _, editor in pairs(self.layers) do
        if editor.reset then
            editor:reset()
        end
    end
end

function WData:reset_selected_units()
    if self._loaded then
        for _, editor in pairs(self.layers) do
            if editor.reset_selected_units then
                editor:reset_selected_units()
            end
        end
    end
end

function WData:set_selected_unit()
    for _, editor in pairs(self.layers) do
        if editor.set_selected_unit then
            editor:set_selected_unit()
        end
    end
end

function WData:update(t, dt)
    self.super.update(self, t, dt)

    for _, editor in pairs(self.layers) do
        if editor.update and editor:active() then
            editor:update(t, dt)
        end
    end
end

function WData:mouse_busy()
    for _, layer in pairs(self.layers) do
        if layer.mouse_busy and layer:mouse_busy(b, x, y) then
            return true
        end
    end
end

function WData:mouse_pressed(b, x, y)
    for _, layer in pairs(self.layers) do
        if layer.mouse_pressed and layer:mouse_pressed(b, x, y) then
            return true
        end
    end
end

function WData:mouse_released(b, x, y)
    for _, layer in pairs(self.layers) do
        if layer.mouse_released and layer:mouse_released(b, x, y) then
            return true
        end
    end
end

function WData:refresh()
    self.layers.main:build_menu()
end