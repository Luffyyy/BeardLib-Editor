PortalLayerEditor = PortalLayerEditor or class(LayerEditor)
local PortalLayer = PortalLayerEditor
function PortalLayer:init(parent)
	PortalLayer.super.init(self, parent, "PortalLayerEditor", {private = {offset = 0, h = parent._holder:ItemsHeight()-16}})
	self._created_units = {}
	self._portal_shape_unit = "core/units/portal_shape/portal_shape"
    self._units_visible = true
end

function PortalLayer:loaded_continents()
    PortalLayer.super.loaded_continents(self)
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

function PortalLayer:selected_portal()
    return self._selected_portal
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

function PortalLayer:unit_deleted(unit)
	local ud = unit:unit_data()
	table.delete(self._created_units, unit)
	if ud then
		if unit:name() == self._portal_shape_unit:id() then
            ud.portal:remove_shape(ud.shape)
            self:load_portal_shapes()
            self:save()
		end
    end
    self:remove_unit_from_portal(unit)
	self:save()
end

function PortalLayer:build_menu()

    local h = self._holder:ItemsHeight(4) / 4
	local opt = self:GetPart("opt")

    self._holder:tickbox("DrawPortals", nil, true)
    local portals = self._holder:group("Portals", {h = h, auto_height = false})
    portals:GetToolbar():tb_imgbtn("NewPortal", ClassClbk(self, "add_portal"), nil, BLE.Utils.EditorIcons.plus, {help = "Add a New Portal"})
    local shapes = self._holder:group("Shapes", {h = h, auto_height = false})
    shapes:GetToolbar():tb_imgbtn("NewShape", ClassClbk(self, "add_shape"), nil, BLE.Utils.EditorIcons.plus, {help = "Add a New Shape"})

    self._holder:group("Units", {stretch_to_bottom = true, auto_height = false})
    self:load_portals()
    self:save()
end

function PortalLayer:build_unit_menu()
	local S = self:GetPart("static")
	S._built_multi = false
	S:clear_menu()
	local unit = self:selected_unit()
	if alive(unit) then
		S:build_positions_items(true)
        S:update_positions()
        S:SetTitle("Portal Shape Selection")
		if unit:name() == self._portal_shape_unit:id() then
            unit:unit_data().shape:create_panel(S, S:GetItem("Transform"))
		end
        for i, shape in pairs(self._selected_portal._shapes) do
            if shape == unit:unit_data().shape then
                self._holder:GetItem("shape_"..tostring(i)):RunCallback()
                break
            end
        end
	end
end

function PortalLayer:update(t, dt)
    local portal = self._selected_portal
    if self._holder:GetItemValue("DrawPortals") then
        if portal then
            for unit_id in pairs(portal._ids) do  
                local unit = managers.worlddefinition:get_unit(unit_id)
                if alive(unit) then
                    Application:draw(unit, 1, 0, 0)
                end
            end
            for _, shape in pairs(portal._shapes) do
                shape:draw(t, dt, 1, self._selected_shape == shape and 0 or 1,1)
            end
        end
    end
    for _, unit in pairs(self._created_units) do
        if alive(unit) then
            unit:set_enabled(unit:unit_data().portal == portal)
        else
            table.delete(self._created_units, unit)
            break
        end
    end
end

function PortalLayer:select_shape(item)
    if self._selected_portal then
        for i=1, #self._selected_portal._shapes do
            self._holder:GetItem("shape_" .. tostring(i)):SetBorder({left = false})
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
    local units = self._holder:GetItem("Units")
    units:ClearItems()
    units:GetToolbar():tb_imgbtn("ToggleVisibility", ClassClbk(self, "toggle_units_visible"), nil, BLE.Utils.EditorIcons.eye, {enabled_alpha = self._units_visible and 1 or 0.5, help = "Toggle Visibility"})
    if self._selected_portal then
        for unit_id, _ in pairs(self._selected_portal._ids) do
            local unit = managers.worlddefinition:get_unit(unit_id)
            if unit then
                local btn = units:button(unit_id, function() managers.editor:select_unit(unit) end, {text = string.format("%s[%s]", unit:unit_data().name_id, unit_id)})
                btn:tb_imgbtn("Remove", ClassClbk(self, "remove_unit_from_portal", unit, btn), nil, BLE.Utils.EditorIcons.cross, {highlight_color = Color.red})
            end
        end
    end
end

function PortalLayer:remove_unit_from_portal(unit, item)
    if self._selected_portal then
        self._selected_portal:remove_unit_id(unit)
        item = item or self._holder:GetItem(unit:unit_data().unit_id) 
        if item then
            item:Destroy()
        end
    end
end

function PortalLayer:add_unit_to_portal(unit, no_reload)
    self._selected_portal:add_unit_id(unit)
    if not no_reload then
        self:load_portal_units()
    end
end

