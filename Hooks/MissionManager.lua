if not Global.editor_mode then
	return
end

local BeardLibEditor = BeardLibEditor
local Utils = BeardLibEditor.Utils

core:module("CoreMissionManager")
core:import("CoreMissionScriptElement")
core:import("CoreEvent")
core:import("CoreClass")
core:import("CoreDebug")
core:import("CoreCode")
core:import("CoreTable")
require("core/lib/managers/mission/CoreElementDebug")
local Mission = MissionManager
function Mission:parse(params, stage_name, offset, file_type)
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
	self._activate_script = activate_mission
	Utils:GetPart("mission"):set_elements_vis()
	return true
end

Hooks:PostHook(Mission, "post_init", "EditorSetDebugGUI", function(self)
	local fdo = self._fading_debug_output:script()
	Hooks:PostHook(fdo, "add_row", "EditorAddRow", function(text, color)
		if not alive(fdo.main_panel) then
			return
		end
		for _, c in pairs(fdo.main_panel:children()) do
			for _, text in pairs(c:children()) do
				text:configure({
					font = _G.tweak_data.menu.pd2_large_font,
					font_size = fdo.FONT_SIZE
				})
				local _,_,w,h = text:text_rect()
				c:set_size(w,h)
			end
		end
	end)
end)

Hooks:PostHook(MissionManager, "_show_debug_subtitle", "ChangeDebugSubtitleFont", function(self)
	if alive(self._debug_subtitle_text) then
		self._debug_subtitle_text:configure({font = _G.tweak_data.menu.pd2_large_font, font_size = self._fading_debug_output:script().FONT_SIZE})
	end
end)

function Mission:store_element_id(continent, id)
	self._ids = self._ids or {}
	self._ids[continent] = self._ids[continent] or {}
	self._ids[continent][id] = true
end

function Mission:delete_element_id(continent, id)
	self._ids[continent][id] = nil
end

function Mission:get_new_id(continent)
	if continent then		
		self._ids = self._ids or {}
		self._ids[continent] = self._ids[continent] or {}
		local tbl = self._ids[continent]
		local i = managers.worlddefinition._continents[continent].base_id
		while tbl[i] do
			i = i + 1
		end
		tbl[i] = true
		return i
	else
		_G.BeardLibEditor:log("[ERROR] continent needed for element id")
	end
end

function Mission:activate()
	if not self._activated then
		self._activated = true
		self:_activate_mission(self._activate_script)
	end
end

function Mission:_load_mission_file(name, file_dir, data)
	self._missions = self._missions or {}
	local file_path = file_dir .. data.file
	self._missions[name] = self:_serialize_to_script("mission", file_path) 
	for sname, mdata in pairs(self._missions[name]) do	
		mdata.name = sname
		mdata.continent = name
		self:_add_script(mdata)
	end
end

function Mission:set_element(element, old_script_name)
	if not element then
		return
	end

	local script_name = element.script
	local script = self._scripts[script_name] or nil
	local old_script = self._scripts[old_script_name] or nil
	local old_id = element.id
	local id = old_id

	if script then
		local mission_script = self._missions[script._continent][script_name]

		--TODO: Move multiple elements to different scripts without removing links		
		if old_script and script_name ~= old_script_name then

			local old_continent_name = old_script._continent
			local continent_name = script._continent
			local old_mission_script = self._missions[old_continent_name][old_script_name]

			if old_mission_script then
				self:delete_links(old_id, Utils.LinkTypes.Element)
				self:delete_element_id(old_continent_name, old_id)

				id = self:get_new_id(continent_name)
				self:store_element_id(continent_name, id)
				element.id = id

				script._elements[id] = old_script._elements[old_id]
				old_script._elements[old_id] = nil

				for k, e in pairs(old_mission_script.elements) do
					if e.id == id then
						table.remove(old_mission_script.elements, k)
						table.insert(mission_script.elements, e)
						break
					end
				end
			end
		end

		for k, e in pairs(mission_script.elements) do
			if e.id == id then
				mission_script.elements[k] = element
				break
			end
		end

		local script_element = script._elements[id]
		script_element._values = _G.deep_clone(element.values)

		if script_element._finalize_values then
			script_element:_finalize_values(script_element._values)
		end
		if script_element.on_script_activated then
			script_element:on_script_activated()
		end
	end
end

--Fucking hell overkill
function core:import_without_crashing(module_name)
	if self.__filepaths[module_name] ~= nil then
		local fp = self.__filepaths[module_name]
		require(fp)
		local m = self.__modules[module_name]
		rawset(getfenv(2), module_name, m)
		return m
	end
end

