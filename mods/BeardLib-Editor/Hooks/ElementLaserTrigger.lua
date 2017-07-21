if not Global.editor_mode then
    return
end

--Report if outdated.
function ElementLaserTrigger:init(...)
    ElementLaserTrigger.super.init(self, ...)
    self._brush = Draw:brush(Color(0.15, unpack(self.COLORS[self._values.color])))
    self._brush:set_blend_mode("opacity_add")
    self._last_project_amount_all = 0
    self._inside = {}
    self._connections = {}
    self._is_cycled = self._values.cycle_interval ~= 0
    self._next_cycle_t = 0
    self._cycle_index = 1
    self._cycle_order = {}
    self._slotmask = managers.slot:get_mask("persons")
    if self._values.instigator == "enemies" then
        self._slotmask = managers.slot:get_mask("enemies")
    elseif self._values.instigator == "civilians" then
        self._slotmask = managers.slot:get_mask("civilians")
    elseif self._values.instigator == "loot" then
        self._slotmask = World:make_slot_mask(14)
    end
    if not self._values.skip_dummies then
        self._dummy_units = {}
        self._dummies_visible = true
        self:remake_dummies()
    end
    for i, connection in ipairs(self._values.connections) do
        table.insert(self._cycle_order, i)
        table.insert(self._connections, {
            enabled = not self._is_cycled,
            from = self._values.points[connection.from],
            to = self._values.points[connection.to]
        })
    end
    if self._values.cycle_random then
        local cycle_order = clone(self._cycle_order)
        self._cycle_order = {}
        while #cycle_order > 0 do
            table.insert(self._cycle_order, table.remove(cycle_order, math.random(#cycle_order)))
        end
    end
end

function ElementLaserTrigger:remake_dummies()
    local temp = clone(self._dummy_units)
    self._dummy_units = {}
    for _, unit in pairs(temp) do
        unit:set_enabled(false)
        unit:set_slot(0)
        World:delete_unit(unit)		
    end
    for _, point in pairs(self._values.points) do
        local unit = safe_spawn_unit(Idstring("units/payday2/props/gen_prop_lazer_blaster_dome/gen_prop_lazer_blaster_dome"), point.pos, point.rot)
        local materials = unit:get_objects_by_type(Idstring("material"))
        for _, m in ipairs(materials) do
            m:set_variable(Idstring("contour_opacity"), 0)
        end
        table.insert(self._dummy_units, unit)
        point.pos = point.pos + point.rot:y() * 3
    end
end