SpawnMenu = SpawnMenu or class(EditorPart)
function SpawnMenu:init(parent, menu)
    self.super.init(self, parent, menu, "Spawn Menu", {make_tabs = ClassClbk(self, "make_tabs"), scrollbar = false})
    self._tabs:s_btn("Unit", ClassClbk(self, "open_tab"), {border_bottom = true})
    self._tabs:s_btn("Element", ClassClbk(self, "open_tab"))
    self._tabs:s_btn("Instance", ClassClbk(self, "open_tab"))
    self._tabs:s_btn("Prefab", ClassClbk(self, "open_tab"))
    self._tab_classes = {
        Unit = UnitSpawnList:new(self),
        Element = ElementSpawnList:new(self),
        Instance = InstanceSpawnList:new(self),
        Prefab = PrefabSpawnList:new(self),
    }
    self._tab_classes.Unit:set_visible(true)
end

function SpawnMenu:make_tabs()
    
end

function SpawnMenu:open_tab(item)
    for name, tab in pairs(self._tab_classes) do
        tab:set_visible(name == item.name)
    end
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = tab == item})
    end
end

function SpawnMenu:begin_spawning(unit)
    if not PackageManager:has(Idstring("unit"), unit:id()) then
        return
    end
    self._currently_spawning = unit
    self:remove_dummy_unit()
    if self._parent._spawn_position then
        self._dummy_spawn_unit = World:spawn_unit(Idstring(unit or "units/mission_element/element"), self._parent._spawn_position)
    end
    self:GetPart("menu"):set_tabs_enabled(false)
    self:SetTitle("Press: LMB to spawn, RMB to cancel")
end

function SpawnMenu:get_dummy_unit()
    return self._dummy_spawn_unit
end

function SpawnMenu:mouse_pressed(button, x, y)
    if not self:enabled() then
        return
    end

    if button == Idstring("0") then
        if self._currently_spawning_element then
            self._do_switch = true
            self._parent:add_element(self._currently_spawning_element)
            return true
        elseif self._currently_spawning then
            self._do_switch = true
            local unit = self._parent:SpawnUnit(self._currently_spawning)
            self:GetPart("undo_handler"):SaveUnitValues({unit}, "spawn")
            return true
        end
    elseif button == Idstring("1") and (self._currently_spawning or self._currently_spawning_element) then
        self:remove_dummy_unit()
        self._currently_spawning = nil
        self._currently_spawning_element = nil
        self:SetTitle()
        self:GetPart("menu"):set_tabs_enabled(true)
        if self._do_switch and self:Val("SelectAndGoToMenu") then
            self:GetPart("static"):Switch()
            self._do_switch = false
        end
        return true
    end
    return false
end

function SpawnMenu:remove_dummy_unit()
    local unit = self._dummy_spawn_unit
    if alive(unit) then
        unit:set_enabled(false)
        unit:set_slot(0)
        World:delete_unit(unit)
    end
end

function SpawnMenu:is_spawning()
    return self._currently_spawning_element or self._currently_spawning
end

function SpawnMenu:update(t, dt)
    self.super.update(self, t, dt)

    if alive(self._dummy_spawn_unit) then
        self._dummy_spawn_unit:set_position(self._parent._spawn_position)
        if self._parent._current_rot then
            self._dummy_spawn_unit:set_rotation(self._parent._current_rot)
        end
        Application:draw_line(self._parent._spawn_position - Vector3(0, 0, 2000), self._parent._spawn_position + Vector3(0, 0, 2000), 0, 1, 0)
        Application:draw_sphere(self._parent._spawn_position, 30, 0, 1, 0)
    end
end