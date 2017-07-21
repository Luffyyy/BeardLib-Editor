InstancesEditor = InstancesEditor or class(EditorPart)
local Instance = InstancesEditor

function Instance:init(parent, menu)
    self:init_basic(parent, name)
    self._units = {}
    self._triggers = {}
    self._static = self:Manager("static")
    MenuUtils:new(self, self._static:GetMenu())
end

function Instance:build_editor_menu()
    Instance.super.build_default_menu(self)
    self._editors = {}
    local other = self:Group("Main")    
    self._static:build_positions_items(true)
    self._static:SetTitle("Instance Selection")
    self:TextBox("Name", callback(self, self, "set_data"), nil, {group = other, help = "the name of the instance(make sure it's unique!)"})
    self:ComboBox("Continent", callback(self, self, "set_data"), self._parent._continents, 1, {group = other})
    self:ComboBox("Script", callback(self, self, "set_data"), table.map_keys(managers.mission._scripts), 1, {group = other})
    self:Toggle("MissionPlaced", callback(self, self, "set_data"), false, {group = other})
end

function Instance:set_instance(reset)
    self._static._built_multi = false
    if reset then
        self._static:reset_selected_units()
    end
    local unit = self:selected_unit()
    if alive(unit) and unit:fake() then
        if not reset then
            self:set_menu_unit(unit)
            return
        end
    end
    self._static:build_default_menu()
end

function Instance:delete_instance(instance)
    instance = instance or self:selected_unit():object()
    local instances = managers.worlddefinition._continent_definitions[instance.continent].instances
    for _, mission in pairs(managers.mission._missions) do
        for _, script in pairs(mission) do
            if script.instances then
                table.delete(script.instances, instance.name)
            end
        end
    end
    local script = managers.mission._scripts[instance.script]
    local temp = clone(script._elements)
    for i, element in pairs(temp) do
        if element.instance == instance.name then
            script._elements[i] = nil
            table.delete(script._element_groups[element.class], element)
        end
    end
    for i, ins in pairs(instances) do
        if ins.name == instance.name then
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:unit_data() and unit:unit_data().instance == instance.name then
                    managers.worlddefinition:delete_unit(unit)
                    World:delete_unit(unit)
                end
            end
            for k, ins in pairs(managers.world_instance._instance_data) do
                if instance.name == ins.name then
                    table.remove(managers.world_instance._instance_data, k)
                    break
                end
            end
            table.remove(instances, i)
            break
        end
    end
end

function Instance:set_menu_unit(unit)
    self:build_editor_menu()
    local instance = unit:object()
    self:GetItem("Name"):SetValue(instance.name, false, true)
    self:GetItem("MissionPlaced"):SetValue(instance.mission_placed)
    self:GetItem("Continent"):SetSelectedItem(instance.continent)
    self:GetItem("Script"):SetSelectedItem(instance.script)
    self._static:update_positions()
end

function Instance:update_positions()
    for _, unit in pairs(self:selected_units()) do
        if unit:fake() then
            local instance = unit:object()
            local instance_name = instance.name
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:unit_data() and unit:unit_data().instance == instance_name then
                    BeardLibEditor.Utils:SetPosition(unit, instance.position + unit:unit_data().local_pos:rotate_with(instance.rotation), instance.rotation * unit:unit_data().local_rot)
                end
            end        
        end
    end
end

function Instance:update(menu, item)
	local unit = self:selected_unit()
	if unit and alive(unit) and unit:fake() then
		Application:draw_sphere(unit:position(), 30, 0, 0, 0.7)
	end
end

function Instance:set_data(menu, item)
    local main = self:GetItem("Main")
    main:RemoveItem(self:GetItem("NameWarning"))
    local instance = self:selected_unit():object()
    local instance_in_continent
    local instance_in_continent_index
    local instance_in_script_mission
    local instance_in_script_index
    local new_name = self:GetItem("Name"):Value()
    local no_saving_name
    local continents = managers.worlddefinition._continent_definitions
    for name, continent in pairs(continents) do
        continent.instances = continent.instances or {}
        for i, ins in pairs(continent.instances) do
            if instance.name ~= new_name and ins.name == new_name then
                no_saving_name = true
                self:Divider("NameWarning", {group = main, index = "After|Name", text = "*Warning: name is taken by a different instance", color = false})
            end
            if name == instance.continent and ins.name == instance.name and not instance_in_continent then
                instance_in_continent = ins
                instance_in_continent_index = i
                break
            end
        end
    end
    for _, mission in pairs(managers.mission._missions) do
        for _, script in pairs(mission) do
            if script.instances then
                local index = table.get_key(script.instances, instance.name)
                if index then
                    instance_in_script_mission = script
                    instance_in_script_index = index
                    break
                end
            end
        end
    end
    if instance_in_continent then
        local old_continent = instance.continent
        local old_script = instance.script
        local old_name = instance.name
        if not no_saving_name then
            instance.name = new_name
        end
        instance.continent = self:GetItem("Continent"):SelectedItem()
        instance.script = self:GetItem("Script"):SelectedItem()
        instance.mission_placed = self:GetItem("MissionPlaced"):Value()
        instance_in_continent.name = instance.name
        instance_in_continent.mission_placed = instance.mission_placed
        instance_in_continent.continent = instance.continent
        instance_in_continent.script = instance.script
        if old_continent ~= instance.continent then
            table.remove(continents[old_continent].instances, instance_in_continent_index)
            table.insert(continents[instance.continent].instances, instance_in_continent)
        end
        if instance_in_script_mission then
            instance_in_script_mission.instances[instance_in_script_index] = instance.name
            if old_script ~= instance.script then
                table.remove(instance_in_script_mission.instances, instance_in_script_index)
                local script = managers.mission._scripts[old_script]
                local temp = clone(script._element)
                for i, element in pairs(temp) do
                    if element.instance == instance.name then
                        script._element[i] = nil
                        table.delete(script._element_groups[element.class], element)
                    end
                end
                for _, mission in pairs(managers.mission._missions) do
                    if mission[instance.script] then
                        table.insert(mission[instance.script].instances, instance.name)
                        local script = managers.mission._scripts[instance.script]
                        local prepare_mission_data = managers.world_instance:prepare_mission_data_by_name(instance_name)
                        if not instance.mission_placed then
                            script:create_instance_elements(prepare_mission_data)
                        else
                            script:_preload_instance_class_elements(prepare_mission_data)
                        end
                        break
                    end
                end
            end
        end
        for _, unit in pairs(World:find_units_quick("all")) do
            if unit:unit_data() and unit:unit_data().instance == old_name then
                unit:unit_data().instance = instance.name
                unit:unit_data().continent = instance.continent
            end
        end
    else
        BeardLibEditor:log("[Error] This is not a valid instance")
    end
end