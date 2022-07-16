EditorWorldCamera = EditorWorldCamera or class(MissionScriptEditor)
function EditorWorldCamera:create_element()
	EditorWorldCamera.super.create_element(self)
	self._element.class = "ElementWorldCamera"
	self._element.module = "CoreElementWorldCamera"
	self._element.values.worldcamera = "none"
	self._element.values.worldcamera_sequence = "none"
end

function EditorWorldCamera:test_element()
	if self._element.values.worldcamera_sequence ~= "none" then
		local sequence = managers.worldcamera:world_camera_sequence(self._element.values.worldcamera_sequence)
		if sequence and #sequence > 0 then
			managers.worldcamera:play_world_camera_sequence(self._element.values.worldcamera_sequence)
		end
		self._test_done_callback = managers.worldcamera:add_sequence_done_callback(self._element.values.worldcamera_sequence, ClassClbk(managers.editor, "force_editor_state"))
	elseif self._element.values.worldcamera ~= "none" then
		local camera = managers.worldcamera:world_camera(self._element.values.worldcamera)
		if camera and #camera._positions > 0 then
			managers.worldcamera:play_world_camera(self._element.values.worldcamera)
		end
		self._test_done_callback = managers.worldcamera:add_world_camera_done_callback(self._element.values.worldcamera, ClassClbk(managers.editor, "force_editor_state"))
	end
end

function EditorWorldCamera:stop_test_element()
	managers.worldcamera:stop_world_camera()
	managers.worldcamera:_sequence_done()
end

function EditorWorldCamera:set_element_data(item)
	self.super.set_element_data(self, item)
	if item.name == "worldcamera" or item.name == "worldcamera_sequence" then
		self:_check_validity()
	end
end

function EditorWorldCamera:_check_validity()
	if self._element.values.worldcamera_sequence ~= "none" then
		local sequence = managers.worldcamera:world_camera_sequence(self._element.values.worldcamera_sequence)
		if not sequence or #sequence == 0 then
			self._alert:SetVisible(true)
			self._alert:SetText("Sequence has no cameras! Executing the element in normal gameplay will produce a black screen")
			self._holder:AlignItems(true)
			return
		end
	elseif self._element.values.worldcamera ~= "none" then
		local camera = managers.worldcamera:world_camera(self._element.values.worldcamera)
		if not camera or #camera._positions == 0 then
			self._alert:SetVisible(true)
			self._alert:SetText("Camera has no points! Executing the element in normal gameplay will produce a black screen")
			self._holder:AlignItems(true)
			return
		end
	end
	self._alert:SetVisible(false)
	self._holder:AlignItems(true)
end

function EditorWorldCamera:_build_panel()
	self:_create_panel()
	self:ComboCtrl("worldcamera", self:_sorted_worldcameras(), {text = "Camera"})
	self:ComboCtrl("worldcamera_sequence", self:_sorted_worldcamera_sequences(), {text = "Sequence"})
	self._alert = self._class_group:alert("")
	self:_check_validity()
end

function EditorWorldCamera:_sorted_worldcameras()
	local t = {"none"}

	for name, _ in pairs(managers.worldcamera:all_world_cameras()) do
		table.insert(t, name)
	end

	table.sort(t)

	return t
end

function EditorWorldCamera:_sorted_worldcamera_sequences()
	local t = {"none"}

	for name, _ in pairs(managers.worldcamera:all_world_camera_sequences()) do
		table.insert(t, tostring(name))
	end

	table.sort(t)

	return t
end

EditorWorldCameraTrigger = EditorWorldCameraTrigger or class(MissionScriptEditor)
function EditorWorldCameraTrigger:create_element()
	EditorWorldCameraTrigger.super.create_element(self)
	self._element.class = "ElementWorldCameraTrigger"
	self._element.module = "CoreElementWorldCamera"
	self._element.values.worldcamera_trigger_sequence = "none"
	self._element.values.worldcamera_trigger_after_clip = "done"
end

function EditorWorldCameraTrigger:_build_panel()
	self:_create_panel()
	self:ComboCtrl("worldcamera_trigger_sequence", self:_sorted_worldcamera_sequences(), {text = "Trigger Sequence"})
	self._after_clip = self:ComboCtrl("worldcamera_trigger_after_clip", {"done"}, {text = "Trigger After Clip"})
	self:_populate_after_clip()
end

function EditorWorldCameraTrigger:set_element_data(item)
	self.super.set_element_data(self, item)
	if item.name == "worldcamera_trigger_sequence" then
		self:_populate_after_clip()
	end
end

function EditorWorldCameraTrigger:_sorted_worldcamera_sequences()
	local t = {"none"}

	for name, _ in pairs(managers.worldcamera:all_world_camera_sequences()) do
		table.insert(t, name)
	end

	table.sort(t)

	return t
end

function EditorWorldCameraTrigger:_populate_after_clip()
	local t = {"done"}

	local old_clip = self._element.values.worldcamera_trigger_after_clip
	self._element.values.worldcamera_trigger_after_clip = "done"

	if self._element.values.worldcamera_trigger_sequence ~= "none" then
		local sequence = managers.worldcamera:world_camera_sequence(self._element.values.worldcamera_trigger_sequence)

		for i, cam in ipairs(sequence) do
			table.insert(t, i)

			if i == old_clip then
				self._element.values.worldcamera_trigger_after_clip = old_clip
			end
		end
	end

	self._after_clip:SetItems(t)
	self._after_clip:SetSelectedItem(self._element.values.worldcamera_trigger_after_clip)
end