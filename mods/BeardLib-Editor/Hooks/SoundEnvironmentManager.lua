if not Global.editor_mode then
	return
end

core:import("CoreShapeManager")
local SoundEnv = CoreSoundEnvironmentManager
function SoundEnv:init()
	self._areas = {}
	self._areas_per_frame = 1
	self._check_objects = {}
	self._check_object_id = 0
	self._emitters = {}
	self._area_emitters = {}
	self._ambience_changed_callback = {}
	self._ambience_changed_callbacks = {}
	self._environment_changed_callback = {}
	self.GAME_DEFAULT_ENVIRONMENT = "padded_cell"
	self._default_environment = self.GAME_DEFAULT_ENVIRONMENT
	self._current_environment = self.GAME_DEFAULT_ENVIRONMENT
	self:_set_environment(self.GAME_DEFAULT_ENVIRONMENT)
	self._environments = self:_environment_effects()
	self.GAME_DEFAULT_ENVIRONMENT = self._environments[1] or nil
	self._default_environment = self.GAME_DEFAULT_ENVIRONMENT
	self._current_environment = self.GAME_DEFAULT_ENVIRONMENT
	self:_set_environment(self.GAME_DEFAULT_ENVIRONMENT)
    self:_find_emitter_events()
    self:_find_ambience_events()
    self:_find_scene_events()
    self:_find_occasional_events()
    self.GAME_DEFAULT_EMITTER_PATH = self._emitter.paths[1]
    self.GAME_DEFAULT_AMBIENCE = self._ambience.events[1]
    self._default_ambience = self.GAME_DEFAULT_AMBIENCE
    self.GAME_DEFAULT_OCCASIONAL = self._occasional.events[1]
    self._default_occasional = self.GAME_DEFAULT_OCCASIONAL
    self.GAME_DEFAULT_SCENE_PATH = self._scene.paths[1]
	self._ambience_enabled = false
	self._occasional_blocked_by_platform = SystemInfo:platform() == Idstring("X360")
	self._ambience_sources_count = 1
	self.POSITION_OFFSET = 50
	self._active_ambience_soundbanks = {}
	self._occasional_sound_source = SoundDevice:create_source("occasional")
end

function SoundEnv:_find_emitter_events()
	self._emitter = {
		events = {},
		paths = {},
		soundbanks = {}
	}
	for _, soundbank in ipairs(SoundDevice:sound_banks()) do
		for event, data in pairs(SoundDevice:events(soundbank) or {}) do
			if string.match(event, "emitter") then
				if not table.contains(self._emitter.paths, data.path) then
					table.insert(self._emitter.paths, data.path)
				end
				self._emitter.events[data.path] = self._emitter.events[data.path] or {}
				table.insert(self._emitter.events[data.path], event)
				self._emitter.soundbanks[event] = soundbank
			end
		end
	end
	table.sort(self._emitter.paths)
end

function SoundEnv:_find_ambience_events()
	self._ambience = {
		events = {},
		soundbanks = {}
	}
	for _, soundbank in ipairs(SoundDevice:sound_banks()) do
		for event, data in pairs(SoundDevice:events(soundbank) or {}) do
			if string.match(event, "ambience") then
				table.insert(self._ambience.events, event)
				self._ambience.soundbanks[event] = soundbank
			end
		end
	end
	table.sort(self._ambience.events)
end

function SoundEnv:_find_scene_events()
	self._scene = {
		events = {},
		paths = {},
		soundbanks = {}
	}
	for _, soundbank in ipairs(SoundDevice:sound_banks()) do
		for event, data in pairs(SoundDevice:events(soundbank) or {}) do
			if not table.contains(self._scene.paths, data.path) then
				table.insert(self._scene.paths, data.path)
			end
			self._scene.events[data.path] = self._scene.events[data.path] or {}
			table.insert(self._scene.events[data.path], event)
			self._scene.soundbanks[event] = soundbank
		end
	end
	table.sort(self._scene.paths)
end

function SoundEnv:_find_occasional_events()
	self._occasional = {
		events = {},
		soundbanks = {}
	}
	for _, soundbank in ipairs(SoundDevice:sound_banks()) do
		for event, data in pairs(SoundDevice:events(soundbank) or {}) do
			if string.match(event, "occasional") then
				table.insert(self._occasional.events, event)
				self._occasional.soundbanks[event] = soundbank
			end
		end
	end
	table.sort(self._occasional.events)
end

function SoundEnv:set_default_ambience(ambience_event)
	if not ambience_event then
		return
	end
	self._default_ambience = ambience_event
	--if Application:editor() then
		self:add_soundbank(self:ambience_soundbank(self._default_ambience))
	--end
	for id, data in pairs(self._check_objects) do
		self:_change_ambience(data)
	end
