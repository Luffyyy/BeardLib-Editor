UndoUnitHandler = UndoUnitHandler or class(EditorPart)
local UHandler = UndoUnitHandler

function UHandler:init(parent, menu)
    self._parent = parent
    self._triggers = {}
    
    self._history = {}
    self._undo_history_size = math.floor(BLE.Options:GetValue("UndoHistorySize"))

    self._undo_funcs = {
        pos = function(k) self:undo_unit_pos_rot(k) end,
        rot = function(k) self:undo_unit_pos_rot(k) end,
        delete = function(k) self:restore_unit(k) end,
        spawn = function(k) self:delete_unit(k) end
    }
    
    self._redo_funcs = {
        pos = function(k) self:redo_unit_pos_rot(k) end,
        rot = function(k) self:redo_unit_pos_rot(k) end,
        delete = function(k) self:delete_unit(k) end,
        spawn = function(k) self:restore_unit(k) end
    }

    self._static = self:GetPart("static")
end

function UHandler:enable()
    UHandler.super.enable(self)
    self:bind_opt("Redo", ClassClbk(self, "Redo"))
    self:bind_opt("Undo", ClassClbk(self, "Undo"))
end

function UHandler:SaveUnitValues(units, action_type)
    local event_tbl = {}
    local selected_units = self:selected_units()
    for _, unit in pairs(units) do
        if alive(unit) and not unit:fake() then
            if action_type == "pos" then
                table.insert(event_tbl, {
                    unit = unit,
                    pos = unit:position(), prev_pos = unit:unit_data()._prev_pos,
                    rot = unit:rotation(), prev_rot = unit:unit_data()._prev_rot
                })
            elseif action_type == "delete" or action_type == "spawn" then
                table.insert(event_tbl, {unit = unit, was_selected = table.contains(selected_units, unit), copy_data = self:build_unit_data(unit)})
            end
        end
    end
    if self._history_point then --Uh oh! YOU'VE CHANGED THE PAST
        local new_history = {}
        for i, event in pairs(self._history) do
            if i<self._history_point then
                table.insert(new_history, event)
            end
        end
        self._history = new_history
        self._history_point = nil --no more time traveling
    end
    table.insert(self._history, {action_type = action_type, event_tbl = event_tbl})
    if #self._history == self._undo_history_size then
        table.remove(self._history, 1)
    end
end

function UHandler:GetPoint()
    return self._history_point or #self._history + 1
end

function UHandler:Undo()
    if #self._history == 0 then
        self._parent:Log("History table empty!")
        return
    elseif self._history_point == 1 then
        self._parent:Log("Nothing to undo!")
        return        
    end

    self._history_point = self:GetPoint()-1
    
    local point = self._history[self._history_point]
    local action_type = point.action_type
    if action_type == "spawn" then
        self._static:set_unit(true)
    end
    for _, event in pairs(point.event_tbl) do
        self._undo_funcs[action_type](event)
    end

    self._static:recalc_all_locals()
    self._static:update_positions()
end

function UHandler:Redo()
    if #self._history == 0 then
        self._parent:Log("History table empty!")
        return
    elseif not self._history_point then
        self._parent:Log("Nothing to redo!")
        return
    end

    local point = self:GetPoint()
    if point == #self._history then
        self._history_point = nil
    else
        self._history_point = point+1
    end

    local point = self._history[point]
    local action_type = point.action_type
    if action_type == "spawn" then
        self._static:set_unit(true)
    end
    for _, event in pairs(point.event_tbl) do
        self._redo_funcs[action_type](event)
    end

    self._static:recalc_all_locals()
    self._static:update_positions()
end

function UHandler:build_unit_data(unit)
    local typ = unit:mission_element() and "element" or not unit:fake() and "unit" or "unsupported"
    return {
        type = typ,
        mission_element_data = typ == "element" and unit:mission_element().element and deep_clone(unit:mission_element().element) or nil,
        unit_data = typ == "unit" and unit:unit_data() and deep_clone(unit:unit_data()) or nil,
        wire_data = typ == "unit" and unit:wire_data() and deep_clone(unit:wire_data()) or nil,
        ai_editor_data = typ == "unit" and unit:ai_editor_data() and deep_clone(unit:ai_editor_data()) or nil
    }
end

function UHandler:redo_unit_pos_rot(event)
    local unit = event.unit
    if alive(unit) then
        BLE.Utils:SetPosition(unit, event.pos, event.rot, unit:unit_data())
		local static = self._static
		static:set_units()
		static:update_positions()
    end
end

function UHandler:undo_unit_pos_rot(event)
    local unit = event.unit
    if alive(unit) then
		BLE.Utils:SetPosition(unit, event.prev_pos or unit:position(), event.prev_rot, unit:unit_data())
		local static = self._static
		static:set_units()
		static:update_positions()
    end
end

function UHandler:restore_unit(event)
    local copy_data = event.copy_data
    if copy_data.type == "element" then
        self:GetPart("mission"):add_element(copy_data.mission_element_data.class, false, copy_data.mission_element_data)
        self._static:build_links(copy_data.mission_element_data.id, BLE.Utils.LinkTypes.Element, copy_data.mission_element_data)
    else
        local new_unit = self._parent:SpawnUnit(copy_data.unit_data.name, copy_data.unit_data, event.was_selected, copy_data.unit_id)
        event.unit = new_unit
        BLE.Utils:SetPosition(new_unit, copy_data.unit_data.position, copy_data.unit_data.rotation)
        BLE.Utils:SetPosition(new_unit, copy_data.unit_data.position, copy_data.unit_data.rotation) --No clue why this fails sometimes (doesn't update the collision)
    end
end

function UHandler:delete_unit(event)
    local unit = event.unit
    if alive(unit) then
        self._parent:DeleteUnit(unit)
        self._static:set_unit(true)
    end
end