if not Global.editor_mode then
	return
end

local F = table.remove(RequiredScript:split("/"))
local UnitIds = Idstring("unit")

local civ = F == "elementspawncivilian"
if F == "coreelementarea" then
	core:module("CoreElementArea")
	function ElementAreaTrigger:init(...)
		ElementAreaTrigger.super.init(self, ...)

		self._last_project_amount_all = 0
		self:_finalize_values()
	end
	function ElementAreaTrigger:_finalize_values()
		if self._shapes then
			for _, shape in pairs(self._shapes) do
				shape:destroy()
			end
		end
		self._shapes = {}
		self._shape_elements = {}
		self._rules_elements = {}
		if not self._values.use_shape_element_ids then
			if not self._values.shape_type or self._values.shape_type == "box" then
				self:_add_shape(CoreShapeManager.ShapeBoxMiddle:new({
					position = self._values.position,
					rotation = self._values.rotation,
					width = self._values.width,
					depth = self._values.depth,
					height = self._values.height
				}))
			elseif self._values.shape_type == "cylinder" then
				self:_add_shape(CoreShapeManager.ShapeCylinderMiddle:new({
					position = self._values.position,
					rotation = self._values.rotation,
					height = self._values.height,
					radius = self._values.radius
				}))
			elseif self._values.shape_type == "sphere" then
				self:_add_shape(CoreShapeManager.ShapeSphere:new({
					position = self._values.position,
					rotation = self._values.rotation,
					height = self._values.height,
					radius = self._values.radius
				}))
			end
		end
		self._inside = {}
	end
	function ElementAreaTrigger:debug_draw()
		for _, shape in ipairs(self._shapes) do
			shape:draw(0, 0, self._values.enabled and 0 or 1, self._values.enabled and 1 or 0, 0, 0.2)
		end
	
		for _, shape_element in ipairs(self._shape_elements) do
			for _, shape in ipairs(shape_element:get_shapes()) do
				shape:draw(0, 0, self._values.enabled and 0 or 1, self._values.enabled and 1 or 0, 0, 0.2)
			end
		end
	end
elseif civ or F == "elementspawnenemydummy" then
	local C = civ and ElementSpawnCivilian or ElementSpawnEnemyDummy
	--Makes sure unit path is updated.
	Hooks:PostHook(C, "_finalize_values", "EditorFinalizeValues", function(self)
		if self._values.enemy then
			self._enemy_name = self._values.enemy and Idstring(self._values.enemy) or nil
		end
		if not self._enemy_name then
			if civ then
				self._enemy_name = Idstring("units/characters/civilians/dummy_civilian_1/dummy_civilian_1")
			else
				self._enemy_name = Idstring("units/payday2/characters/ene_swat_1/ene_swat_1")
			end
		end 
	end)
	--Makes sure element doesn't crash in editor.
	local orig = C.produce
	function C:produce(params, ...)
		local enemy = self._enemy_name or self:value("enemy")
		if (not params or not params.name) and (not enemy or not PackageManager:has(UnitIds, enemy:id())) then
			return
		end
		return orig(self, params, ...)
	end
elseif F == "coreelementworldcamera" then
	core:module("CoreElementWorldCamera")
	--Prevent black screen after executing from editor
	Hooks:PostHook(ElementWorldCamera, "on_executed", "EditorWorldCameraFix", function(self, instigator)
		if not managers.editor:enabled() then
			return
		end

		if self._values.worldcamera_sequence and self._values.worldcamera_sequence ~= "none" then
			local sequence = managers.worldcamera:world_camera_sequence(self._values.worldcamera_sequence)
			if not sequence or #sequence == 0 then
				self:camera_done()
				return
			end
			managers.worldcamera:add_sequence_done_callback(self._values.worldcamera_sequence, callback(self, self, "camera_done"))
		elseif self._values.worldcamera and self._values.worldcamera ~= "none" then
			local camera = managers.worldcamera:world_camera(self._values.worldcamera)
			if not camera or #camera._positions == 0 then
				self:camera_done()
				return
			end
			managers.worldcamera:add_world_camera_done_callback(self._values.worldcamera, callback(self, self, "camera_done"))
		end
	end)

	function ElementWorldCamera:camera_done()
		managers.editor:force_editor_state()
	end
elseif F == "levelstweakdata" then
	Hooks:PostHook(LevelsTweakData, "init", "BLEInstanceFix", function(self)
		if Global.editor_loaded_instance then
			local id = Global.game_settings.level_id
			local instance = BeardLib.current_level or {_levels_less_path = id, _config = {}}
			self[id] = table.merge(clone(instance._config), {
				name_id = "none",
				briefing_id = "none",
				world_name = instance._levels_less_path,
				ai_group_type = self.ai_groups.default,
				intro_event = "nothing",
				outro_event = "nothing",
				custom = true
			})
		end
	end)
elseif F == "jobmanager" then
	function JobManager:current_mission_filter()
		if not self._global.current_job then
			return
		end
		return {Global.current_mission_filter} or self:current_stage_data().mission_filter
	end
elseif F == "coreworldcameramanager" then
	function CoreWorldCameraManager:save()
		local worldcameras = {}
	
		for name, world_camera in pairs(self._world_cameras) do
			worldcameras[name] = world_camera:save_data_table()
		end
	
		managers.worlddefinition._world_cameras_data = {}
		if table.size(worldcameras) > 0 or table.size(self._world_camera_sequences) > 0 then
			managers.worlddefinition._world_cameras_data = {
				worldcameras = worldcameras,
				sequences = self._world_camera_sequences
			}
		end
	end

	function CoreWorldCamera:_check_loaded_data()
		self._in_acc = math.round(self._in_acc * 100) / 100
		self._out_acc = math.round(self._out_acc * 100) / 100
		for _, key in pairs(self._keys) do
			key.roll = key.roll or 0
		end
	end
end