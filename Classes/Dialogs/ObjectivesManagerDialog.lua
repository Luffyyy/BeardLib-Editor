ObjectivesManagerDialog = ObjectivesManagerDialog or class(MenuDialog)
ObjectivesManagerDialog.type_name = "ObjectivesManagerDialog"
ObjectivesManagerDialog._no_reshaping_menu = true
function ObjectivesManagerDialog:init(params, menu)
    if self.type_name == ObjectivesManagerDialog.type_name then
        params = params and clone(params) or {}
    end
    params.scrollbar = false
    menu = menu or BeardLib.managers.dialog:Menu()
    self._obj_info = menu:Menu(table.merge({
        name = "objinfo",
        visible = false,
        auto_foreground = true,
        w = 300,
        h = 500,
    }, params))
    ObjectivesManagerDialog.super.init(self, table.merge({
        w = 500,
        h = 500,
        position = function(item)
            if alive(self._obj_info) then
                item:SetPositionByString("Center")
                item:Panel():move(-self._obj_info:Width() / 2)
            end
        end,
        auto_height = false,
        items_size = 20,
    }, params), menu)
    self._obj_info:SetPosition(function(item)
        if alive(self._menu) then
            item:Panel():set_lefttop(self._menu:Panel():righttop())
        end
    end)
    self._menus = {self._obj_info}
    self._settings = ObjectiveSettingsDialog:new(BLE._dialogs_opt)
    ItemExt:add_funcs(self)
end

function ObjectivesManagerDialog:Destroy()
    ObjectivesManagerDialog.super.Destroy(self)
    self._settings:Destroy()
end

function ObjectivesManagerDialog:_Show()
    if not self.super._Show(self, {yes = false}) then
        return
    end
    self._params = nil
    self._objectives = nil
    local project = BLE.MapProject
    local mod, data = project:get_mod_and_config()
    if data then
        local level = project:get_level_by_id(data, Global.current_level_id)
        local sdm = level.script_data_mods
        if sdm then
            for _, mod in pairs(sdm) do
                if type(mod) == "table" and mod._meta == "mod" and mod.target_ext == "objective" then
                    self._replacement_type = mod.replacement_type
                    self._objectvies_path = Path:Combine(project:current_path(), sdm.directory, mod.replacement)
                    self._objectives = FileIO:ReadScriptData(self._objectvies_path, self._replacement_type)
                    break
                end
			end
        end
    end
    if not self._objectives then
        self:hide()
        BLE.Utils:Notify("Error", "Your map is not setup correctly")
    end
    self:remove_previous_objectives()
    local group_h = (self._menu:Height()) - 12
    local btn = self:button("Close", ClassClbk(self, "hide", true))

	local objectives = self:divgroup("Objectives", {h = group_h - (btn:Height() + 8), auto_align = false, auto_height = false, scrollbar = true})
    objectives:GetToolbar():textbox("Search", ClassClbk(BLE.Utils, "FilterList", objectives), "", {w = 300, control_slice = 0.8, lines = 1, highlight_color = false})
    btn:SetIndex(3)

    local manager = self._obj_info:divgroup("Actions")
    manager:button("AddNewObjective", ClassClbk(self, "edit_or_add_objective", false))
    manager:button("ClearObjectives", ClassClbk(self, "clear_all_objectives"))

    self._options = self._obj_info:divgroup("Options")
    local holder = self._options:holder("Holder", {offset = 0, visible = false})
    self._options:divider("NoObjective", {text = "No Objective Selected."})

    holder:textbox("id", ClassClbk(self, "set_objective_data"), "", {text = "Name", control_slice = 0.6})
    holder:numberbox("amount", ClassClbk(self, "set_objective_data"), 0, {text = "Amount", control_slice = 0.6, floats = 0})
    holder:tickbox("CustomId", ClassClbk(self, "toggle_autotext"), false, {text = "Custom Ids"})
    holder:textbox("text", ClassClbk(self, "set_objective_data"), "", {text = "Text Id", control_slice = 0.6, enabled = false})
    holder:textbox("description", ClassClbk(self, "set_objective_data"), "", {text = "Description Id", control_slice = 0.6, enabled = false})
    holder:button("CopyIds", ClassClbk(self, "open_clone_text_dialog"), {text = "Copy Ids from existing objective", enabled = false})
    holder:divider("TextLoc")
    holder:divider("DescriptionLoc")

    self._menu:AlignItems(true)
    self:load_objectives()
end

function ObjectivesManagerDialog:edit_or_add_objective(objective)
    self._settings:Show({objective = objective, objectives = self._objectives, force = true, callback = function()
        self:load_objectives()
    end})
end

function ObjectivesManagerDialog:open_clone_text_dialog(item)
    local list = {}
    for _, id in ipairs(managers.objectives:objectives_by_name()) do
        local objective = managers.objectives:get_objective(id)
        local data = {name = objective.text.. " ("..id..")", id = id, help = objective.description}
        table.insert(list, data)
    end

    BLE.ListDialog:Show({
        list = list,
        force = true,
        callback = ClassClbk(self, "clone_text_clbk")
    })

end

