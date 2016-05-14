core:module("CoreWorldDefinition")
WorldDefinition = WorldDefinition or class()
function WorldDefinition:init(params)
	managers.worlddefinition = self
	self._world_dir = params.world_dir
	self._cube_lights_path = params.cube_lights_path
	PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
	self:_load_world_package()
	self._definition = self:_serialize_to_script(params.file_type, params.file_path)
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
	else
		_G.BeardLibEditor:log(tostring(unit_id))
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
	_G.BeardLibEditor.managers.MapEditor:load_continents(self._continent_definitions)
	self:_unload_package(self._current_world_init_package)
end

function WorldDefinition:delete_unit(unit)
	local unit_id = unit:unit_data().unit_id
	local name_id = unit:unit_data().name_id
	if unit_id ~= 1 then
		local continent = self._continent_definitions[unit:unit_data().continent]
		if continent then
			for k, static in pairs(continent.statics) do
				if static.unit_data and (static.unit_data.unit_id == unit_id or static.unit_data.name_id == name_id) then
					table.remove(continent.statics, k)
					_G.BeardLibEditor:log("Removing.. " .. name_id .. "[" .. unit_id .. "]")
					return
				end
			end
		end
	end
end

function WorldDefinition:add_unit(unit, continent)
	table.insert(self._continent_definitions[continent].statics, { unit_data = unit:unit_data()})
end

function WorldDefinition:_set_only_visible_in_editor(unit, data)
	if unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor then
		unit:set_visible(false)
	end
end
function WorldDefinition:_setup_disable_on_ai_graph(unit, data)
	if not data.disable_on_ai_graph then
		return
	end
	unit:unit_data().disable_on_ai_graph = data.disable_on_ai_graph
end
function WorldDefinition:assign_unit_data(unit, data)
	if not unit:unit_data() then
		Application:error("The unit " .. unit:name():s() .. " (" .. unit:author() .. ") does not have the required extension unit_data (ScriptUnitData)")
	end
	unit:unit_data().name_id = data.name_id
	unit:unit_data().name = data.name
	unit:unit_data().instance = data.instance
	self:_setup_unit_id(unit, data)
	self:_setup_editor_unit_data(unit, data)
	if unit:unit_data().helper_type and unit:unit_data().helper_type ~= "none" then
		managers.helper_unit:add_unit(unit, unit:unit_data().helper_type)
	end
	--[[if data.continent and is_editor then
		managers.editor:add_unit_to_continent(data.continent, unit)
	else]]--
	unit:unit_data().continent = data.continent

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
local is_editor = Application:editor()
function WorldDefinition:make_unit(data, offset)
	local name = data.name
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
	else
		local s = "Failed creating unit " .. tostring(name)
		log(tostring(s))
	end
	if self._termination_counter == 0 then
		Application:check_termination()
	end
	self._termination_counter = (self._termination_counter + 1) % 100

	return unit
end
 
function WorldDefinition:_setup_unit_id(unit, data)
	unit:unit_data().unit_id = data.unit_id
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