function Mission:add_element(element)
	local script
	local script_name
	local mission = self._missions.world
	local m = "Core" .. element.class
	if rawget(_G, "CoreMissionManager")[m] or core:import_without_crashing(m) then
		element.module = m
	end
	if element.script then
		for _, miss in pairs(self._missions) do 
			if miss[element.script] then
				script = miss[element.script]
				script_name = element.script
				break
			end
		end
	else
		_G.BeardLibEditor:log("[ERROR] Something went wrong when trying to add the element(1)")
	end
	if not script then
		if not mission then
			for _, v in pairs(self._missions) do mission = v break end
		end
		if mission then
			script = mission.default
			script_name = "default"
			if not script then
				for k, v in pairs(mission) do
					if type(v) == "table" then
						script = v
						script_name = k
						break
					end
				end
			end
		else
			_G.BeardLibEditor:log("[ERROR] Something went wrong when trying to add the element(2)")
		end
	end

	if script then
		table.insert(script.elements, element)
		return self._scripts[script_name]:create_element(element, true)
	else
		_G.BeardLibEditor:log("[ERROR] No mission scripts found in the map! cannot add elements")
	end
end

function Mission:delete_element(id)	
	self:delete_links(id, Utils.LinkTypes.Element)
	for m_name, mission in pairs(self._missions) do
		for s_name, script in pairs(mission) do
			for i, element in pairs(script.elements) do
				if element.id == id then
					Utils:GetPart("console"):Log("Deleting element %s in mission %s in script %s", tostring(element.editor_name), tostring(m_name), tostring(s_name))
					self._scripts[s_name]:delete_element(element)
					script.elements[i] = nil
					return
				end
			end
		end
	end
end

_G.Hooks:PreHook(MissionScript, "init", "BeardLibEditorMissionScriptPreInit", function(self, data)
	self._continent = data.continent
end)

function Mission:execute_element(element)
    for _, script in pairs(self._scripts) do
        if script._elements[element.id] then
            script:execute_element(element)
        end
    end
end

local tblinsert = table.insert
local tblremove = table.remove
local tbldel = table.delete
local tblcont = table.contains

function Mission:get_executors(element)
	local executors = {}
	if element then
		for _, script in pairs(self._missions) do
			for _, tbl in pairs(script) do
				if tbl.elements then
					for i, s_element in pairs(tbl.elements) do
						if s_element.values.on_executed then
							for _, exec in pairs(s_element.values.on_executed) do									
								if exec.id == element.id then
									tblinsert(executors, s_element)
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

function Mission:delete_links(id, match, elements)
	local links = self:get_links_paths_new(id, match, elements)
	--Remove last and then first so indices stay correct
	for i=#links, 1, -1 do
		local link = links[i]
		if tonumber(link.upper_k) then
			tblremove(link.upper_tbl, link.upper_k)
		elseif link.tbl[link.key] == id then
			if tonumber(link.key) then
				tblremove(link.tbl, link.key)
			else
				link.tbl[link.key] = nil
			end
		end
	end
end

local unit_rules = {
	keys = {"unit_id", "camera_u_id", "att_unit_id"},
	tbl_keys = {"unit_ids", "graph_ids", "nav_segs", "digital_gui_unit_ids"},
	tbl_value_keys = {
		{"obstacle_list", "unit_id"}, {"trigger_list", "notify_unit_id"}, {"sequence_list", "unit_id"}
	}
}
local element_rules = {
	keys = {"counter_id", "sequence", "att_unit_id", "element_id"},
	tbl_keys = {
		"elements",
		"instigator_ids",
		"spawn_unit_elements", 
		"use_shape_element_ids",
		"rules_element_ids", 
		"spawn_groups", 
		"spawn_points", 
		"followup_elements", 
		"spawn_instigator_ids", 
		"Stopwatch_value_ids",
		"included_units",
		"excluded_units"
	},
	tbl_value_keys = {{"on_executed", "id"}}
}

local instance_rules = {
	keys = {"instance"},
	tbl_value_keys = {{"event_list", "instance"}, {"instances", "instance"}}
}

-- key and id(located in values)
	--Deleting: tbl[key] = nil
	--Altering: tbl[key] = x
	--upper_tbl[upper_key][key] / element.values.unit_id
-- id inside tbl
	--Deleting: table.remove(tbl, key)
	--Altering: tbl[key] = x
	--upper_tbl[upper_key][key] / values.elements[1]
-- key and id inside tbl
	--Deleting: table.remove(upper_tbl, upper_key)
	--Altering: tbl[key] = x
	--upper_tbl[upper_key][key] / on_executed[1].id

local LinkTypes = Utils.LinkTypes
local default_upper_k = "values"
function Mission:get_links_paths_new(id, match, elements)
    if type(id) ~= "string" and (not tonumber(id) or tonumber(id) < 0) then
        return {}
	end
	local id_paths = {}
	local function GetLinks(values, element)
		local function get_locations_of_links(rules)
			for _, key in pairs(rules.keys) do
				if values[key] == id then
					tblinsert(id_paths, {tbl = values, key = key, upper_k = default_upper_k, upper_tbl = element, element = element, location = key})
				end
			end
			if rules.tbl_keys then
				for _, key in pairs(rules.tbl_keys) do
					local t = values[key]
					if t then
						local k = table.get_key(t, id)
						if k then
							tblinsert(id_paths, {tbl = t, key = k, upper_k = key, upper_tbl = values, element = element, location = key})
						end
					end
				end
			end
			for _, loc in pairs(rules.tbl_value_keys) do
				local t = values[loc[1]]
				if t then
					for i,v in pairs(t) do
						if v[loc[2]] == id then
							tblinsert(id_paths, {tbl = v, key = loc[2], upper_k = i, upper_tbl = t, element = element, location = loc[1]})
						end
					end
				end
			end
		end

		if match == LinkTypes.Unit then
			get_locations_of_links(unit_rules)
		elseif match == LinkTypes.Instance then
			get_locations_of_links(instance_rules)
		elseif match == LinkTypes.Element then
			get_locations_of_links(element_rules)
		end
    end
    if elements then
        for _, element in pairs(elements) do
			if element.mission_element_data and element.mission_element_data.values then
                GetLinks(element.mission_element_data.values, element)
            end
        end
    else
        for _, script in pairs(self._missions) do
            for _, tbl in pairs(script) do
                if tbl.elements then
					for k, element in pairs(tbl.elements) do
						if not element.instance then
							GetLinks(element.values, element)
						end
                    end
                end
            end
        end
    end
    return id_paths
