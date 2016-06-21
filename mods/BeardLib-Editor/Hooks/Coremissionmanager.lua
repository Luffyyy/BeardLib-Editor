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
	self._missions = {}
	for name, data in pairs(continent_files) do
		if not managers.worlddefinition:continent_excluded(name) then
			self:_load_mission_file(name, file_dir, data)
		end
	end
	if Global.editor_mode then
		_G.BeardLibEditor.managers.MapEditor:load_missions(self._missions)
	end
	self:_activate_mission(activate_mission)
	return true
end

function MissionManager:_load_mission_file(name, file_dir, data)
	local file_path = file_dir .. data.file
	local scripts = self:_serialize_to_script("mission", file_path)
	self._missions[name] = self:_serialize_to_script("mission", file_path) 
	for name, data in pairs(scripts) do	
		data.name = name
		self:_add_script(data)
	end
end

function MissionManager:add_element(element)
	local module_name = "Core" .. element.class
	if rawget(_G, "CoreMissionManager")[module_name] then
		element.module = module_name 	
	end
	table.insert(self._missions["world"]["default"].elements, element)
	self._scripts["default"]:create_element(element)
	return element
end
function MissionManager:delete_element(element)	
	self:delete_executors_of_element(element)
	self._scripts["default"]:delete_element(element)
	table.delete(self._missions["world"]["default"].elements, element)
end

function MissionManager:execute_element(element)
	self._scripts["default"]:execute_element(element)
end
function MissionManager:save_mission_file(mission, type, path)
	local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(self._missions[mission], type)	 
	local mission_file = io.open(path .. "/" .. mission .. "_mission" .. "." .. type, "w+")
	_G.BeardLib:log("Saving mission: " .. mission .. " as a " .. type .. " in " .. path)
	if mission_file then
		mission_file:write(new_data)
		mission_file:close()	
	else
		_G.BeardLib:log("Failed to save mission: " .. mission .. " path: " .. path)
	end		 
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
 
function MissionManager:get_links( id )	
	if id <= 0 then
		return {}
	end
	local modifiers = {}
	local function search_table( element, tbl )
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

function MissionManager:get_mission_element( id )
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
	self._scripts[data.name]:add_updator("_debug_draw", callback(self._scripts[data.name], self._scripts[data.name], "_debug_draw"))
end
function MissionScript:_create_elements(elements)
	local new_elements = {}
	for _, element in ipairs(elements) do	
		if element.class == "ElementDisableUnit" then
		--	element.values.enabled = false
		end
		new_elements[element.id] = self:create_element(element)
	end
	return new_elements
end

function MissionScript:create_element(element)
	local class = element.class	

	local new_element = self:_element_class(element.module, class):new(self, element)

	new_element.class = element.class
	new_element.module = element.module
	self._elements[element.id] = new_element
	self._element_groups[class] = self._element_groups[class] or {}
	table.insert(self._element_groups[class], new_element)
	return new_element
end

function MissionScript:execute_element(element)
	self._elements[element.id]:on_executed(managers.player:player_unit())
end
function MissionScript:delete_element(element)
	self._elements[element.id]:set_enabled(false)
	self._elements[element.id] = nil
	self._element_groups[element.class] = nil
end
function MissionScript:draw_element(element, color)
	local brush = Draw:brush(Color.red)
	local name_brush = Draw:brush(Color.red)
	name_brush:set_font(Idstring("core/fonts/nice_editor_font"), 24)
	name_brush:set_render_template(Idstring("OverlayVertexColorTextured"))
	brush:set_color(color or element:enabled() and Color.green or Color.red)
	name_brush:set_color(color or element:enabled() and Color.green or Color.red)
	if managers.viewport:get_current_camera() then
		if element:value("position") then
			brush:sphere(element:value("position"), 5)
			local cam_up = managers.viewport:get_current_camera():rotation():z()
			local cam_right = managers.viewport:get_current_camera():rotation():x()
			name_brush:center_text(element:value("position") + Vector3(0, 0, 30), utf8.from_latin1(element:editor_name()) .. "[ "..element.class.. " - ".. tostring(element:id()) .." ]", cam_right, -cam_up)
		end
		if element:value("rotation") then
			local rotation = CoreClass.type_name(element:value("rotation")) == "Rotation" and element:value("rotation") or Rotation(element:value("rotation"), 0, 0)
			brush:cylinder(element:value("position"), element:value("position") + rotation:y() * 50, 2)
			brush:cylinder(element:value("position"), element:value("position") + rotation:z() * 25, 1)
		end
	end
	element:debug_draw()
end
 
function MissionScript:_debug_draw(t, dt)
	local Editor = _G.BeardLibEditor.managers.MapEditor
	local wanted_classes = Editor.managers.GameOptions._wanted_elements
	if Editor.managers.GameOptions._menu:GetItem("Map/ShowElements").value and managers.viewport:get_current_camera() then
		for id, element in pairs(self._elements) do
			if element:value("position") then
				local distance = mvector3.distance_sq(element:value("position"), managers.viewport:get_current_camera():position())
				if distance < 2250000 then
					if #wanted_classes == 0 then
						self:draw_element(element)
					else
						for _, class in pairs(wanted_classes) do
							if element.class == class then
								self:draw_element(element)
							end
						end
					end
				end
			end
		end
	end
	if _G.BeardLibEditor.managers.MapEditor._selected_element then
		local element = self._elements[Editor._selected_element.id]
		if element then
			self:draw_element(element, Color(0, 0.5, 1))
			element._values = Editor._selected_element.values
			element._editor_name = Editor._selected_element.editor_name
		end
	end
end

function MissionScript:debug_output(debug, color)
	_G.BeardLibEditor.managers.MapEditor.managers.Console:LogMission(debug)
end