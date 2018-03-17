UndoUnitHandler = UndoUnitHandler or class()
core:import("CoreStack")

local UHandler = UndoUnitHandler

function UHandler:init()
    self._unit_data = {}
    self._undo_stack = CoreStack.Stack:new()
    self._redo_stack = CoreStack.Stack:new()
    self._undo_history_size = BLE.Options:GetValue("UndoHistorySize")
end

function UHandler:SaveUnitValues(units, action_type)
    local jump_table = {
        pos = function(u) table.insert(self._unit_data[u:key()].pos, 1, u:unit_data()._prev_pos) end,  -- I have to insert them into the first pos as
        rot = function(u) table.insert(self._unit_data[u:key()].rot, 1, u:unit_data()._prev_rot) end   -- to make it easier to get the first inserted element
    }

    if self._undo_stack:size() > self._undo_history_size then
        local dif = self._undo_stack:size() - self._undo_history_size

		table.remove(self._undo_stack:stack_table(), 1, dif)

        self._undo_stack._last = self._undo_stack._last - dif
        managers.editor:Log("Stack history too big, removing elements")
    end                                                         -- TODO also remove the last unit value based on the last action in undo_stack

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
    local jump_table = {
        pos = function(k) self:restore_unit_pos(k) end,
        rot = function(k) self:restore_unit_rot(k) end
    }
    if not self._undo_stack:is_empty() then
        local element = self._undo_stack:pop()
        for _, key in pairs(element[1]) do
            jump_table[element[2]](key)
        end
        self._redo_stack:push(element)
    else managers.editor:Log("Undo stack is empty!")
    end

end

function UHandler:restore_unit_pos(key)    -- with the current implementation i have to have 2 different methods for unit restore
    local pos = table.remove(self._unit_data[key].pos, 1)
    managers.editor:Log("Restoring unit to position: " .. tostring(pos))
    local unit = self._unit_data[key].unit_data
    BLE.Utils:SetPosition(unit, pos)
end

function UHandler:restore_unit_rot(key)     -- unit rotation is completely fucked, and causes dumb crashes
    local pos = self._unit_data[key].pos[1]
    local rot = table.remove(self._unit_data[key].rot, 1)
    managers.editor:Log("Restoring unit rotation: " .. tostring(rot))
    local unit = self._unit_data[key].unit_data
    BLE.Utils:SetPosition(unit, pos, rot)
end