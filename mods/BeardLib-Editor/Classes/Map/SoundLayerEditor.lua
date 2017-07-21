SoundLayerEditor = SoundLayerEditor or class(EnvironmentLayerEditor)
local SndLayer = SoundLayerEditor
function SndLayer:init(parent)
	self:init_basic(parent, "SoundLayerEditor")
	self._menu = parent._holder
	MenuUtils:new(self)
	self._created_units = {}
	self._environment_unit = "core/units/sound_environment/sound_environment"
	self._emitter_unit = "core/units/sound_emitter/sound_emitter"
	self._area_emitter_unit = "core/units/sound_area_emitter/sound_area_emitter"
end

function SndLayer:loaded_continents()
	for _, area in ipairs(clone(managers.sound_environment:areas())) do
		local unit = self:do_spawn_unit(self._environment_unit, {name_id = area:name(), position = area:position(), rotation = area:rotation()})
		unit:unit_data().environment_area = area
		unit:unit_data().environment_area:set_unit(unit)
	end
	for _, emitter in ipairs(clone(managers.sound_environment:emitters())) do
		local unit = self:do_spawn_unit(self._emitter_unit, {name_id = emitter:name(), position = emitter:position(), rotation = emitter:rotation()})
		unit:unit_data().emitter = emitter
		unit:unit_data().emitter:set_unit(unit)
	end
	for _, emitter in ipairs(clone(managers.sound_environment:area_emitters())) do
		local unit = self:do_spawn_unit(self._area_emitter_unit, {name_id = emitter:name(), position = emitter:position(), rotation = emitter:rotation()})
		unit:unit_data().emitter = emitter
		unit:unit_data().emitter:set_unit(unit)
	end
end

function SndLayer:save()
	local sound_environments = {}
	local sound_emitters = {}
	local sound_area_emitters = {}
	for _, unit in ipairs(self._created_units) do
		if unit:name() == Idstring(self._environment_unit) then
			local area = unit:unit_data().environment_area
			local shape_table = area:save_level_data()
			shape_table.environment = area:environment()
			shape_table.ambience_event = area:ambience_event()
			shape_table.occasional_event = area:occasional_event()
			shape_table.use_environment = area:use_environment()
			shape_table.use_ambience = area:use_ambience()
			shape_table.use_occasional = area:use_occasional()
			shape_table.name = area:name()
			table.insert(sound_environments, shape_table)
		end
		if unit:name() == Idstring(self._emitter_unit) then
			local emitter = unit:unit_data().emitter
			table.insert(sound_emitters, {
				emitter_event = emitter:emitter_event(),
				position = emitter:position(),
				rotation = emitter:rotation(),
				name = emitter:name()
			})
		end
		if unit:name() == Idstring(self._area_emitter_unit) then
			local area_emitter = unit:unit_data().emitter
			local shape_table = area_emitter:save_level_data()
			shape_table.name = area_emitter:name()
			table.insert(sound_area_emitters, shape_table)
		end
	end
	local default_ambience = managers.sound_environment:default_ambience()
	local default_occasional = managers.sound_environment:default_occasional()
	local ambience_enabled = managers.sound_environment:ambience_enabled()
	managers.worlddefinition._sound_data = {
		default_environment = managers.sound_environment:default_environment(),
		default_ambience = default_ambience,
		ambience_enabled = ambience_enabled,
		default_occasional = default_occasional,
		sound_environments = sound_environments,
		sound_emitters = sound_emitters,
		sound_area_emitters = sound_area_emitters
	}
end

function SndLayer:reset_selected_units()
	for k, unit in ipairs(clone(self._created_units)) do
		if not alive(unit) then
			table.remove(self._created_units, k)
		end
	end
	self:save()
end