function PortalLayer:rename_portal(item)
    BLE.InputDialog:Show({title = "Rename portal to", text = item.parent.text, callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Portal name cannot be empty!", callback = function()
                self:rename_portal(item)
            end})
            return
        elseif string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_portal(item)
            end})
            return
        elseif managers.portal:unit_groups()[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Portal with that name already exists!", callback = function()
                self:add_portal(name)
            end})
            return
        end
        managers.portal:rename_unit_group(item.parent.text, name)
        self:load_portals()
        self:save() 
    end})
end

function PortalLayer:remove_portal(item)
    BLE.Utils:YesNoQuestion("This will remove the portal", function()
        managers.portal:remove_unit_group(item.parent.text)
        self:load_portals()
        self:save()   
    end)
end

function PortalLayer:remove_shape(item)
    BLE.Utils:YesNoQuestion("This will remove the portal shape", function()
        if self._selected_shape == self._selected_portal._shapes[tonumber(item.parent.id)] then
            self._selected_shape = nil
        end
        self._selected_portal:remove_shape(self._selected_portal._shapes[tonumber(item.parent.id)])
        self:load_portal_shapes()
        self:save()        
    end)
end

function PortalLayer:add_portal(name)
    BLE.InputDialog:Show({title = "Portal name", text = type(name) == "string" and name or "group", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Portal name cannot be empty!", callback = function()
                self:add_portal(name)
            end})
            return
        elseif string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_portal(name)
            end})
            return
        elseif managers.portal:unit_groups()[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Portal with that name already exists!", callback = function()
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
    if self._units_visible == false then
        self:toggle_units_visible()
    end
    if noswitch ~= true then
        self._parent:Switch()
    end
    if self._parent._current_layer ~= "portal" then
        self._parent:build_menu("portal")
    end
    self._selected_shape = nil
    self._holder:GetItem("Shapes"):ClearItems("Shapes")
    self._holder:GetItem("Units"):ClearItems()
    if self._selected_portal then
        self._holder:GetItem("portal_"..self._selected_portal._name):SetBorder({left = false})
    end
    if self._selected_portal and self._selected_portal._name == name and nounselect ~= true then
        self._selected_portal = nil
    else
        self._holder:GetItem("portal_"..name):SetBorder({left = true})
        self._selected_portal = managers.portal:unit_groups()[name]
        self:load_portal_shapes()
        self:load_portal_units()
    end        
    self:select_shape()
    self:save()
end

function PortalLayer:clbk_select_portal(item)
    self:select_portal(item.text)
end

function PortalLayer:load_portal_shapes()
    local group = self._holder:GetItem("Shapes")
    if group then
        group:ClearItems("Shapes")
        for i=1, #self._selected_portal._shapes do
            local btn = group:button("shape_" .. tostring(i), ClassClbk(self, "select_shape"), {label = "Shapes"})
            btn.id = i
            btn:tb_imgbtn("Remove", ClassClbk(self, "remove_shape"), nil, BLE.Utils.EditorIcons.cross, {highlight_color = Color.red})
        end
    end
end

function PortalLayer:add_shape()
    self:do_spawn_unit(self._portal_shape_unit, {position = managers.editor:GetSpawnPosition(), portal = self._selected_portal})
    self:load_portal_shapes()
    self:save()
end

function PortalLayer:load_portals()
    local portals = self._holder:GetItem("Portals")
    if portals then
        portals:ClearItems("portals")
        for name, portal in pairs(managers.portal:unit_groups()) do
            local prtl = portals:button("portal_"..portal._name, ClassClbk(self, "clbk_select_portal"), {text = portal._name, label = "portals"})
            prtl:tb_imgbtn("Remove", ClassClbk(self, "remove_portal"), nil, BLE.Utils.EditorIcons.cross, {highlight_color = Color.red})
            prtl:tb_imgbtn("Rename", ClassClbk(self, "rename_portal"), nil, BLE.Utils.EditorIcons.pen)
            prtl:tb_imgbtn("AutoFillUnits", ClassClbk(self, "auto_fill_portal"), nil, BLE.Utils.EditorIcons.select)
        end
    end   
end

function PortalLayer:auto_fill_portal(item)
    local portal = managers.portal:unit_groups()[item.parent.text]
    BLE.Utils:YesNoQuestion("This will automatically fill the portal with units", function()
        for _, unit in pairs(managers.worlddefinition._all_units) do
            if alive(unit) and unit:visible() then
                local ud = unit:unit_data()
                if not ud.instance and not ud.only_visible_in_editor and not ud.only_exists_in_editor and not portal:unit_in_group(unit) and portal:inside(unit:position()) then
                    portal:add_unit_id(unit)
                end
            end
        end
        self:load_portal_units()
        self:save()
    end)
end

function PortalLayer:toggle_units_visible(item)
    if not self._selected_portal then
        return
    end

    self._units_visible = not self._units_visible
    for unit_id, _ in pairs(self._selected_portal._ids) do
        local unit = managers.worlddefinition:get_unit(unit_id)
        if unit and alive(unit) then
            unit:set_enabled(self._units_visible)
        end
    end
    if item then
        item.enabled_alpha = self._units_visible and 1 or 0.5
        item:SetEnabled(item.enabled)
    end
end
