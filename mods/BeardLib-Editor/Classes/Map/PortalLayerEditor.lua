PortalLayerEditor = PortalLayerEditor or class(EditorPart)
local PortalLayer = PortalLayerEditor
function PortalLayer:init(parent)
	self:init_basic(parent, "PortalLayerEditor")
	self._menu = parent._holder
	MenuUtils:new(self)
	self._created_units = {}
	self._portal_shape_unit = "core/units/portal_shape/portal_shape"
end

function PortalLayer:loaded_continents()
    for _, portal in pairs(clone(managers.portal:unit_groups())) do
        for _, shape in pairs(portal._shapes) do
            self:do_spawn_unit(self._portal_shape_unit, {position = shape:position(), rotation = shape:rotation(), shape = shape, portal = portal})
        end
    end
end

function PortalLayer:reset()
    self._selected_portal = nil
    self._selected_shape = nil
    self:select_shape()
end

function PortalLayer:set_selected_unit()
    local unit = self:selected_unit()
    if not alive(unit) or unit:name() ~= self._portal_shape_unit:id() then
        self._selected_shape = nil
        self:select_shape()
    end
    for k, unit in ipairs(clone(self._created_units)) do
        if not alive(unit) then
            table.remove(self._created_units, k)
        end
    end
end

function PortalLayer:save()
    local data = self._parent:data()
    if data then
        data.portal.unit_groups = managers.portal:save_level_data()
    end
end

function PortalLayer:do_spawn_unit(unit_path, ud)
	local unit = World:spawn_unit(unit_path:id(), ud.position or Vector3(), ud.rotation or Rotation())
	table.merge(unit:unit_data(), ud)
    ud = unit:unit_data()
	ud.name = unit_path
	ud.portal_shape_unit = true
	ud.position = unit:position()
	ud.rotation = unit:rotation()
	table.insert(self._created_units, unit)
	if alive(unit) then
		if unit:name() == self._portal_shape_unit:id() then
            local shape = ud.shape or ud.portal:add_shape({})
            shape:set_unit(unit)
            ud.shape = shape
        end
    end
end

function PortalLayer:is_my_unit(unit)
	if unit == self._portal_shape_unit:id() then
		return true
	end
	return false
end

function PortalLayer:delete_unit(unit)
	local ud = unit:unit_data()
	table.delete(self._created_units, unit)
	if ud then
		if unit:name() == self._portal_shape_unit:id() then
            ud.portal:remove_shape(ud.shape)
            self:load_portal_shapes()
            self:save()
		end
	end
	self:save()
end

function PortalLayer:build_menu()
    self:Group("Portals")
    self:Group("Shapes")
    self:Group("Units")
    self:load_portals()
    self:save()
end

function PortalLayer:build_unit_menu()
	local S = self:GetPart("static")
	S._built_multi = false
	S.super.build_default_menu(S)
	local unit = self:selected_unit()
	if alive(unit) then
		S:build_positions_items(true)
		S:update_positions()
        S:Button("CreatePrefab", callback(S, S, "add_selection_to_prefabs"), {group = S:GetItem("QuickButtons")})    
        S:SetTitle("Portal Shape Selection")
		if unit:name() == self._portal_shape_unit:id() then
            unit:unit_data().shape:create_panel(S)
		end
        for i, shape in pairs(self._selected_portal._shapes) do
            if shape == unit:unit_data().shape then
                self:GetItem("shape_"..tostring(i)):RunCallback()
                break
            end
        end
	end
end

function PortalLayer:update(t, dt)
    local portal = self._selected_portal
    if portal then
        local r, g, b = portal._r, portal._g, portal._b
        self._brush:set_color(Color(0.25, r, g, b))
        for unit_id in pairs(portal._ids) do  
            local unit = managers.worlddefinition:get_unit(unit_id)
            if alive(unit) then
                self._brush:unit(unit)
            end
        end
        for _, shape in pairs(portal._shapes) do
            shape:draw(t, dt, 1, self._selected_shape == shape and 0 or 1,1)
        end
    end
    for _, unit in pairs(self._created_units) do
        if alive(unit) then
            unit:set_enabled(unit:unit_data().portal == portal)
        else
            table.remove(self._created_units, unit)
            break
        end
    end
end

function PortalLayer:select_shape(menu, item)
    if self._selected_portal then
        for i=1, #self._selected_portal._shapes do
            self._menu:GetItem("shape_" .. tostring(i)):SetBorder({left = false})
        end        
        self._selected_shape = item and self._selected_portal._shapes[tonumber(item.id)] 
    end
    if self._selected_shape and self:selected_unit() ~= self._selected_shape:unit() then
        self:GetPart("static"):set_selected_unit(self._selected_shape:unit())
    end
    if item then
        item:SetBorder({left = true})
    end
    self:save()
end

function PortalLayer:load_portal_units()
    local units = self._menu:GetItem("Units")
    units:ClearItems()
    if self._selected_portal then
        for unit_id, _ in pairs(self._selected_portal._ids) do
            local unit = managers.worlddefinition:get_unit(unit_id)
            if unit then
                local btn = self:Button(unit_id, function() managers.editor:select_unit(unit) end, {text = string.format("%s[%s]", unit:unit_data().name_id, unit_id), group = units})
                self:SmallImageButton("Remove", callback(self, self, "remove_unit_from_portal", unit), nil, {184, 2, 48, 48}, btn, {
                    highlight_color = Color.red, size_by_text = true, align = "center", texture = "textures/editor_icons_df"
                })
            end
        end
    end
end

function PortalLayer:remove_unit_from_portal(unit)
    self._selected_portal:add_unit_id(unit)
    self:load_portal_units()
end

