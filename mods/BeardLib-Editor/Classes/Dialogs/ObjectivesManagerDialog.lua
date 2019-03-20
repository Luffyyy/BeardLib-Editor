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
    local mod, data = project:get_mod_and_config()
    if data then
        local level = project:get_level_by_id(data, Global.game_settings.level_id)
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
        BeardLibEditor.Utils:Notify("Error", "Your map is not setuped correctly")
    end
    self._missing_units = {}
	local objectives = self:DivGroup("Objectives", {h = self._menu:ItemsHeight(), auto_height = false, scrollbar = true})
	local add = self._menu:SqButton("Add", ClassClbk(self, "rename_or_add_objective", false), {offset = 4, text = "+", position = "TopRightOffset-xy"})
    
    self:TextBox("Search", ClassClbk(BeardLibEditor.Utils, "FilterList", objectives), "", {w = 300, control_slice = 0.8, lines = 1, highlight_color = false, position = function(item)
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
    FileIO:WriteScriptData(self._objectvies_path, self._objectives, self._replacement_type)
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
    if self._objectives then
        for _, objective in ipairs(self._objectives) do
            if objective._meta == "objective" then
                local obj = self:Divider(objective.id, {group = objectives, label = "objectives"})
                obj:ImgButton("Remove", ClassClbk(self, "remove_objective", objective), nil, {184, 2, 48, 48})
                obj:ImgButton("Rename", ClassClbk(self, "rename_or_add_objective", objective), nil, {66, 1, 48, 48})
            end
        end
    end
end