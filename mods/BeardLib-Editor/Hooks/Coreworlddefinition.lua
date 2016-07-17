if Global.editor_mode then
core:module("CoreWorldDefinition")
WorldDefinition = WorldDefinition or class()
function WorldDefinition:init(params)
	managers.worlddefinition = self
	self._world_dir = params.world_dir
	self._cube_lights_path = params.cube_lights_path
	PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
	self:_load_world_package()
	self._definition = self:_serialize_to_script(params.file_type, params.file_path)
	self._world_data = self:_serialize_to_script(params.file_type, params.file_path)
	self._continent_definitions = {}
	self._continents = {}
	self._portal_slot_mask = World:make_slot_mask(1)
	self._massunit_replace_names = {}
	self._replace_names = {}
	self._replace_units_path = "assets/lib/utils/dev/editor/xml/replace_units"
	self:_parse_replace_unit()
	self._ignore_spawn_list = {}
	self._excluded_continents = {}
	self:_parse_world_setting(params.world_setting)
	self:parse_continents()
	managers.sequence:preload()
	PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
	self._all_units = {}
	self._trigger_units = {}
	self._name_ids = {}
	self._use_unit_callbacks = {}
	self._mission_element_units = {}
	self._termination_counter = 0
	self:create("ai")
end
function WorldDefinition:set_unit(unit_id, config, old_continent, new_continent)
	local continent_data = self._continent_definitions[old_continent]
	local new_continent_data = self._continent_definitions[new_continent]
	local move_continent = (old_continent ~= new_continent)
	if continent_data then
		for i, static in pairs(continent_data.statics) do
			if type(static) == "table" then
				if static.unit_data.unit_id == unit_id then
					for k,v in pairs(config) do
						static.unit_data[k] = v
					end
					if move_continent then
						continent_data.statics[i] = nil
						table.insert(new_continent_data.statics, static)
					end
					break
				end
			end
		end
	end
end
function WorldDefinition:insert_name_id(unit)
	local name = unit:unit_data().name
	self._name_ids[name] = self._name_ids[name] or {}
	local name_id = unit:unit_data().name_id
	self._name_ids[name][name_id] = (self._name_ids[name][name_id] or 0) + 1
end
function WorldDefinition:set_up_name_id(unit)
	if unit:unit_data().name_id ~= "none" then
		self:insert_name_id(unit)
	else
		unit:unit_data().name_id = self:get_name_id(unit)
	end				
	self:set_unit(unit:unit_data().unit_id, unit:unit_data(), unit:unit_data().continent, unit:unit_data().continent)
end
function WorldDefinition:get_name_id(unit, name)
	local u_name = unit:unit_data().name
	local start_number = 1
	if name then
		local sub_name = name
		for i = string.len(name), 0, -1 do
			local sub = string.sub(name, i, string.len(name))
			sub_name = string.sub(name, 0, i)
			if tonumber(sub) and tonumber(sub) < 10000 then
				start_number = tonumber(sub)
			else
				break
			end
		end
		name = sub_name
	else
		local reverse = string.reverse(u_name)
		local i = string.find(reverse, "/")
		name = string.reverse(string.sub(reverse, 0, i - 1))
		name = name .. "_"
	end
	self._name_ids[u_name] = self._name_ids[u_name] or {}
	local t = self._name_ids[u_name]
	for i = start_number, 10000 do
		i = (i < 10 and "00" or i < 100 and "0" or "") .. i
		local name_id = name .. i
		if not t[name_id] then
			t[name_id] = 1
			return name_id
		end
	end
end
function WorldDefinition:remove_name_id(unit)
	local unit_name = unit:unit_data().name
	if self._name_ids[unit_name] then
		local name_id = unit:unit_data().name_id
		self._name_ids[unit_name][name_id] = self._name_ids[unit_name][name_id] - 1
		if self._name_ids[unit_name][name_id] == 0 then
			self._name_ids[unit_name][name_id] = nil
		end
	end
end
function WorldDefinition:set_name_id(unit, name_id)
	local unit_name = unit:unit_data().name
	if self._name_ids[unit_name] then
		self:remove_name_id(unit)
		self._name_ids[unit_name][name_id] = (self._name_ids[unit_name][name_id] or 0) + 1
		unit:unit_data().name_id = name_id
	end
end
function WorldDefinition:get_unit_number(name)
	local i = 1
	for _, unit in pairs(World:find_units_quick("all")) do
		if unit:unit_data() and unit:unit_data().name == name then
			i = i + 1
		end
	end
	return i
end
function WorldDefinition:_continent_editor_only(data)
	return false
end
function WorldDefinition:init_done()
	if self._continent_init_packages then
		for _, package in ipairs(self._continent_init_packages) do
			self:_unload_package(package)
		end
	end
	self:_unload_package(self._current_world_init_package)
	managers.editor:load_continents(self._continent_definitions)
