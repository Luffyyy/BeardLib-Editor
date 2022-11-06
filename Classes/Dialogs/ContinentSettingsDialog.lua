ContinentSettingsDialog = ContinentSettingsDialog or class(MenuDialog)
ContinentSettingsDialog.type_name = "ContinentSettingsDialog"
function ContinentSettingsDialog:_Show(params)
    local p = table.merge({title = params.new and "New Continent" or "Continent settings", yes = "Apply", no = "Cancel"}, params)
    if not self.super._Show(self, p) then
        return
    end
    local continent = params.continent
    self._current = continent
    self._new = params.new
    ItemExt:add_funcs(self)

    local settings = params.new and {
        enabled_in_simulation = true,
        base_id = self:_new_base_id()
    } or managers.worlddefinition._continents[continent]
    self:textbox("Name", callback(self, self, "SetName"), continent, {index = 2, enabled = continent ~= "world", auto_focus = continent ~= "world"})
    self:tickbox("EnabledInPlaytesting", nil, settings.enabled_in_simulation ~= false, {index = 3})
    self:tickbox("Locked", callback(self, self, "SetLocked"), settings.locked, {index = 4})
    self:tickbox("EditorOnly", nil, settings.editor_only, {index = 5})
    self._menu:GetItem("Title"):lbl("BaseID", {text = "Base ID: "..settings.base_id, position = "RightCentery", size_by_text = true})
end

function ContinentSettingsDialog:SetName(item)
    local name = item:Value()
    local warn = self:GetItem("NameWarning")
    if alive(warn) then
        warn:Destroy()
    end
    
    self._new_name = nil
    
    if name == "" then
        self:divider("NameWarning", {text = "Warning: Continent name cannot be empty. Name will not be saved!", index = 2})
    elseif name == "environments" or string.begins(name, " ") or string.match(name:sub(1, 1), "%d") then
        self:divider("NameWarning", {text = "Warning: Continent name cannot begin with a space or a number, and cannot be the same as an existing level folder.\nName will not be saved!", index = 2})
    elseif managers.worlddefinition._continent_definitions[name] then
        self:divider("NameWarning", {text = "Warning: Continent name cannot be the same as an existing continent. Name will not be saved!", index = 2})
    else
        self._new_name = name
    end
end

function ContinentSettingsDialog:SetLocked(item)
    local locked = item:Value()
    local warn = self:GetItem("LockedWarning")
    if alive(warn) then
        warn:Destroy()
    end

    self._new_locked = nil
    local unlocked_continents = 0
    for _, data in pairs(managers.worlddefinition._continents) do
        if data.locked ~= true then
            unlocked_continents = unlocked_continents + 1
        end
    end

    local is_locked = managers.worlddefinition._continents[self._current] and managers.worlddefinition._continents[self._current].locked or false
    if locked and is_locked ~= true and unlocked_continents <= 1 then
        self:divider("LockedWarning", {text = "Warning: All other continents are locked, locked status will not be saved.", index = 2})
    else
        self._new_locked = locked
    end
end

function ContinentSettingsDialog:hide(success)
    if success then
        if self._new then
            self:new_continent()
        else
            self:modify_continent()
        end           
    end
    self._new_name = nil
    self._current = nil

    return ContinentSettingsDialog.super.hide(self, success)
end

function ContinentSettingsDialog:new_continent()
    local worlddef = managers.worlddefinition

    local mission = managers.mission
    local name = self._new_name

    if name and not (name == "" and name == "environments" or string.begins(name, " ") and worlddef._continent_definitions[name]) then
        mission._missions[name] = mission._missions[name] or {}
        worlddef._continent_definitions[name] = managers.worlddefinition._continent_definitions[name] or {
            editor_groups = {},
            statics = {},
            values = {workviews = {}}
        }
        worlddef._continents[name] = {
            base_id = self:_new_base_id(), 
            name = name,
            editor_only = self:GetItem("EditorOnly"):Value(),
            enabled_in_simulation = self:GetItem("EnabledInPlaytesting"):Value(),
            locked = self._new_locked
        }
    end

    managers.editor:load_continents(worlddef._continent_definitions)
end

function ContinentSettingsDialog:modify_continent()
    local worlddef = managers.worlddefinition

    local mission = managers.mission
    local continent = self._current
    local name = self._new_name

    worlddef._continents[continent].editor_only = self:GetItem("EditorOnly"):Value()
    worlddef._continents[continent].enabled_in_simulation = self:GetItem("EnabledInPlaytesting"):Value()
    if self._new_locked ~= nil then
        worlddef._continents[continent].locked = self._new_locked
    end
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
                        BLE:log("[Warning] Unit with no unit data inside continent")
                    end
                end
            end
        end
    end
    
    managers.editor:load_continents(worlddef._continent_definitions)
end

function ContinentSettingsDialog:_new_base_id()
	local i = managers.worlddefinition._start_id

	while not self:_base_id_availible(i) do
		i = i + managers.worlddefinition._start_id
	end

	return i
end

function ContinentSettingsDialog:_base_id_availible(id)
	for _, continent in pairs(managers.worlddefinition._continents) do
		if continent.base_id == id then
			return false
		end
	end

	return true
end