ObjectiveSettingsDialog = ObjectiveSettingsDialog or class(MenuDialog)
ObjectiveSettingsDialog.type_name = "ObjectiveSettingsDialog"
function ObjectiveSettingsDialog:_Show(params)
    local p = table.merge({title = "Objective "..  (params.objective and "Settings" or "Creation"), yes = "Apply", no = "Cancel"}, params)
    if not self.super._Show(self, p) then
        return
    end
    if not params.objective then
        self._add_current = true
    end
    local objective = params.objective and clone(params.objective) or {_meta = "objective", id = ""}
    self._current = objective
    self._to_update = params.objective
    self._objectives = params.objectives
    ItemExt:add_funcs(self)
    self:textbox("Name", ClassClbk(self, "SetName"), objective.id, {index = 2})
    local amount = self:numberbox("Amount", ClassClbk(self, "SetAmount"), objective.amount or 0, {floats = 0, index = 3})
    amount:tickbox("AmountEnabled", ClassClbk(self, "SetAmount"), objective.amount ~= nil, {
        text = "Use", help = "Enable amount setting? Sets the amount of the objective", size_by_text = true, offset = 0
    })
end

function ObjectiveSettingsDialog:SetName(item)
    local name = item:Value()
    local warn = self:GetItem("NameWarning")
    if alive(warn) then
        warn:Destroy()
    end
    if name == "" then
        self:divider("NameWarning", {text = "Warning: Objective name cannot be empty, name will not be saved.", index = 2})
    else
        for _, o in ipairs(self._objectives) do
            if o ~= self._current and o.id == name then
                self:divider("NameWarning", {text = "Warning: Objective name already exists, name will not be saved.", index = 2})
                return
            end
        end
        self._current.id = name
        self._current.text = name
        self._current.description = name .. "_desc"
    end
end

function ObjectiveSettingsDialog:SetAmount(item)
    local amount = self:GetItem("Amount")
    self._current.amount = amount:GetItem("AmountEnabled"):Value() and amount:Value() or nil
end

function ObjectiveSettingsDialog:hide(success)
    if success and self._current.id ~= "" then
        if self._add_current then
            table.insert(self._objectives, self._current)
        end
        if self._to_update then
            self._to_update.id = self._current.id
            self._to_update.text = self._current.text
            self._to_update.description = self._current.description
            self._to_update.amount = self._current.amount
        end
    end
    
    self._add_current = nil
    self._to_update = nil
    self._current = nil
    return ObjectiveSettingsDialog.super.hide(self, success)
end