end

function SoundEnv:set_default_occasional(occasional_event)
	if not occasional_event then
		return
	end
	if occasional_event and Application:editor() and not table.contains(managers.sound_environment:occasional_events(), occasional_event) then
		if managers.editor then
			managers.editor:output_error("Default occasional event " .. occasional_event .. " no longer exits. Falls back on default.")
		end
		occasional_event = managers.sound_environment:game_default_occasional()
	end
	self._default_occasional = occasional_event
	if Application:editor() then
		self:add_soundbank(self:occasional_soundbank(self._default_occasional))
	end
end

function SoundEnv:add_soundbank(soundbank)
	if not soundbank then
		Application:error("Cant load nil soundbank")
		return
	end
	if Application:editor() then
		CoreEngineAccess._editor_load(("bnk"):id(), soundbank:id())
	end
end

function SoundEnvironmentArea:init(params)
	params.type = "box"
	SoundEnvironmentArea.super.init(self, params)
	self._environment = params.environment or managers.sound_environment:game_default_environment()
	self._ambience_event = params.ambience_event or managers.sound_environment:game_default_ambience()
	self._occasional_event = params.occasional_event or managers.sound_environment:game_default_occasional()
	self._use_environment = params.use_environment or params.use_environment == nil and true
	self._use_ambience = params.use_ambience or params.use_ambience == nil and true
	self._use_occasional = params.use_occasional or params.use_occasional == nil and true
	self._gain = params.gain or 0
	self._name = params.name or ""
	self._enable = true
	self:_init_environment_effect()
	self:_init_event()
	self._environment_shape = EnvironmentShape(self:position(), self:size(), self:rotation())
	self:_add_environment()
	if Application:editor() then
		managers.sound_environment:add_soundbank(managers.sound_environment:ambience_soundbank(self._ambience_event))
		managers.sound_environment:add_soundbank(managers.sound_environment:occasional_soundbank(self._occasional_event))
	end
end

function SoundEnvironmentArea:_init_event()
	if Application:editor() then
		if not table.contains(managers.sound_environment:ambience_events(), self._ambience_event) then
			managers.editor:output_error("Ambience event " .. self._ambience_event .. " no longer exits. Falls back on default.")
			self:set_environment_ambience(managers.sound_environment:game_default_ambience())
		end
		if self._occasional_event and not table.contains(managers.sound_environment:occasional_events(), self._occasional_event) then
			managers.editor:output_error("Occasional event " .. self._occasional_event .. " no longer exits. Falls back on default.")
			self:set_environment_occasional(managers.sound_environment:game_default_occasional())
		end
	end
end

function SoundEnvironmentArea:_init_environment_effect()
	if Application:editor() and not table.contains(managers.sound_environment:environments(), self._environment) then
		managers.editor:output_error("Environment effect " .. self._environment .. " no longer exits. Falls back on default.")
		self:set_environment(managers.sound_environment:game_default_environment())
	end
end

function SoundEnvironmentArea:set_environment_ambience(ambience_event)
	if not ambience_event then
		return
	end
	self._ambience_event = ambience_event
	if Application:editor() then
		managers.sound_environment:add_soundbank(managers.sound_environment:ambience_soundbank(self._ambience_event))
	end
end

function SoundEnvironmentArea:set_environment_occasional(occasional_event)
	self._occasional_event = occasional_event
	if not occasional_event then
		return
	end
	if Application:editor() then
		managers.sound_environment:add_soundbank(managers.sound_environment:occasional_soundbank(self._occasional_event))
	end
end

function SoundEnvironmentEmitter:set_emitter_event(emitter_event)
	self._emitter_event = emitter_event
	if Application:editor() then
		managers.sound_environment:add_soundbank(managers.sound_environment:emitter_soundbank(self._emitter_event))
	end
	self:play_sound()
end

function SoundEnvironmentAreaEmitter:set_emitter_event(emitter_event)
	self._properties.emitter_event = emitter_event
	if Application:editor() then
		managers.sound_environment:add_soundbank(managers.sound_environment:emitter_soundbank(self._properties.emitter_event))
	end
	self:play_sound()
end

function SoundEnvironmentArea:set_unit(unit)
	SoundEnvironmentArea.super.set_unit(self, unit)
	if alive(unit) then
		self._environment_shape:link(unit:orientation_object())
	end
end

function SoundEnvironmentEmitter:unit()
	return self._unit
end

SoundEnvironmentEmitter.get_params = CoreShapeManager.Shape.get_params