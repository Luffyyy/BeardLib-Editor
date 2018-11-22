InstancesEditor = InstancesEditor or class(EditorPart)
local Instance = InstancesEditor

function Instance:init(parent, menu)
    self:init_basic(parent, name)
    self._stashed_instance_units = {}
    self._units = {}
    self._triggers = {}
    self._static = self:GetPart("static")
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
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:fake() then
            instance = instance or unit:object()
            local instances = managers.worlddefinition._continent_definitions[instance.continent].instances
            for _, mission in pairs(managers.mission._missions) do
                for _, script in pairs(mission) do
                    if script.instances then
                        table.delete(script.instances, instance.name)
                    end
                end
            end
            managers.mission:delete_links(instance.name, BeardLibEditor.Utils.LinkTypes.Instance)
            for i, ins in pairs(instances) do
                if ins.name == instance.name then
                    for _, unit in pairs(World:find_units_quick("all")) do
                        if unit:unit_data() and unit:unit_data().instance == instance.name then
                            managers.worlddefinition:delete_unit(unit, true)
                            World:delete_unit(unit)
                        end
                    end
                    for k, ins in pairs(managers.world_instance._instance_data) do
                        if instance.name == ins.name then
                            table.remove(managers.world_instance._instance_data, k)
                            self._stashed_instance_units[instance.name] = nil
                            break
                        end
                    end
                    table.remove(instances, i)
                    break
                end
            end
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
        if alive(unit) and unit:fake() then
            local instance = unit:object()
            local instance_name = instance.name
            for _, unit in pairs(World:find_units_quick("all")) do
                local ud = unit:unit_data()
                if ud and ud.instance == instance_name then
                    BeardLibEditor.Utils:SetPosition(unit, instance.position + ud.local_pos:rotate_with(instance.rotation), instance.rotation * ud.local_rot, ud)
                end
            end        
        end
    end
end

function Instance:update(item)
    if self:Value("HighlightInstances") then
        for _, instance_data in pairs(managers.world_instance:instances_data_by_continent(managers.editor._current_continent)) do
            local instance_units = self:get_instance_units_by_name(instance_data.name)

            Application:draw_sphere(instance_data.position, 50, 0.5, 0.5, 0.5)
        end
    end
    
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:fake() then
            self:_draw_instance(unit:object().name)
        end
    end
end

function Instance:_draw_instance(instance_name, r, g, b)
	r = r or 1
	g = g or 1
	b = b or 1
	local unit_brush = Draw:brush(Color(0.15, r, g, b))
    local instance_units = self:get_instance_units_by_name(instance_name)
            
    for _, unit in pairs(instance_units) do
        if alive(unit) then
            local ud = unit:unit_data()
            if ud and ud.instance and ud.instance == instance_name then
                Application:draw(unit, r, g, b)
                unit_brush:unit(unit)
            end
        end
    end
            
    local name_brush = Draw:brush(Color(r, g, b))

    name_brush:set_font(Idstring("fonts/font_medium"), 8)
    name_brush:set_render_template(Idstring("OverlayVertexColorTextured"))

    for _, element in pairs(managers.world_instance:prepare_mission_data_by_name(instance_name).default.elements) do
        unit_brush:set_color(Color(1, r, g, b))

        if element.values.position then
            unit_brush:sphere(element.values.position, 2, 2)

            if managers.viewport:get_current_camera() then
                local cam_up = managers.viewport:get_current_camera():rotation():z()
                local cam_right = managers.viewport:get_current_camera():rotation():x()

                name_brush:center_text(element.values.position + Vector3(0, 0, 25), utf8.from_latin1(element.editor_name), cam_right, -cam_up)
            end

            if element.values.rotation then
                local rotation = CoreClass.type_name(element.values.rotation) == "Rotation" and element.values.rotation or Rotation(element.values.rotation, 0, 0)

                unit_brush:set_color(Color(0.15, 1, 0, 0))
                unit_brush:cylinder(element.values.position, element.values.position + rotation:x() * 20, 1)
                unit_brush:set_color(Color(0.15, 0, 1, 0))
                unit_brush:cylinder(element.values.position, element.values.position + rotation:y() * 20, 1)
                unit_brush:set_color(Color(0.15, 0, 0, 1))
                unit_brush:cylinder(element.values.position, element.values.position + rotation:z() * 20, 1)
            end
        end
    end 
end

function Instance:get_instance_units_by_name(name)
    if self._stashed_instance_units[name] then
		return self._stashed_instance_units[name]
	end
    
    local units = World:find_units_quick('all', managers.slot:get_mask('statics', 'dynamics'))
    local t = {}
    for k, unit in pairs(units) do
        if alive(unit) then
            local ud = unit:unit_data()
            if ud and ud.instance and ud.instance == name then
                table.insert(t, unit)
            end
        end
    end

    self._stashed_instance_units[name] = t

    return t
end

function Instance:set_data(item)
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