function SndLayer:update(t, dt)
	if self:Value("SoundUnits") then
		local selected_units = self:selected_units()
		for _, unit in ipairs(self._created_units) do
			if alive(unit) then
				if unit:name() == Idstring(self._emitter_unit) then
					local r, g, b = 0.6, 0.6, 0
					if table.contains(selected_units, unit) then
						r, g, b = 1, 1, 0.4
					end
					unit:unit_data().emitter:draw(t, dt, r, g, b)
				end
				if unit:name() == Idstring(self._environment_unit) then
					Application:draw(unit, 1, 1, 1)
					local r, g, b = 0, 0, 0.8
					if table.contains(selected_units, unit) then
						r, g, b = 0.4, 0.4, 1
					end
					unit:unit_data().environment_area:draw(t, dt, r, g, b)
				end
				if unit:name() == Idstring(self._area_emitter_unit) then
					Application:draw(unit, 1, 1, 1)
					local r, g, b = 0, 0, 0.8
					if table.contains(selected_units, unit) then
						r, g, b = 0.4, 0.4, 1
					end
					unit:unit_data().emitter:draw(t, dt, r, g, b)
				end
			end
		end
	end
end

function SndLayer:ambience_events()
	local events = {}
	for _, sound in pairs(Global.WorldSounds) do
		if string.begins(sound, "ambience_") then
			table.insert(events, sound)
		end
	end
	return events
end

function SndLayer:occasional_events()
	local events = {}
	for _, sound in pairs(Global.WorldSounds) do
		if string.begins(sound, "occasionals_") then
			table.insert(events, sound)
		end
	end
	return events
end

function SndLayer:emitter_events()
	local events = {}
	for _, sound in pairs(Global.WorldSounds) do
		if string.begins(sound, "emitter_") then
			table.insert(events, sound)
		end
	end
	return events
end

