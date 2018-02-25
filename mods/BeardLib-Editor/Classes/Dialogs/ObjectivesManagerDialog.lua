ObjectivesManagerDialog = ObjectivesManagerDialog or class(MenuDialog)
ObjectivesManagerDialog.type_name = "ObjectivesManagerDialog"
ObjectivesManagerDialog._no_reshaping_menu = true
function ObjectivesManagerDialog:init(params, menu)
    if self.type_name == ObjectivesManagerDialog.type_name then
        params = params and clone(params) or {}
    end
    menu = menu or BeardLib.managers.dialog:Menu()
    local p = table.merge({
        w = 800,
        h = 400,
        auto_height = false,
        items_size = 20,
    }, params)
    ObjectivesManagerDialog.super.init(self, p, menu)
    MenuUtils:new(self)
end

function ObjectivesManagerDialog:_Show()
    if not self.super._Show(self, {yes = false}) then
        return
    end
    self._params = nil
    self._objectives = nil
    local project = BeardLibEditor.MapProject
    local mod = project:current_mod()
    local data = mod and project:get_clean_data(mod._clean_config)
    if data then
        local level = project:get_level_by_id(data, Global.game_settings.level_id)
        local sdm = level.script_data_mods
        if sdm then
            for _, mod in ipairs(sdm) do
                if mod._meta == "mod" and mod.target_ext == "objective" then
                    self._replacement_type = mod.replacement_type
                    self._objectvies_path = Path:Combine(project:current_path(), sdm.directory, mod.replacement)
                    self._objectives = FileIO:ReadScriptDataFrom(self._objectvies_path, self._replacement_type)
                    break
                end
            end
        end
    end
    if not self._objectives then
        self:hide()
        BeardLibEditor.Utils:Notify("Error", "Your map is not setuped correctly")
    end
    self._missing_units = {}
    local btn = self:Button("Close", callback(self, self, "hide", true), {position = "Bottom", count_height = true})
    local group_h = self._menu:Height() - 24
    local objectives = self:DivGroup("Objectives", {h = group_h - (btn:Height() + 8), auto_height = false, scrollbar = true})    
    local add = self:Button("Add", callback(self, self, "rename_or_add_objective", false), {override_panel = objectives, size_by_text = true, text = "+", position = function(item)
        item:SetPositionByString("TopRight")
        item:Panel():move(-8)
    end})
    self:TextBox("Search", callback(BeardLibEditor.Utils, BeardLibEditor.Utils, "FilterList"), "", {override_panel = objectives, w = 300, control_slice = 0.8, lines = 1, highlight_color = false, position = function(item)
        item:SetPositionByString("Top")
        item:Panel():set_world_right(add:Panel():world_left() - 4)
    end})

    self._menu:AlignItems(true)
    self:load_objectvies()
end

function ObjectivesManagerDialog:rename_or_add_objective(objective)
    BeardLibEditor.InputDialog:Show({title = "Objective Id", force = true, text = objective and objective.id or "", callback = function(name)
        for _, o in ipairs(self._objectives) do
            if o ~= objective and o.id == name then
                BeardLibEditor.Utils:Notify("Error!", "Objective with the Id "..tostring(name).. " already exists!")
                return
            end
        end
        if not objective then
            objective = {_meta = "objective", prio = 1, xp_weight = 1}
            table.insert(self._objectives, objective)
        end
        self:remove_previous_objectives()
        objective.id = name
        objective.text = name
        objective.description = name .. "_desc"
        self:save_and_reload()
    end})
end

function ObjectivesManagerDialog:remove_previous_objectives(objective)
    for _, objective in ipairs(self._objectives) do
        if objective._meta == "objective" and objective.id then
            managers.objectives._objectives[objective.id] = nil
        end
    end
end

function ObjectivesManagerDialog:remove_objective(objective)
    BeardLibEditor.Utils:YesNoQuestion("This will remove the objective", function()
        self:remove_previous_objectives()
        table.delete(self._objectives, objective)
        self:save_and_reload()
    end)
end

function ObjectivesManagerDialog:save_and_reload()
    FileIO:WriteScriptDataTo(self._objectvies_path, self._objectives, self._replacement_type)
    for _, objective in ipairs(self._objectives) do
        if objective._meta == "objective" then
            managers.objectives:_parse_objective(objective)
        end
    end
    self:load_objectvies()
end

function ObjectivesManagerDialog:load_objectvies()
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
    local opt = {items_size = 18, size_by_text = true, align = "center", texture = "textures/editor_icons_df", position = pos}
    for _, objective in ipairs(self._objectives) do
        if objective._meta == "objective" then
            opt.position = pos
            local obj = self:Divider(objective.id, {group = objectives, label = "objectives"})
            local btn = self:SmallImageButton("Remove", callback(self, self, "remove_objective", objective), nil, {184, 2, 48, 48}, obj, opt)
            opt.position = callback(WorldDataEditor, WorldDataEditor, "button_pos", btn)
            self:SmallImageButton("Rename", callback(self, self, "rename_or_add_objective", objective), nil, {66, 1, 48, 48}, obj, opt)
        end
    end
end