end

function Mission:get_mission_element(id)
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

function Mission:add_fading_debug_output(debug, color, as_subtitle)
	if not self._fading_debug_enabled then
		return
	end
	if as_subtitle then
		self:_show_debug_subtitle(debug, color)
	else
		local stuff = { " -", " \\", " |", " /" }
		self._fade_index = (self._fade_index or 0) + 1
		self._fade_index = #stuff < self._fade_index and self._fade_index and 1 or self._fade_index
		self._fading_debug_output:script().log(stuff[self._fade_index] .. " " .. debug, color, nil)
	end
end

--Instance elements--
local MScript = MissionScript
function MScript:_preload_instance_class_elements(prepare_mission_data)
	prepare_mission_data.instance_name = nil
	for _, instance_mission_data in pairs(prepare_mission_data) do
		for _, element in ipairs(instance_mission_data.elements) do
			self:_element_class(element.module, element.class)
		end
	end
end

function MScript:create_instance_elements(prepare_mission_data)
	local new_elements = {}
	local instance_name = prepare_mission_data.instance_name
	prepare_mission_data.instance_name = nil
	for _, instance_mission_data in pairs(prepare_mission_data) do
		new_elements = self:_create_elements(instance_mission_data.elements, instance_name)
	end
	return new_elements
end
--Instance elements code end

function MScript:_create_elements(elements, instance_name)
	local new_elements = {}
	for _, element in pairs(elements) do
		element.instance = instance_name
		new_elements[element.id] = self:create_element(element, false, instance_name)
	end
	return new_elements
end

function MScript:create_element(element, return_unit, instance_name)
	local class = element.class
	if not element.id then
		element.id = managers.mission:get_new_id(self._continent)
	end
	managers.mission:store_element_id(self._continent, element.id)
	local new_element = self:_element_class(element.module, class):new(self, _G.deep_clone(element))
	element.script = self._name
	new_element.class = element.class
	new_element.module = element.module
	new_element.instance = instance_name
	self._elements[element.id] = new_element
	self._element_groups[class] = self._element_groups[class] or {}
	table.insert(self._element_groups[class], new_element)
	local new_unit = not instance_name and self:create_mission_element_unit(element)
	if return_unit then
		return new_unit
	end
	return new_element
end

function MScript:execute_element(element)
	self._elements[element.id]:on_executed(managers.player:player_unit())
end

function MScript:create_mission_element_unit(element)
	local enabled = element.values.position ~= nil
	element.values.position = element.values.position or Vector3(math.random(9999), math.random(9999), 0)
	element.values.rotation = type(element.values.rotation) ~= "number" and element.values.rotation or Rotation()

	local unit_name = "units/mission_element/element"
	if element.class == "ElementSpawnCivilian" then
		unit_name = "units/civilian_element/element"
	elseif element.class == "ElementSpawnEnemyDummy" then
		unit_name = "units/enemy_element/element"
	elseif element.class == "ElementPlayerSpawner" then
		unit_name = "units/player_element/element"
	end
	local unit = World:spawn_unit(Idstring(unit_name), element.values.position, element.values.rotation)

	--unit:mission_element():set_enabled(enabled, true)
    unit:unit_data().position = element.values.position
   	unit:unit_data().rotation = element.values.rotation
    unit:unit_data().local_pos = Vector3()
    unit:unit_data().local_rot = Rotation()
	unit:mission_element().element = element
	unit:mission_element():update_text()
	unit:mission_element():update_icon()
	if managers.editor then
		local mission = Utils:GetPart("mission")
		mission:set_name_id(element.class, element.editor_name)
		mission:add_element_unit(unit)
	end
	return unit
end

function MScript:delete_element(element)
	local id = element.id
	managers.mission:delete_element_id(self._continent, id)
	if self._elements[id] then
		self._elements[id]:set_enabled(false)
		self._elements[id] = nil
	else
		Utils:GetPart("console"):Error("Something went wrong when deleting the element %s", tostring(id))
	end
	if self._element_groups[element.class] then
		table.delete(self._element_groups[element.class], element)
	end
end

function MScript:debug_output(debug, color)
	if managers.editor then
		Utils:GetPart("console"):LogMission(debug:gsub('%%', '%'))
	end
end