function ObjectivesManagerDialog:clone_text_clbk(item)
    BLE.ListDialog:hide()
    local list = PackageManager:script_data(managers.objectives.FILE_EXTENSION:id(), managers.objectives.PATH:id())

    for _, data in ipairs(list) do
		if data._meta == "objective" and data.id == item.id then
            self._selected_objective.text = data.text
            self._selected_objective.description = data.description
            self._options:GetItem("text"):SetValue(data.text)
            self._options:GetItem("description"):SetValue(data.description)
            self:update_localization()
            self:load_objectives()
            return
        end
    end
end

function ObjectivesManagerDialog:hide(yes, item)
    self:save_and_reload()
    self._selected_objective = nil

    ObjectivesManagerDialog.super.hide(self, yes, item)
end

function ObjectivesManagerDialog:set_objective_data(item)
    if self._selected_objective then
        local value = item:Value()
        if item.name == "id" then
            local warn = self._options:GetItem("NameWarning")
            if alive(warn) then
                warn:Destroy()
            end
            if value == "" then
                self._options:divider("NameWarning", {text = "Warning: Objective name cannot be empty.", index = 1})
                return
            else
                for _, o in ipairs(self._objectives) do
                    if o ~= self._selected_objective and o.id == value then
                        self._options:divider("NameWarning", {text = "Warning: Objective name already exists.", index = 1})
                        return
                    end
                end
            end
            if not self._options:GetItem("CustomId"):Value() then
                self._selected_objective.text = value
                self._selected_objective.description = value .. "_desc"
                self._options:GetItem("text"):SetValue(value)
                self._options:GetItem("description"):SetValue(value .. "_desc")
            end
        elseif item.name == "amount" and value == 0 then
            value = nil
        end
        self._selected_objective[item.name] = value

        BeardLib:AddDelayedCall("BLESetObjectiveData", 0.2, function()
            self:load_objectives()
            self:update_localization()
        end)
    end
end

function ObjectivesManagerDialog:update_localization()
    if self._selected_objective then
        local text = managers.localization:text(self._selected_objective.text)
        self._options:GetItem("TextLoc"):SetText("Localized text:\n"..text)
        local description = managers.localization:text(self._selected_objective.description)
        self._options:GetItem("DescriptionLoc"):SetText("Localized description:\n"..description)
    end
end

function ObjectivesManagerDialog:toggle_autotext(item)
    local enabled = item:Value()
    self._options:GetItem("text"):SetEnabled(enabled)
    self._options:GetItem("description"):SetEnabled(enabled)
    self._options:GetItem("CopyIds"):SetEnabled(enabled)
end

function ObjectivesManagerDialog:clear_all_objectives(item)
    BLE.Utils:YesNoQuestion("This will remove all objectives", function()
        self._objectives = {}
        self._selected_objective = nil
        self:load_objectives()
        self:set_objective_selected()
    end)
end


function ObjectivesManagerDialog:remove_previous_objectives()
    for _, objective in ipairs(self._objectives) do
        if objective._meta == "objective" and objective.id then
            managers.objectives._objectives[objective.id] = nil
        end
    end
end

function ObjectivesManagerDialog:remove_objective(objective)
    BLE.Utils:YesNoQuestion("This will remove the objective", function()
        table.delete(self._objectives, objective)
        self._selected_objective = nil
        self:load_objectives()
        self:set_objective_selected()
    end)
end

function ObjectivesManagerDialog:save_and_reload()
    if self._objectives then
        FileIO:WriteScriptData(self._objectvies_path, self._objectives, self._replacement_type)
        for _, objective in ipairs(self._objectives) do
            if objective._meta == "objective" then
                managers.objectives:_parse_objective(objective)
            end
        end
    end
end

function ObjectivesManagerDialog:load_objectives()
    local function base_button_pos(item)
        local p = item:Panel():parent()
        item:Panel():set_world_righttop(p:world_righttop())
    end
    local objectives = self:GetItem("Objectives")
    objectives:ClearItems("objectives")
    local function pos(item)
        local p = item:Panel():parent()
        item:Panel():set_world_righttop(p:world_righttop())
    end
    if self._objectives then
        for _, objective in ipairs(self._objectives) do
            if objective._meta == "objective" then
                local obj_name = managers.localization:text(objective.text)
                local obj = objectives:button(objective.id, ClassClbk(self, "set_objective_selected", objective), {text = obj_name.. " ("..objective.id..")", label = "objectives"})
                obj:tb_imgbtn("Remove", ClassClbk(self, "remove_objective", objective), nil, BLE.Utils:GetIcon("cross"))
                if self._selected_objective and self._selected_objective.id == objective.id then
                    self._tbl._selected = obj
                    obj:SetBorder({left = true})
                end
            end
        end
    end

    objectives:AlignItems(true)
end

function ObjectivesManagerDialog:set_objective_selected(objective, item)
    if self._tbl._selected then
        self._tbl._selected:SetBorder({left = false})
    end
    if self._tbl._selected == item then
        self._tbl._selected = nil
        self._selected_objective = nil
    else
        self._tbl._selected = item
        self._selected_objective = objective
        if item then
            item:SetBorder({left = true})
        end
    end

    local visible = false
    if self._tbl._selected then
        self._options:GetItem("id"):SetValue(objective.id)
        self._options:GetItem("text"):SetValue(objective.text)
        self._options:GetItem("description"):SetValue(objective.description)
        self._options:GetItem("amount"):SetValue(objective.amount)

        self:update_localization()
        visible = true
    end

    self._options:GetItem("Holder"):SetVisible(visible)

    self._options:GetItem("NoObjective"):SetVisible(not visible)
end