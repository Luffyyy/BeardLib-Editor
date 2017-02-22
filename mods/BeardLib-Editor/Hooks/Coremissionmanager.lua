if Global.editor_mode then
core:module("CoreMissionManager")
core:import("CoreMissionScriptElement")
core:import("CoreEvent")
core:import("CoreClass")
core:import("CoreDebug")
core:import("CoreCode")
core:import("CoreTable")
require("core/lib/managers/mission/CoreElementDebug")
MissionManager = MissionManager or CoreClass.class(CoreEvent.CallbackHandler)
function MissionManager:parse(params, stage_name, offset, file_type)
	local file_path, activate_mission
	if CoreClass.type_name(params) == "table" then
		file_path = params.file_path
		file_type = params.file_type or "mission"
		activate_mission = params.activate_mission
		offset = params.offset
	else
		file_path = params
		file_type = file_type or "mission"
	end
	CoreDebug.cat_debug("gaspode", "MissionManager", file_path, file_type, activate_mission)
	if not DB:has(file_type, file_path) then
		Application:error("Couldn't find", file_path, "(", file_type, ")")
		return false
	end
	local reverse = string.reverse(file_path)
	local i = string.find(reverse, "/")
	local file_dir = string.reverse(string.sub(reverse, i))
	local continent_files = self:_serialize_to_script(file_type, file_path)
	continent_files._meta = nil
	for name, data in pairs(continent_files) do
		if not managers.worlddefinition:continent_excluded(name) then
			self:_load_mission_file(name, file_dir, data)
		end
	end
	--self:_activate_mission(activate_mission)
	return true
end

function MissionManager:activate()
	if not self._activated then
		self._activated = true
		self:_activate_mission()
	end
end

function MissionManager:_load_mission_file(name, file_dir, data)
	self._missions = self._missions or {}
	local file_path = file_dir .. data.file
	local scripts = self:_serialize_to_script("mission", file_path)
	self._missions[name] = self:_serialize_to_script("mission", file_path) 
	for name, data in pairs(scripts) do	
		data.name = name
		self:_add_script(data)
	end
end

function MissionManager:set_element(element)
	for m_name, mission in pairs(self._missions) do
		for s_name, script in pairs(mission) do
			for i, s_element in pairs(script.elements) do
				if s_element.id == element.id then
					self._missions[m_name][s_name].elements[i] = element
					self._scripts[s_name]._elements[element.id]._values = element.values
				end
			end
		end
	end
end

function MissionManager:add_element(element)
	local module_name = "Core" .. element.class
	if rawget(_G, "CoreMissionManager")[module_name] then
		element.module = module_name 	
	end
	table.insert(self._missions["world"]["default"].elements, element)
	return self._scripts["default"]:create_element(element, true)
end

function MissionManager:delete_element(id)	
	self:delete_executors_of_element(element)
	for m_name, mission in pairs(self._missions) do
		for s_name, script in pairs(mission) do
			for i, element in pairs(script.elements) do
				if element.id == id then
					_G.BeardLibEditor:log("Deleting element %s in mission %s in script %s", tostring(element.editor_name), tostring(m_name), tostring(s_name))
					self._scripts[s_name]:delete_element(element)
					script.elements[i] = nil
					return
				end
			end
		end
	end
end

function MissionManager:execute_element(element)
	self._scripts["default"]:execute_element(element)
end

function MissionManager:get_executors_of_element(element)
	local executors = {}
	if element then
		for _, script in pairs(self._missions) do
			for _, tbl in pairs(script) do
				if tbl.elements then
					for i, script_element in pairs(tbl.elements) do
						if script_element.values.on_executed then
							for _, on_executed_element in pairs(script_element.values.on_executed) do									
								if on_executed_element.id == element.id then
									table.insert(executors, script_element)
								end
							end
						elseif script_element.values.elements then
							for _, _element in pairs(script_element.values.elements) do									
								if _element.id == element.id then
									table.insert(executors, script_element)
								end
							end							
						end
					end
				end
			end	
		end
	end
	return executors