function PortalLayer:rename_portal(menu, item)
    BeardLibEditor.InputDialog:Show({title = "Rename portal to", text = item.override_panel.text, callback = function(name)
        if name == "" then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Portal name cannot be empty!", callback = function()
                self:rename_portal(menu, item)
            end})
            return
        elseif string.begins(name, " ") then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_portal(menu, item)
            end})
            return
        elseif managers.portal:unit_groups()[name] then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Portal with that name already exists!", callback = function()
                self:add_portal(name)
            end})
            return
        end
        managers.portal:rename_unit_group(item.override_panel.text, name)
        self:load_portals()
        self:save() 
    end})
end

function PortalLayer:remove_portal(menu, item)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the portal", function()
        managers.portal:remove_unit_group(item.override_panel.text)
        self:load_portals()
        self:save()   
    end)
end

function PortalLayer:remove_shape(menu, item)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the portal shape", function()
        if self._selected_shape == self._selected_portal._shapes[tonumber(item.override_panel.id)] then
            self._selected_shape = nil
        end
        self._selected_portal:remove_shape(self._selected_portal._shapes[tonumber(item.override_panel.id)])
        self:load_portal_shapes()
        self:save()        
    end)
end

function PortalLayer:add_portal(name)
    BeardLibEditor.InputDialog:Show({title = "Portal name", text = type(name) == "string" and name or "group", callback = function(name)
        if name == "" then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Portal name cannot be empty!", callback = function()
                self:add_portal(name)
            end})
            return
        elseif string.begins(name, " ") then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_portal(name)
            end})
            return
        elseif managers.portal:unit_groups()[name] then
            BeardLibEditor.Dialog:Show({title = "ERROR!", message = "Portal with that name already exists!", callback = function()
                self:add_portal(name)
            end})
            return
        end
        managers.portal:add_unit_group(name)
        self:load_portals()
    end})
    self:save()
end

function PortalLayer:refresh()
    if self._parent._current_layer == "portal" and self._selected_portal then
        self:load_portal_shapes()
        self:load_portal_units()
        self:select_shape()
    end
end

function PortalLayer:select_portal(name, nounselect, noswitch)
    if noswitch ~= true then
        self._parent:Switch()
    end
    if self._parent._current_layer ~= "portal" then
        self._parent:build_menu("portal", self) --TODO: change to less dumb
    end
    self._selected_shape = nil
    self._menu:GetItem("Shapes"):ClearItems()
    self._menu:GetItem("Units"):ClearItems()
    if self._selected_portal then
        self._menu:GetItem("portal_"..self._selected_portal._name):SetBorder({left = false})
    end
    if self._selected_portal and self._selected_portal._name == name and nounselect ~= true then
        self._selected_portal = nil
    else
        self._menu:GetItem("portal_"..name):SetBorder({left = true})
        self._selected_portal = managers.portal:unit_groups()[name]
        self:load_portal_shapes()
        self:load_portal_units()
    end        
    self:select_shape()
    self:save()
end

function PortalLayer:clbk_select_portal(menu, item)
    self:select_portal(item.text)
end

function PortalLayer:load_portal_shapes()
    local group = self._menu:GetItem("Shapes")
    if group then
        group:ClearItems()
        self:Button("NewShape", callback(self, self, "add_shape"), {group = group, label = "Shapes"})
        for i=1, #self._selected_portal._shapes do
            local btn = self:Button("shape_" .. tostring(i), callback(self, self, "select_shape"), {group = group})
            btn.id = i

            self:SmallImageButton("Remove", callback(self, self, "remove_shape"), nil, {184, 2, 48, 48}, btn, {
                highlight_color = Color.red, size_by_text = true, align = "center", texture = "textures/editor_icons_df"
            })
        end
    end
end

function PortalLayer:add_shape()
    self:do_spawn_unit(self._portal_shape_unit, {position = managers.editor:GetSpawnPosition(), portal = self._selected_portal})
    self:load_portal_shapes()
    self:save()
end

function PortalLayer:load_portals()
    local portals = self:GetItem("Portals")
    if portals then
        portals:ClearItems()
        self:Button("NewPortal", callback(self, self, "add_portal"), {group = portals})
        for name, portal in pairs(managers.portal:unit_groups()) do
            local prtl = self:Button("portal_"..portal._name, callback(self, self, "clbk_select_portal"), {group = portals, text = portal._name})
            local opt = {items_size = 18, size_by_text = true, align = "center", texture = "textures/editor_icons_df"}
            
            opt.highlight_color = Color.red
            local btn = self:SmallImageButton("Remove", callback(self, self, "remove_portal"), nil, {184, 2, 48, 48}, prtl, opt)

            opt.position = callback(WorldDataEditor, WorldDataEditor, "button_pos", btn)
            opt.highlight_color = nil
            local btn = self:SmallImageButton("Rename", callback(self, self, "rename_portal"), nil, {66, 1, 48, 48}, prtl, opt)

            opt.position = callback(WorldDataEditor, WorldDataEditor, "button_pos", btn)
            self:SmallImageButton("AutoFillUnits", callback(self, self, "auto_fill_portal"), nil, {122, 1, 48, 48}, prtl, opt)
        end
    end   
end

function PortalLayer:auto_fill_portal(menu, item)
    local portal = managers.portal:unit_groups()[item.override_panel.text]
    BeardLibEditor.Utils:YesNoQuestion("This will automatically fill the portal with units", function()
        for _, unit in pairs(managers.worlddefinition._all_units) do
            if alive(unit) and unit:visible() and not unit:unit_data().only_visible_in_editor and not unit:unit_data().only_exists_in_editor and not portal:unit_in_group(unit) and portal:inside(unit:position()) then
                portal:add_unit_id(unit)
            end
        end
        self:load_portal_units()
        self:save()
    end)
end