end

function WorldDefinition:delete_unit(unit)
	local unit_id = unit:unit_data().unit_id
	local name_id = unit:unit_data().name_id
	self:remove_name_id(unit)
	if unit_id ~= 1 then
		local continent = self._continent_definitions[unit:unit_data().continent]
		if continent then
			for k, static in pairs(continent.statics) do
				if static.unit_data and (static.unit_data.unit_id == unit_id or static.unit_data.name_id == name_id) then
					table.remove(continent.statics, k)
					managers.editor:Log("Removing.. " .. name_id .. "[" .. unit_id .. "]")

					return
				end
			end
		end
	end

end

function WorldDefinition:add_unit(unit, continent)
	table.insert(self._continent_definitions[continent].statics, {unit_data = unit:unit_data()})
end

function WorldDefinition:_set_only_visible_in_editor(unit, data)
	if unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor then
		unit:set_visible(_G.BeardLibEditor.Options:GetOption("Map/EditorUnits").value)
	end
end
function WorldDefinition:_setup_disable_on_ai_graph(unit, data)
	if not data.disable_on_ai_graph then
		return
	end
	unit:unit_data().disable_on_ai_graph = data.disable_on_ai_graph
end
function WorldDefinition:_setup_editor_unit_data(unit, data)
	unit:unit_data().name_id = data.name_id
	unit:unit_data().name = data.name
	unit:unit_data().continent = data.continent
	unit:unit_data().position = unit:position()
	unit:unit_data().rotation = unit:rotation()
	unit:unit_data().local_pos = Vector3(0, 0, 0)
	unit:unit_data().local_rot = Vector3(0, 0, 0)

	unit:unit_data().projection_lights = data.projection_lights
	self:set_up_name_id(unit)
end
function WorldDefinition:make_unit(data, offset)
	local name = data.name
	if self._ignore_spawn_list[Idstring(name):key()] then
		return nil
	end
	if table.has(self._replace_names, name) then
		name = self._replace_names[name]
	end
	if not name then
		return nil
	end
	if not is_editor and not Network:is_server() then
		local network_sync = PackageManager:unit_data(name:id()):network_sync()
		if network_sync ~= "none" and network_sync ~= "client" then
			return
		end
	end
	local unit
	if MassUnitManager:can_spawn_unit(Idstring(name)) and not is_editor then
		unit = MassUnitManager:spawn_unit(Idstring(name), data.position + offset, data.rotation)
	else
		unit = CoreUnit.safe_spawn_unit(name, data.position, data.rotation)
	end
	if unit then
		self:assign_unit_data(unit, data)
	elseif is_editor then
		local s = "Failed creating unit " .. tostring(name)
		Application:throw_exception(s)
	end
	if self._termination_counter == 0 then
		Application:check_termination()
	end
	self._termination_counter = (self._termination_counter + 1) % 100
	return unit
end
function WorldDefinition:assign_unit_data(unit, data)
	local is_editor = Global.editor_mode
	if unit:unit_data().only_exists_in_editor and not is_editor then
		self._ignore_spawn_list[unit:name():key()] = true
		unit:set_slot(0)
		return
	end
	unit:unit_data().instance = data.instance
	self:_setup_unit_id(unit, data)
	self:_setup_editor_unit_data(unit, data)
	if unit:unit_data().helper_type and unit:unit_data().helper_type ~= "none" then
		managers.helper_unit:add_unit(unit, unit:unit_data().helper_type)
	end
	self:_setup_lights(unit, data)
	self:_setup_variations(unit, data)
	self:_setup_editable_gui(unit, data)
	self:add_trigger_sequence(unit, data.triggers)
	self:_set_only_visible_in_editor(unit, data)
	self:_setup_cutscene_actor(unit, data)
	self:_setup_disable_shadow(unit, data)
	self:_setup_hide_on_projection_light(unit, data)
	self:_setup_disable_on_ai_graph(unit, data)
	self:_add_to_portal(unit, data)
	self:_setup_projection_light(unit, data)
	self:_setup_ladder(unit, data)
	self:_setup_zipline(unit, data)
	self:_project_assign_unit_data(unit, data)
end

function WorldDefinition:_setup_unit_id(unit, data)
	unit:unit_data().unit_id = tonumber(data.unit_id)
	unit:set_editor_id(unit:unit_data().unit_id)
	self._all_units[unit:unit_data().unit_id] = unit
	self:use_me(unit, Application:editor())

	if data.unit_id then
		self._largest_id = self._largest_id or 0
		if data.unit_id > self._largest_id then
			self._largest_id = data.unit_id
		end
	end
end

function WorldDefinition:GetNewUnitID()
	self._largest_id = self._largest_id + 1

	return self._largest_id
end
end