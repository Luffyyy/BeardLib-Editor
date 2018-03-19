UndoUnitHandler = UndoUnitHandler or class(EditorPart)
core:import("CoreStack")

local UHandler = UndoUnitHandler

function UHandler:init(parent, menu)
    self._parent = parent
    self._triggers = {}
    self._unit_data = {}
    self._undo_stack = CoreStack.Stack:new()
    self._redo_data = {}
    self._undo_history_size = math.floor(BLE.Options:GetValue("UndoHistorySize"))
end

function UHandler:SaveUnitValues(units, action_type)

    if self._undo_stack:size() > self._undo_history_size then
        local dif = self._undo_stack:size() - self._undo_history_size

        local last_element = self._undo_stack:stack_table()[1]
        for _, key in pairs(last_element[1]) do
            table.remove(self._unit_data[key].pos, #self._unit_data[key].pos)
            if last_element[2] == "rot" then
                table.remove(self._unit_data[key].rot, #self._unit_data[key].rot) -- slow and gay
            end
            if last_element[2] == "delete" then
                table.remove(self._unit_data[key].rot, #self._unit_data[key].rot) -- maybe keep track of the last unit id maually
                table.remove(self._unit_data[key].unit_data, #self._unit_data[key].unit_data)
            end
        end

		table.remove(self._undo_stack:stack_table(), 1, dif)

        self._undo_stack._last = self._undo_stack._last - dif
        self._parent:Log("Stack history too big, removing elements")
    end

    local unit_keys = {}
    for _, unit in pairs(units) do
        if alive(unit) and not unit:fake() then
            table.insert(unit_keys, unit:key())
            if not self._unit_data[unit:key()] then
                self._unit_data[unit:key()] = {
                    unit = unit,
                    unit_data = {},
                    pos = {},
                    rot = {}
                }
            end -- spawn does nothing, always save pos, only save rot if needed. Made this instead of a table, not very readable
            if action_type ~= "spawn" then table.insert(self._unit_data[unit:key()].pos, 1, unit:unit_data()._prev_pos) end
            if action_type == "rot" then table.insert(self._unit_data[unit:key()].rot, 1, unit:unit_data()._prev_rot) end
            if action_type == "delete" then self:build_unit_data(unit) end

        end
    end

    local element = {unit_keys, action_type}
    self._undo_stack:push(element)
end

function UHandler:Undo()
    if self._undo_stack:is_empty() then
        self._parent:Log("Undo stack is empty!")
        return
    end

    local jump_table = {
        pos = function(k, a) self:restore_unit_pos_rot(k, a) end,
        rot = function(k, a) self:restore_unit_pos_rot(k, a) end,
        delete = function(k, a) self:restore_unit(k) end,
        spawn = function(k, a) self:delete_unit(k) end
    }
    local element = self._undo_stack:pop()
    for _, key in pairs(element[1]) do
        jump_table[element[2]](key, element[2])
    end

end

function UHandler:set_redo_values(key)
--empty
end

function UHandler:build_unit_data(unit)
    local typ = unit:mission_element() and "element" or not unit:fake() and "unit" or "unsupported"
    local copy = {
        type = typ,
        mission_element_data = typ == "element" and unit:mission_element().element and deep_clone(unit:mission_element().element) or nil,
        unit_data = typ == "unit" and unit:unit_data() and deep_clone(unit:unit_data()) or nil,
        wire_data = typ == "unit" and unit:wire_data() and deep_clone(unit:wire_data()) or nil,
        ai_editor_data = typ == "unit" and unit:ai_editor_data() and deep_clone(unit:ai_editor_data()) or nil
    }

    table.insert(self._unit_data[unit:key()].unit_data, 1, copy)
    table.insert(self._unit_data[unit:key()].rot, 1, unit:rotation())
end

function UHandler:restore_unit_pos_rot(key, action)
    local unit = self._unit_data[key].unit
    if alive(unit) then
        local pos = table.remove(self._unit_data[key].pos, 1)
        local rot = action == "rot" and table.remove(self._unit_data[key].rot, 1) or nil
        BLE.Utils:SetPosition(unit, pos, rot)
        self:GetPart("static"):set_units()
    end
end

function UHandler:restore_unit(key)
    local unit = self._unit_data[key].unit
    if not alive(unit) then
        local unit_data = self._unit_data[key].unit_data[1].unit_data
        if not unit_data then self._parent:Log("Element restoration is unhandled, skipping") return end
        local pos = table.remove(self._unit_data[key].pos, 1)   -- workaround for the unit itself being deleted
        local rot = table.remove(self._unit_data[key].rot, 1)   -- need to change some stuff in SpawnUnit 
        local new_unit = self._parent:SpawnUnit(unit_data.name, nil, false, unit_data.unit_id)
        BLE.Utils:SetPosition(new_unit, pos, rot)
        table.remove(self._unit_data[key].unit_data, 1)
    end
end

function UHandler:delete_unit(key)
    local unit = self._unit_data[key].unit
    if alive(unit) then
        self._parent:DeleteUnit(unit)
        self:GetPart("static"):reset_selected_units()
    end
end