function SndLayer:build_menu()
	local defaults = self:Group("Defaults")

	local environments = managers.sound_environment:environments()
	self._default_environment = self:ComboBox("Environment", callback(self, self, "select_default_sound_environment"), environments, table.get_key(environments, managers.sound_environment:default_environment()), {group = defaults})
	local events = self:ambience_events()
	self._default_ambience = self:ComboBox("Ambience", callback(self, self, "select_default_ambience"), events, table.get_key(events, managers.sound_environment:default_ambience()), {
		group = defaults,
		enabled = #events > 0
	})
	local occ_events = self:occasional_events()
	self._default_occasional = self:ComboBox("Occasional", callback(self, self, "select_default_occasional"), occ_events, table.get_key(occ_events, managers.sound_environment:default_occasional()), {
		group = defaults, 
		enabled = #occ_events > 0
	})
	self._ambience_enabled = self:Toggle("AmbienceEnabled", callback(self, self, "set_ambience_enabled"), managers.sound_environment:ambience_enabled(), {group = defaults, enabled = #events > 0})

	self:Button("RestartAllEmitters", callback(self, self, "on_restart_emitters"))
    local utils = self:Manager("utils")
    self:Button("SpawnSoundEnvironment", callback(utils, utils, "BeginSpawning", self._environment_unit))
    self:Button("SpawnSoundEmitter", callback(utils, utils, "BeginSpawning", self._emitter_unit))
    self:Button("SpawnSoundAreaEmitter", callback(utils, utils, "BeginSpawning", self._area_emitter_unit))
end

function SndLayer:build_unit_menu()
	local S = self:Manager("static")
	S._built_multi = false
	S.super.build_default_menu(S)
	local unit = self:selected_unit()
	if alive(unit) then
		S:build_positions_items(true)
		S:update_positions()
        S:Button("CreatePrefab", callback(S, S, "add_selection_to_prefabs"), {group = S:GetItem("QuickButtons")})

		if unit:name() == self._environment_unit:id() then
			S:SetTitle("Sound Environment Selection")
			local sound_environment = S:Group("SoundEnvironment", {index = 1})
            S:TextBox("Name", callback(self, self, "set_unit_name_id"), unit:unit_data().name_id or "", {group = sound_environment})
			local environments = managers.sound_environment:environments()
			self._effect = S:ComboBox("Effect", callback(self, self, "select_sound_environment"), managers.sound_environment:environments(), table.get_key(environments, managers.sound_environment:default_environment()), {
				group = sound_environment
			})

			self._use_environment = S:Toggle("UseEnvironment", callback(self, self, "toggle_use_environment"), true, {group = sound_environment})

			local events = self:ambience_events()
			self._ambience = S:ComboBox("Ambience", callback(self, self, "select_environment_ambience"), events, table.get_key(events, managers.sound_environment:default_ambience()), {
				group = sound_environment,
			})
			self._use_ambience = S:Toggle("UseAmbience", callback(self, self, "toggle_use_ambience"), true, {group = sound_environment})

			local occ_events = self:occasional_events()
			self._occasional = S:ComboBox("Occasional", callback(self, self, "select_environment_occasional"), occ_events, table.get_key(occ_events, managers.sound_environment:default_occasional()), {
				group = sound_environment, 
			})
			self._use_occasional = S:Toggle("UseOccasional", callback(self, self, "toggle_use_occasional"), true, {group = sound_environment})
			self:set_sound_environment_parameters()
		elseif unit:name() == self._emitter_unit:id() or  unit:name() == self._area_emitter_unit:id() then
			if unit:name() == self._emitter_unit:id() then
				S:SetTitle("Sound Emitter Selection")
			elseif unit:name() == self._area_emitter_unit:id() then
				S:SetTitle("Sound Area Emitter Selection")	
			end
			local sound_emitter = S:Group("SoundEmitter", {index = 1})
            S:TextBox("Name", callback(self, self, "set_unit_name_id"), unit:unit_data().name_id or "", {group = sound_emitter})

			local events = self:emitter_events{}
			self._emitter_events_combobox = S:ComboBox("Events", callback(self, self, "select_emitter_event"), events, table.get_key(events, default_emitter_path and managers.sound_environment:emitter_events(default_emitter_path)[1]), {group = sound_emitter})
			self:set_sound_emitter_parameters()
		end
	end
end

function SndLayer:select_default_ambience(menu, item)
	managers.sound_environment:set_default_ambience(item:SelectedItem())
	self:save()
end

function SndLayer:select_default_occasional(menu, item)
	managers.sound_environment:set_default_occasional(item:SelectedItem())
	self:save()
end

function SndLayer:set_ambience_enabled(menu, item)
	managers.sound_environment:set_ambience_enabled(item:Value())
	self:save()
end

function SndLayer:select_default_sound_environment(menu, item)
	managers.sound_environment:set_default_environment(item:SelectedItem())
	self:save()
end

function SndLayer:select_emitter_path(menu, item)
	local path = item:SelectedItem()
	local emitter = self:selected_unit():unit_data().emitter
	emitter:set_emitter_path(path)
	self._emitter_events_combobox:SetItems(managers.sound_environment:emitter_events(path))
	self._emitter_events_combobox:SetSelectedItem(emitter:emitter_event())
end

function SndLayer:select_emitter_event(menu, item)
	self:selected_unit():unit_data().emitter:set_emitter_event(item:SelectedItem())
	self:save()
end

function SndLayer:select_sound_environment(menu, item)
	self:selected_unit():unit_data().environment_area:set_environment(item:SelectedItem())
	self:save()
end

function SndLayer:toggle_use_environment(menu, item)
	self:selected_unit():unit_data().environment_area:set_use_environment(item:Value())
	self:save()
end

function SndLayer:select_environment_ambience(menu, item)
	self:selected_unit():unit_data().environment_area:set_environment_ambience(item:SelectedItem())
	self:save()
end

function SndLayer:toggle_use_ambience(menu, item)
	self:selected_unit():unit_data().environment_area:set_use_ambience(item:Value())
	self:save()
end

function SndLayer:select_environment_occasional(menu, item)
	self:selected_unit():unit_data().environment_area:set_environment_occasional(item:SelectedItem())
	self:save()
end

function SndLayer:toggle_use_occasional(menu, item)
	self:selected_unit():unit_data().environment_area:set_use_occasional(item:Value())
	self:save()
end

function SndLayer:on_restart_emitters()
	for _, unit in ipairs(self._created_units) do
		if unit:name() == Idstring(self._emitter_unit) or unit:name() == Idstring(self._area_emitter_unit) then
			unit:unit_data().emitter:restart()
		end
	end
end

function SndLayer:do_spawn_unit(unit_path, ud)
	local unit = World:spawn_unit(unit_path:id(), ud.position or Vector3(), ud.rotation or Rotation())
	table.merge(unit:unit_data(), ud)
	unit:unit_data().name = unit_path
	unit:unit_data().sound_unit = true
	unit:unit_data().position = unit:position()
	unit:unit_data().rotation = unit:rotation()
	table.insert(self._created_units, unit)
	if alive(unit) then
		if unit:name() == Idstring(self._emitter_unit) then
            local emitter = unit:unit_data().emitter
			if not emitter or emitter:unit() ~= unit then
				unit:unit_data().emitter = managers.sound_environment:add_emitter(emitter and emitter:get_params() or {})
				unit:unit_data().emitter:set_unit(unit)
			end
		elseif unit:name() == Idstring(self._area_emitter_unit) then
            local emitter = unit:unit_data().emitter
			if not emitter or emitter:unit() ~= unit then
				unit:unit_data().emitter = managers.sound_environment:add_area_emitter(emitter and emitter:save_level_data() or {})
				unit:unit_data().emitter:set_unit(unit)
			end
		elseif unit:name() == Idstring(self._environment_unit) then
            local area = unit:unit_data().environment_area
			if not area or area:unit() ~= unit then
				unit:unit_data().environment_area = managers.sound_environment:add_area(area and area:get_params() or {})
				unit:unit_data().environment_area:set_unit(unit)
			end
		end
	end
	self:save()
	return unit
end

function SndLayer:is_my_unit(unit)
	if unit == self._emitter_unit:id() or unit == self._environment_unit:id() or unit == self._area_emitter_unit:id() then
		return true
	end
	return false
end

function SndLayer:delete_unit(unit)
	local ud = unit:unit_data()
	table.delete(self._created_units, unit)
	if ud then
		if unit:name() == Idstring(self._environment_unit) then
			managers.sound_environment:remove_area(ud.environment_area)
		end
		if unit:name() == Idstring(self._emitter_unit) then
			managers.sound_environment:remove_emitter(ud.emitter)
		end
		if unit:name() == Idstring(self._area_emitter_unit) then
			managers.sound_environment:remove_area_emitter(ud.emitter)
		end
	end
	self:save()
end

function SndLayer:set_sound_environment_parameters()
	local S = self:Manager("static")
	self._effect:SetEnabled(false)
	self._ambience:SetEnabled(false)
	self._occasional:SetEnabled(false)
	self._use_environment:SetEnabled(false)
	self._use_ambience:SetEnabled(false)
	self._use_occasional:SetEnabled(false)
	if alive(self:selected_unit()) and self:selected_unit():name() == self._environment_unit:id() then
		local area = self:selected_unit():unit_data().environment_area
		if area then
			area:create_panel(S)
			self._effect:SetEnabled(true)
			self._ambience:SetEnabled(true)
			self._occasional:SetEnabled(true)
			self._use_environment:SetEnabled(true)
			self._use_ambience:SetEnabled(true)
			self._use_occasional:SetEnabled(true)
			self._effect:SetSelectedItem(area:environment())
			self._ambience:SetSelectedItem(area:ambience_event())
			self._occasional:SetSelectedItem(area:occasional_event())
			self._use_environment:SetValue(area:use_environment())
			self._use_ambience:SetValue(area:use_ambience())
			self._use_occasional:SetValue(area:use_occasional())
		end
	end
end

function SndLayer:set_sound_emitter_parameters()
	local S = self:Manager("static")
	if alive(self:selected_unit()) and (self:selected_unit():name() == self._emitter_unit:id() or self:selected_unit():name() == self._area_emitter_unit:id()) then
		local emitter = self:selected_unit():unit_data().emitter
		if emitter then
			self._emitter_events_combobox:SetSelectedItem(emitter:emitter_event())
		end
		if self:selected_unit():name() == self._area_emitter_unit:id() then
			local area = self:selected_unit():unit_data().emitter
			if area then
				area:create_panel(S)
			end
		end
	end
end

function SndLayer:activate()
	SoundLayerEditor.super.activate(self)
	managers.editor:set_listener_enabled(true)
	managers.editor:set_wanted_mute(false)
end

function SndLayer:deactivate(params)
	managers.editor:set_listener_enabled(false)
	SoundLayerEditor.super.deactivate(self)
	if not params or not params.simulation then
		managers.editor:set_wanted_mute(true)
	end
end