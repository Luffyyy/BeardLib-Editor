ScriptSettingsDialog = ScriptSettingsDialog or class(MenuDialog)
ScriptSettingsDialog.type_name = "ScriptSettingsDialog"
function ScriptSettingsDialog:_Show(params)
    local p = table.merge({title = params.new and "New Script" or "Script Settings", yes = "Apply", no = "Cancel"}, params)
    if not self.super._Show(self, p) then
        return
    end
    local continent = params.continent
    local script = params.script
    local all_continents = managers.editor._continents
    self._script = script
    self._continent = continent
    self._new = params.new

    ItemExt:add_funcs(self)

    self:textbox("Name", callback(self, self, "SetName"), script, {index = 2, auto_focus = true})
    self:combobox("Continent", callback(self, self, "SetContinent"), all_continents, table.get_key(all_continents, continent) or 1, {index = 3})
    self:tickbox("ActivateOnParsed", nil,  params.new and true or managers.mission._missions[continent][script].activate_on_parsed, {index = 4, help = "Automatically activate this script when the level starts"})
end

function ScriptSettingsDialog:SetContinent(item)
    local continent = item:SelectedItem()

    if continent == self._continent then
        self._new_continent = nil
    else
        self._new_continent = continent
    end
end

function ScriptSettingsDialog:SetName(item)
    local name = item:Value()
    local warn = self:GetItem("NameWarning")
    if alive(warn) then
        warn:Destroy()
    end
    
    self._new_name = nil
    
    if name == "" then
        self:divider("NameWarning", {text = "Warning: Script name cannot be empty. Name will not be saved!", index = 2})
    elseif string.begins(name, " ") or string.match(name:sub(1, 1), "%d") then
        self:divider("NameWarning", {text = "Warning: Script name cannot begin with a space or a number. Name will not be saved!", index = 2})
    elseif managers.mission._missions[self._continent][name] then
        self:divider("NameWarning", {text = "Warning: Script name cannot be the same as an existing script. Name will not be saved!", index = 2})
    else
        self._new_name = name
    end
end

function ScriptSettingsDialog:hide(success)
    if success then
        if self._new then
            self:new_script()
        else
            self:modify_script()
        end
    end
    self._new = nil
    self._new_name = nil
    self._new_continent = nil
    self._script = nil
    self._continent = nil

    return ScriptSettingsDialog.super.hide(self, success)
end

function ScriptSettingsDialog:new_script()
    local mission = managers.mission
    
    local name = self._new_name
    local continent = self._new_continent or self._continent

    if name and not (name == "" or string.begins(name, " ") and mission._missions[continent][name]) then
        mission._missions[continent][name] = mission._missions[continent][name] or {
            activate_on_parsed = self:GetItem("ActivateOnParsed"):Value(),
            elements = {},
            instances = {}   
        }

        local data = clone(mission._missions[continent][name])
        data.name = name
        data.continent = continent
        if not mission._scripts[name] then
            mission:_add_script(data)
        end
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
    end
end

function ScriptSettingsDialog:modify_script()
    local mission = managers.mission

    local script = self._script
    local continent = self._continent
    
    local name = self._new_name
    local changed = false

    managers.mission._missions[continent][script].activate_on_parsed = self:GetItem("ActivateOnParsed"):Value()
    if name and not (name == "" or string.begins(name, " ") and mission._missions[continent][name]) then
        mission._scripts[script]._name = name
        mission._scripts[name] = mission._scripts[script]
        mission._scripts[script] = nil

        if managers.worlddefinition._continent_definitions[continent].instances then
            for _, instance in pairs(managers.worlddefinition._continent_definitions[continent].instances) do
                if instance.start_index and instance.script == script then
                    instance.script = name
                end
            end
        end

        for _, element in pairs(mission._missions[continent][script].elements) do
            if element and element.script and element.script == script then
                element.script = name
            end
        end

        changed = true
    end  

    if self._new_continent or changed then
        mission._missions[continent][script].name = name
        mission._missions[continent][script].continent = self._new_continent or continent
        mission._scripts[name or script]._continent = self._new_continent or continent
        mission._missions[self._new_continent or continent][name or script] = deep_clone(managers.mission._missions[continent][script])
        mission._missions[continent][script] = nil
        changed = true
    end
    
    if changed then
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
    end
end