end

function MissionManager:delete_executors_of_element(element)
	if element then
		for _, script in pairs(self._missions) do
			for _, tbl in pairs(script) do
				if tbl.elements then
					for i, script_element in pairs(tbl.elements) do
						if script_element.values.on_executed then
							for k, on_executed_element in pairs(script_element.values.on_executed) do									
								if on_executed_element.id == element.id then
									table.remove(script_element.values.on_executed, k)
								end
							end
						elseif script_element.values.elements then
							for k, _element in pairs(script_element.values.elements) do									
								if _element.id == element.id then
									table.remove(script_element.values.elements, k)
								end
							end
						end
					end
				end
			end	
		end
	end
end
 
function MissionManager:get_links(id)	
 	if not tonumber(id) or tonumber(id) <= 0 then
		return {}
	end
	local modifiers = {}
	local function search_table(element, tbl)
		for _, v in pairs(tbl) do
			if type(v) == "table" then
				search_table(element, v)
			elseif v == id then 
				table.insert(modifiers, element)
			end
		end
	end
	for _, script in pairs(self._missions) do
		for _, tbl in pairs(script) do
			if tbl.elements then
				for i, element in pairs(tbl.elements) do
					for k, element_data in pairs(element) do
						if type(element_data) == "table" and k ~= "id" then
							search_table(element, element_data)
						end
					end

				end
			end
		end
	end
	return modifiers
end

function MissionManager:get_mission_element(id)
	for _, script in pairs(self._missions) do
		for _, tbl in pairs(script) do
			if tbl.elements then
				for i, element in pairs(tbl.elements) do	
					if element.id == id then
						return element
					end
				end
			end
		end
	end
	return nil
end

function MissionManager:_add_script(data)
	self._scripts[data.name] = MissionScript:new(data)
end

function MissionScript:_create_elements(elements)
	local new_elements = {}
	for _, element in pairs(elements) do	
		new_elements[element.id] = self:create_element(element)
	end
	return new_elements
end

function MissionScript:create_element(element, return_unit)
	local class = element.class	
	local new_element = self:_element_class(element.module, class):new(self, element)

	new_element.class = element.class
	new_element.module = element.module
	self._elements[element.id] = new_element
	self._element_groups[class] = self._element_groups[class] or {}
	table.insert(self._element_groups[class], new_element)
	local new_unit = self:create_mission_element_unit(element)
	if return_unit then
		return new_unit
	end
	return new_element
end

function MissionScript:execute_element(element)
	self._elements[element.id]:on_executed(managers.player:player_unit())
end

function MissionScript:create_mission_element_unit(element)
	if not element.values.position then
		return 
	end
	local unit_name = "units/mission_element/element"
	if element.class == "ElementSpawnCivilian" then
		unit_name = "units/civilian_element/element"
	elseif element.class == "ElementSpawnEnemyDummy" then
		unit_name = "units/enemy_element/element"
	end
	element.values.position = element.values.position or Vector3()
	element.values.rotation = type(element.values.rotation) ~= "number" and element.values.rotation or Rotation(0,0,0)
	local unit = World:spawn_unit(Idstring(unit_name), element.values.position, element.values.rotation)
    unit:unit_data().position = element.values.position   
   	unit:unit_data().rotation = element.values.rotation 
    unit:unit_data().local_pos = Vector3()
    unit:unit_data().local_rot = Rotation()
	unit:mission_element().element = element
	if managers.editor then
		managers.editor.managers.mission:add_element_unit(unit)
	end
	return unit
end

function MissionScript:delete_element(element)
	self._elements[element.id]:set_enabled(false)
	self._elements[element.id] = nil
	self._element_groups[element.class] = nil
end

function MissionScript:_debug_draw(t, dt)
end

function MissionScript:debug_output(debug, color)
	if managers.editor then
		managers.editor.managers.console:LogMission(debug)
	end
end
end