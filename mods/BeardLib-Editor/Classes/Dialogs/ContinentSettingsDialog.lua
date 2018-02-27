ContinentSettingsDialog = ContinentSettingsDialog or class(MenuDialog)
ContinentSettingsDialog.type_name = "ContinentSettingsDialog"
function ContinentSettingsDialog:_Show(params)
    local p = table.merge({title = "Continent settings", yes = "Apply", no = "Cancel"}, params)
    if not self.super._Show(self, p) then
        return
    end
    local continent = params.continent
    self._current = continent
    MenuUtils:new(self)
    self:TextBox("Name", callback(self, self, "SetName"), continent, {index = 2})
    self:Toggle("EditorOnly", nil, managers.worlddefinition._continents[continent].editor_only, {index = 3})
end

function ContinentSettingsDialog:SetName(menu, item)
    local name = item:Value()
    self._new_name = nil
    if name == "" then
        self:Divider("NameWarning", {text = "Warning: Continent name cannot be empty, name will not be saved."})
    elseif name == "environments" or string.begins(name, " ") then
        self:Divider("NameWarning", {text = "Warning: Continent name cannot begin with a space or be named as an existing level folder, name will not be saved."})
    elseif managers.worlddefinition._continent_definitions[name] then
        self:Divider("NameWarning", {text = "Warning: Continent name already exists, name will not be saved."})
    else
        local warn = self:GetItem("NameWarning")
        if alive(warn) then
            warn:Destroy()
        end
        self._new_name = name
    end
end

function ContinentSettingsDialog:hide(success)
    local worlddef = managers.worlddefinition
    if success then
        local mission = managers.mission
        local continent = self._current
        local name = self._new_name

        worlddef._continents[continent].editor_only = self:GetItem("EditorOnly"):Value()
        if name and not (name == "" and name == "environments" or string.begins(name, " ") and worlddef._continent_definitions[name]) then
            worlddef._continents[continent].name = name
            worlddef._continent_definitions[name] = deep_clone(worlddef._continent_definitions[continent])
            mission._missions[name] = mission._missions[continent]
            worlddef._continents[name] = worlddef._continents[continent]
            worlddef._continent_definitions[continent] = nil
            mission._missions[continent] = nil
            worlddef._continents[continent] = nil
            for _, script in pairs(mission._scripts) do
                if script._continent == continent then
                    script._continent = name
                end
            end
            for k, static in pairs(worlddef._continent_definitions[name].statics) do
                if static.unit_data and static.unit_data.unit_id then
                    static.unit_data.continent = name
                    local unit = worlddef:get_unit_on_load(static.unit_data.unit_id)
                    if alive(unit) then
                        local ud = unit:unit_data()
                        if ud then
                            ud.continent = name
                        else
                            BeardLibEditor:log("[Warning] Unit with no unit data inside continent")
                        end
                    end
                end
            end
        end
    end    
    
    managers.editor:load_continents(worlddef._continent_definitions)

    self._new_name = nil
    self._current = nil

    return ContinentSettingsDialog.super.hide(self, success)
end