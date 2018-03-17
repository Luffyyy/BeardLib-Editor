UndoUnitHandler = UndoUnitHandler or class()
core:import("CoreStack")

local UHandler = UndoUnitHandler

function UHandler:init()
    self._unit_data = {}
    self._undo_stack = CoreStack.Stack:new()
    self._redo_data = {}
    self._undo_history_size = BLE.Options:GetValue("UndoHistorySize")
end

function UHandler:SaveUnitValues(units, action_type)
    local jump_table = {
        pos = function(u) table.insert(self._unit_data[u:key()].pos, 1, u:unit_data()._prev_pos) end,
        rot = function(u)
            table.insert(self._unit_data[u:key()].rot, 1, u:unit_data()._prev_rot)
            table.insert(self._unit_data[u:key()].pos, 1, u:unit_data()._prev_pos)
        end
    }

    if self._undo_stack:size() > self._undo_history_size then
        local dif = self._undo_stack:size() - self._undo_history_size

        local last_element = self._undo_stack:stack_table()[1]
        for _, key in pairs(last_element[1]) do
            table.remove(self._unit_data[key].pos, #self._unit_data[key].pos)
            if last_element[2] == "rot" then
                table.remove(self._unit_data[key].rot, #self._unit_data[key].rot) -- slow and gay
            end
        end

		table.remove(self._undo_stack:stack_table(), 1, dif)

        self._undo_stack._last = self._undo_stack._last - dif
        managers.editor:Log("Stack history too big, removing elements")
    end

    local unit_keys = {}
    for _, unit in pairs(units) do
        table.insert(unit_keys, unit:key())
        if not self._unit_data[unit:key()] then
            self._unit_data[unit:key()] = {
                unit_data = unit,
                pos = {},
                rot = {}
            }
            jump_table[action_type](unit)                       -- ugly
        else
            jump_table[action_type](unit)
        end
    end
    local element = {unit_keys, action_type}
    self._undo_stack:push(element)
end

function UHandler:Undo()
    if self._undo_stack:is_empty() then
        managers.editor:Log("Undo stack is empty!")
        return
    end

    local element = self._undo_stack:pop()
    for _, key in pairs(element[1]) do
        self:restore_unit_pos_rot(key, element[2])
    end
end

function UHandler:set_redo_values(key)
--empty
end

function UHandler:restore_unit_pos_rot(key, action)
    local action_string = action == "rot" and "rotation " or "to position "
    local pos = table.remove(self._unit_data[key].pos, 1)
    local rot = action == "rot" and table.remove(self._unit_data[key].rot, 1) or nil
    local unit = self._unit_data[key].unit_data
    managers.editor:Log("Restoring unit " .. action_string .. tostring(rot or pos))
    BLE.Utils:SetPosition(unit, pos, rot)
end