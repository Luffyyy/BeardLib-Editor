WorldCamerasToolEditor = WorldCamerasToolEditor or class(ToolEditor)
local WorldCamTool = WorldCamerasToolEditor
function WorldCamTool:init(parent)
	WorldCamTool.super.init(self, parent, "WorldCamerasToolEditor")
    self._workspace = Overlay:newgui():create_screen_workspace(0, 0, 1, 1)
	self._gui = self._workspace:panel():gui(Idstring("core/guis/core_world_camera"))
	self._gui_visible = nil

	self:set_gui_visible(false)

	self._look_through_camera = false
	self._current_time = 0
	self._time_precision = 10000
end

function WorldCamTool:destroy()
	if self._workspace then
		Overlay:newgui():destroy_workspace(self._workspace)
		self._workspace = nil
	end
end


function WorldCamTool:build_menu()
    local icons = BLE.Utils.EditorIcons
	self._holder.auto_align = false

    self._holder:tickbox("ShowFramingGUI", ClassClbk(self, "toggle_show_framing_gui"), false)
    local cameras = self._holder:group("Cameras", {align_method = "grid"})
    cameras:GetToolbar():tb_imgbtn("NewCamera", ClassClbk(self, "create_new"), nil, icons.plus, {help = "Create a new world camera"})
    self._camera_list = cameras:pan("CameraList", {h = 80, auto_height = false, full_bg_color = Color.transparent, background_color = false})
   
    local settings = cameras:group("Settings", {enabled = false})
    local acc = {"linear", "ease", "fast"}
    settings:GetToolbar():tb_imgbtn("StopCamera", ClassClbk(self, "stop_camera"), nil, icons.stop, {help = "Stop current test world camera"})
    settings:GetToolbar():tb_imgbtn("TestCamera", ClassClbk(self, "test_camera"), nil, icons.play, {help = "Test selected world camera"})
    self._sine_alert = settings:alert("The sine Curve Type is unfinished and is prone to crashing. Use at your own risk!")
    self._sine_alert:SetVisible(false)
    settings:combobox("CurveType", ClassClbk(self, "set_type"), {"bezier", "sine"}, 1)
    settings:combobox("StartAcceleration", ClassClbk(self, "change_acc", "in"), acc, 1)
    settings:combobox("EndAcceleration", ClassClbk(self, "change_acc", "out"), acc, 1)
    settings:numberbox("CameraDuration", ClassClbk(self, "set_duration"), 2.5, {floats = 2, min = 0.01, step = 0.1, help = "Specifies the camera lenght in seconds"})
    settings:numberbox("EndDelay", ClassClbk(self, "set_delay"), 0, {floats = 2, min = 0, help = "Specifies the delay time after camera has reached the end position, in seconds"})
    settings:numberbox("DofPadding", ClassClbk(self, "set_dof_padding"), managers.worldcamera:default_dof_padding(), {floats = 2, min = 0, help = "The fade distance from max dof to no dof"})
    settings:numberbox("DofAmount", ClassClbk(self, "set_dof_clamp"), managers.worldcamera:default_dof_clamp(), {floats = 2, min = 0, help = "A value to specify how much dof it should have"})
    
    self._point_list = cameras:group("Points", {enabled = false, max_height = 155})
	self:update_point_list()
    self._keys_list = cameras:group("Keys", {enabled = false, align_method = "grid_from_right"})
    self._keys_list:GetToolbar():tb_imgbtn("LookThroughCamera", ClassClbk(self, "look_through_camera"), nil, icons.teleport_selection, {help = "Look through camera", enabled_alpha = self._look_through_camera and 1 or 0.5})
    local divider = " | "
    local timeData = "Key Time: 0"..divider
    timeData = timeData.."Fov: ".. managers.worldcamera:default_fov()..divider
    timeData = timeData.."Roll: 0\n"
    timeData = timeData.."Near Dof: "..managers.worldcamera:default_near_dof()..divider
    timeData = timeData.."Far Dof: "..managers.worldcamera:default_far_dof()

    self._keys_list:divider("TimeData", {text = timeData, offset = {0}})
    self._keys_list:slider("Time", ClassClbk(self, "set_time"), self._current_time, {max = 1, min = 0, text = false, control_slice = 1, slider_slice = 1, align_method = "grid"})

    local key = self._keys_list:combobox("SelectKey", ClassClbk(self, "select_key"), nil, 1)
	local size = key:H()

	self._keys_list:tb_imgbtn("AddKey", ClassClbk(self, "add_key"), nil, icons.plus, {help = "Add key starting at the current time", size = size})
	self._keys_list:tb_imgbtn("DeleteKey", ClassClbk(self, "delete_key"), nil, icons.trash, {help = "Delete Selected key", highlight_color = Color.red, size = size})
    self._keys_list:tb_imgbtn("NextKey", ClassClbk(self, "next_key"), nil, icons.arrow_right, {help = "Next key", size = size})
	self._keys_list:tb_imgbtn("PreviousKey", ClassClbk(self, "prev_key"), nil, icons.arrow_left, {help = "Previous key", size = size})

    self._keys_list:numberbox("KeyTime", ClassClbk(self, "on_key_time"), 0, {help = "The time where this key starts at", max = 1, min = 0, step = 0.01, floats = 4})
    self._keys_list:slider("Fov", ClassClbk(self, "on_key_fov"), managers.worldcamera:default_fov(), {max = 90, min = 1, floats = 0})
    self._keys_list:numberbox("NearDof", ClassClbk(self, "on_key_near_dof"), managers.worldcamera:default_near_dof(), {max = 10000, min = 0})
    self._keys_list:numberbox("FarDof", ClassClbk(self, "on_key_far_dof"), managers.worldcamera:default_far_dof(), {max = 10000, min = 0})
    self._keys_list:numberbox("Roll", ClassClbk(self, "on_set_roll"), 0, {floats = 0})

    self._sequence_list = self._holder:group("Sequences")
    self._sequence_list:GetToolbar():tb_imgbtn("NewSequence", ClassClbk(self, "on_create_new_sequence"), nil, icons.plus, {help = "Create a new world camera sequence"})
    self._sequence_list:GetToolbar():tb_imgbtn("StopSequence", ClassClbk(self, "on_stop_sequence"), nil, icons.stop, {help = "Stop current test world camera"})

    self._built = true
end

function WorldCamTool:toggle_show_framing_gui(item)
	local visible = item:Value()
	self._forced_show_framing_gui = visible

	self._workspace:panel():set_alpha(0.5)
	self:set_gui_visible(visible)
end

function WorldCamTool:set_gui_visible(visible, external_forced)
	if self._gui_visible ~= visible or self._forced_show_framing_gui then
		if visible and (self._forced_show_framing_gui or managers.worldcamera:use_gui() or external_forced) then
			self._workspace:show()
		else
			self._workspace:hide()
		end

		self._gui_visible = visible
	end
end

function WorldCamTool:mouse_busy()
    return self:active()
end

function WorldCamTool:mouse_pressed(b, x, y)
    if not self:active() or not self._current_world_camera then
        return false
    end

    if b == Idstring("1") then
        self:add_point()
    end

	return true
end


function WorldCamTool:update(t, dt)
	if not managers.worldcamera._current_world_camera and not self._look_through_camera and self._current_world_camera then
		self._current_world_camera:debug_draw_editor()

		if self._current_point then
			Application:draw_sphere(self._current_point.pos, 40, 0, 1, 0)
		end
	end

	if self._current_world_camera then
		local fov = self._current_world_camera:value_at_time(self._current_time, "fov")
		local roll = self._current_world_camera:value_at_time(self._current_time, "roll")
		local near_dof = self._current_world_camera:value_at_time(self._current_time, "near_dof")
		local far_dof = self._current_world_camera:value_at_time(self._current_time, "far_dof")
		local dof_padding = self._current_world_camera:dof_padding()
		local dof_clamp = self._current_world_camera:dof_clamp()

		if self._look_through_camera then
			local pos, t_pos = self._current_world_camera:positions_at_time(self._current_time)

			if pos and t_pos then
				local rot1 = Rotation((t_pos - pos):normalized(), roll)
				local rot = Rotation:look_at(pos, t_pos, rot1:z())

				managers.editor:set_camera(pos, rot)
			end

			managers.editor:set_camera_fov(fov)
			managers.worldcamera:update_dof_values(near_dof, far_dof, dof_padding, dof_clamp)
			if shift() then
				self:look_through_camera()
			end
		end

		local divider = " | "
		local floats = math.log10(self._time_precision)
		local time_data = "Key Time: ".. string.format("%." .. floats .. "f", self._current_time)..divider
		time_data = time_data.."Fov: ".. string.format("%.0f", fov)..divider
		time_data = time_data.."Roll: ".. string.format("%.0f", roll) .."\n"
		time_data = time_data.."Near Dof: "..string.format("%.0f", near_dof)..divider
		time_data = time_data.."Far Dof: "..string.format("%.0f", far_dof)
	
		self._keys_list:GetItem("TimeData"):SetText(time_data)
	end
end

function WorldCamTool:set_visible(visible)
    WorldCamTool.super.set_visible(self, visible)
    if visible then
        self:update_camera_list()
        self:update_sequence_list()
    end
end

function WorldCamTool:look_through_camera(item)
	self._look_through_camera = not self._look_through_camera
	item = item or self._keys_list:GetItem("LookThroughCamera")
    item.enabled_alpha = self._look_through_camera and 1 or 0.5
    item:SetEnabled(item.enabled)
	managers.editor:set_camera_locked(self._look_through_camera)

	if not self._look_through_camera then
		managers.editor:set_camera_fov(managers.editor:default_camera_fov())
		managers.editor:set_camera_roll(0)
		managers.worldcamera:stop_dof()
	elseif self._current_world_camera then
		-- Nothing
	end
end

---------------------- Cameras --------------------------

function WorldCamTool:create_new()
    BLE.InputDialog:Show({title = "Enter name for the new camera", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = function()
                self:create_new()
            end})
            return
        elseif managers.worldcamera:all_world_cameras()[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Name already taken!", callback = function()
                self:create_new()
            end})
            return
        end

        managers.worldcamera:create_world_camera(name)
        self:update_camera_list()
        
        for _, camera_item in pairs(self._camera_list:Items()) do
            if camera_item.name == name then
                self:select_camera(camera_item)
            end
        end

    end})
end

function WorldCamTool:delete_camera(name)
	if name then
        BLE.Utils:YesNoQuestion("Delete the selected camera?", function()
            managers.worldcamera:remove_world_camera(name)
            self:update_camera_list()

            if self._current_world_camera_name == name then
                self._current_world_camera = nil
				self._current_world_camera_name = nil
                self._current_point = nil

                self:update_point_list()
                local settings = self._holder:GetItem("Settings")
                local points = self._holder:GetItem("Points")
                local keys = self._holder:GetItem("Keys")
                settings:SetEnabled(false)
                points:SetEnabled(false)
                keys:SetEnabled(false)

                settings:GetItem("StartAcceleration"):SetSelectedItem("linear")
                settings:GetItem("EndAcceleration"):SetSelectedItem("linear")

                managers.editor:set_camera_fov(managers.editor:default_camera_fov())
                managers.editor:set_camera_roll(0)
            end
        end)
	end
end

function WorldCamTool:select_camera(item)
	local name = item and item:Name() or self:selected_camera()
	self._current_point = nil

	if name then
		self._current_world_camera = managers.worldcamera:world_camera(name)
        self._current_world_camera_name = name

        for _, camera_item in pairs(self._camera_list:Items()) do
            camera_item:SetBorder({left = camera_item.name == name})
        end

        local settings = self._holder:GetItem("Settings")
        local points = self._holder:GetItem("Points")
        local keys = self._holder:GetItem("Keys")
        settings:GetItem("CameraDuration"):SetValue(self._current_world_camera:duration())
        settings:GetItem("EndDelay"):SetValue(self._current_world_camera:delay())
		settings:GetItem("DofPadding"):SetValue(self._current_world_camera:dof_padding())
		settings:GetItem("DofAmount"):SetValue(self._current_world_camera:dof_clamp())
        self:update_point_list()

        settings:GetItem("CurveType"):SetSelectedItem(self._current_world_camera._curve_type)
        self._sine_alert:SetVisible(self._current_world_camera._curve_type == "sine")
		settings:GetItem("StartAcceleration"):SetSelectedItem(self._current_world_camera:in_acc_string())
        settings:GetItem("EndAcceleration"):SetSelectedItem(self._current_world_camera:out_acc_string())

        settings:SetEnabled(true)
        points:SetEnabled(true)
        keys:SetEnabled(true)
		self:populate_keys(1)
	end
end

function WorldCamTool:change_acc(type, item)
	local name = self:selected_camera()

	if name then
		if type == "in" then
			managers.worldcamera:world_camera(name):set_in_acc(item:SelectedItem())
		elseif type == "out" then
			managers.worldcamera:world_camera(name):set_out_acc(item:SelectedItem())
		end
	end
end

function WorldCamTool:set_type(item)
	local name = self:selected_camera()
    local value = item:SelectedItem()

	if name and value then
		if value == "bezier" then
			managers.worldcamera:world_camera(name):set_curve_type_bezier()
            self._sine_alert:SetVisible(false)
		elseif value == "sine" then
			managers.worldcamera:world_camera(name):set_curve_type_sine()
            self._sine_alert:SetVisible(true)
		end
        self:update_point_list()
	end
end

function WorldCamTool:set_duration(item)
	local name = self:selected_camera()

	if name then
		managers.worldcamera:world_camera(name):set_duration(item:Value())
	end
end

function WorldCamTool:set_delay(item)
	local name = self:selected_camera()

	if name then
		managers.worldcamera:world_camera(name):set_delay(item:Value())
	end
end

function WorldCamTool:set_dof_padding(item)
	local name = self:selected_camera()

	if name then
		managers.worldcamera:world_camera(name):set_dof_padding(item:Value())
	end
end

function WorldCamTool:set_dof_clamp(item)
	local name = self:selected_camera()

	if name then
		managers.worldcamera:world_camera(name):set_dof_clamp(item:Value())
	end
end

function WorldCamTool:test_camera()
	local name = self:selected_camera()

	if name then

		self._test_done_callback = managers.worldcamera:add_world_camera_done_callback(name, ClassClbk(self, "test_done"))

		managers.worldcamera:play_world_camera(name)
	end
end

function WorldCamTool:test_done()
	managers.editor:force_editor_state()

	if self._look_through_camera then
		-- Nothing
	end
end

function WorldCamTool:stop_camera()
	if self._current_world_camera then
		managers.worldcamera:stop_world_camera()
		--managers.editor:force_editor_state()
	end
end


function WorldCamTool:selected_camera()
	return self._current_world_camera_name
end

function WorldCamTool:selected_world_camera()
	local name = self:selected_camera()

	if name then
		return managers.worldcamera:world_camera(name)
	end

	return nil
end


function WorldCamTool:update_camera_list()
    self._camera_list:ClearItems()

	for name, _ in pairs(managers.worldcamera:all_world_cameras()) do
        local btn = self._camera_list:button(name, ClassClbk(self, "select_camera"), {border_left = self._current_world_camera_name and self._current_world_camera_name == name})
        btn:tb_imgbtn("Remove", ClassClbk(self, "delete_camera", name), nil, BLE.Utils.EditorIcons.cross, {highlight_color = Color.red})
	end
	self._holder:AlignItems(true)
end

---------------------- Points --------------------------

function WorldCamTool:update_point_list()
    local name = self:selected_camera()
	local icons = BLE.Utils.EditorIcons

	self._point_list:ClearItems()
	self._point_list:GetToolbar():tb_imgbtn("AddPoint", ClassClbk(self, "add_point"), nil,  icons.plus, {help = "Add point"})
	self._point_list:divider("Help", {text="Create new point: Right mouse button", border_color = Color.green})
    if name then
        for i, point in ipairs(managers.worldcamera:world_camera(name):get_points()) do
            local div = self._point_list:divider("Point "..i)
            div:tb_imgbtn("Delete", ClassClbk(self, "delete_point", i), nil, icons.cross, {help = "Delete point", highlight_color = Color.red})
            div:tb_imgbtn("Move", ClassClbk(self, "move_point", i), nil, icons.reset_settings, {help = "Move point to current camera location"})
            div:tb_imgbtn("Goto", ClassClbk(self, "goto_point", i), nil, icons.jump_cam, {help = "Goto point"})
        end
    end
	self._holder:AlignItems(true)
end

function WorldCamTool:add_point()
	local name = self:selected_camera()

	if name then
        local camera = self:selected_world_camera()
        
        if camera and (camera._curve_type == "sine" or #camera:get_points() < 4) then
            local cam = managers.editor._vp:camera()

            camera:add_point(cam:position(), cam:rotation())
			self:update_point_list()
        else
            BLE.Utils:Notify("Error!", "Cameras with the Bezier curve type can only have up to 4 points.")
        end
		self._holder:AlignItems(true)
	end
end

function WorldCamTool:move_point(point)
	local name = self:selected_camera()

	if point and name then
		local cam = managers.editor._vp:camera()

		managers.worldcamera:world_camera(name):move_point(point, cam:position(), cam:rotation())
        --self:update_point_list()
	end
end

function WorldCamTool:delete_point(point, item)
	local name = self:selected_camera()

	if point and name then
		managers.worldcamera:world_camera(name):delete_point(point)
        self:update_point_list()
	end
end

function WorldCamTool:goto_point(point)
	local name = self:selected_camera()

	if point and name then
		local p = managers.worldcamera:world_camera(name):get_point(point)
		local rot = Rotation(p.t_pos - p.pos, Vector3(0, 0, 1))

		managers.editor:set_camera(p.pos, rot)
	end
end


---------------------- Keys --------------------------

function WorldCamTool:set_time(item)
	self._current_time = item:Value()
end

function WorldCamTool:add_key()
	local camera = self:selected_world_camera()

	if camera then
		local index = camera:add_key(self._current_time)

		self:populate_keys(index)
	end
end

function WorldCamTool:delete_key()
	local camera = self:selected_world_camera()

	if camera then
		local index = tonumber(self._keys_list:GetItem("SelectKey"):Value())

		if index == 1 then
			BLE.Utils:Notify("Error!", "Cant delete the first key")
			--managers.editor:output_info("Won't delete key 1")

			return
		end

		camera:delete_key(index)
        
	    self:populate_keys()
		self:prev_key()
	end
end

function WorldCamTool:populate_keys(index)
	local time = self._keys_list:GetItem("Time")
    local keys = self._keys_list:GetItem("SelectKey")
	keys:ClearItems()
	time:ClearItems()

	local camera = self:selected_world_camera()
	if camera then
        local items = {}
        for i, key in ipairs(camera:keys()) do
			table.insert(items, i)
			time:img(i, {texture = "guis/textures/menu_ui_icons", texture_rect = {92, 1, 34, 34}, size = keys.size - 7, highlight_image = false, img_color = index and index == i and Color.green or Color.white, position = function(item)
				item:SetX(time.sbg:w() * key.time + ((time.circle:w() - item:W()) / 2))
				item:SetPositionByString("Centery")
				item:SetLayer(2)
			end})
		end
		keys:SetItems(items)

        index = index or 1
        local key = camera:key(index)
        local time = key.time
        local fov = key.fov
        local near_dof = key.near_dof
        local far_dof = key.far_dof
        local roll = key.roll
    
        keys:SetValue(index or 1)
        self:set_key_values(time, fov, near_dof, far_dof, roll)
	end
end

function WorldCamTool:set_key_values(time, fov, near_dof, far_dof, roll)
	if fov then
        self._keys_list:GetItem("Fov"):SetValue(fov)
	end

	if near_dof then
        self._keys_list:GetItem("NearDof"):SetValue(near_dof)
	end

	if far_dof then
        self._keys_list:GetItem("FarDof"):SetValue(far_dof)
	end

	if roll then
        self._keys_list:GetItem("Roll"):SetValue(roll)
	end

	if time then
		--local floats = math.log10(self._time_precision)
        self._keys_list:GetItem("KeyTime"):SetValue(time)
	end
end

function WorldCamTool:select_key(item)
	self:set_key(tonumber(item:Value()))
end

function WorldCamTool:set_key(index)
	local camera = self:selected_world_camera()

	if camera then
		local key = camera:key(index)
		local time = key.time
		local fov = key.fov
		local near_dof = key.near_dof
		local far_dof = key.far_dof
		local roll = key.roll

        self._keys_list:GetItem("SelectKey"):SetValue(index)
        self._keys_list:GetItem("KeyTime"):SetValue(key.time)
		self._keys_list:GetItem("Time"):SetValue(key.time, true)

		for i, item in ipairs(self._keys_list:GetItem("Time"):Items()) do
			item.img:set_color(index and i == index and Color.green or Color.white)
		end

		self:set_key_values(time, fov, near_dof, far_dof, roll)
	end
end

function WorldCamTool:next_key()
	local camera = self:selected_world_camera()

	if camera then
		local index = camera:next_key(self._current_time)

		self:set_key(index)
	end
end

function WorldCamTool:prev_key()
	local camera = self:selected_world_camera()

	if camera then
		local index = camera:prev_key(self._current_time, true)

		self:set_key(index)
	end
end

function WorldCamTool:on_key_time(item)
	local camera = self:selected_world_camera()

	if camera then
		local old_index = tonumber(self._keys_list:GetItem("SelectKey"):Value())
		local new_index = camera:move_key(old_index, tonumber(item:Value()))

		self:populate_keys(new_index)
	end
end

function WorldCamTool:on_key_fov(item)
	local camera = self:selected_world_camera()

	if camera then
		local key = camera:key(self._keys_list:GetItem("SelectKey"):Value())
		key.fov = item:Value()
	end
end

function WorldCamTool:on_key_near_dof(item)
	local camera = self:selected_world_camera()

	if camera then
		local key = camera:key(self._keys_list:GetItem("SelectKey"):Value())
		local near_dof = item:Value()

		if near_dof == "" then
			near_dof = 0
		end

		key.near_dof = near_dof
	end
end

function WorldCamTool:on_key_far_dof(item)
	local camera = self:selected_world_camera()

	if camera then
		local key = camera:key(self._keys_list:GetItem("SelectKey"):Value())
		local far_dof = item:Value()

		if far_dof == "" then
			far_dof = 0
		end

		key.far_dof = far_dof
	end
end

function WorldCamTool:on_set_roll(item)
	local camera = self:selected_world_camera()

	if camera then
		local key = camera:key(self._keys_list:GetItem("SelectKey"):Value())
		local roll = item:Value()
		key.roll = roll
	end
end

---------------------- Sequences --------------------------

function WorldCamTool:on_create_new_sequence()
	BLE.InputDialog:Show({title = "Enter name for the new sequence", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = function()
                self:on_create_new_sequence()
            end})
            return
        elseif managers.worldcamera:all_world_camera_sequences()[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Name already taken!", callback = function()
                self:on_create_new_sequence()
            end})
            return
        end

		managers.worldcamera:create_world_camera_sequence(name)
		self:update_sequence_list()
	end})
end

function WorldCamTool:on_delete_sequence(name)
	BLE.Utils:YesNoQuestion("Delete the selected world camera sequence?", function()
		if name then
			managers.worldcamera:remove_world_camera_sequence(name)
			self:update_sequence_list()
		end
	end)
end

function WorldCamTool:update_sequence_list()
	self._sequence_list:ClearItems("sequences")
	local icons = BLE.Utils.EditorIcons

	for name, data in pairs(managers.worldcamera:all_world_camera_sequences()) do
		local div = self._sequence_list:divider(name, {label = "sequences", text = name.." ("..#data..")"})
		div:tb_imgbtn("Delete", ClassClbk(self, "on_delete_sequence", name), nil, icons.cross, {help = "Delete world camera sequence", highlight_color = Color.red})
		div:tb_imgbtn("Manage", ClassClbk(self, "on_manage_sequence", name), nil, icons.settings_gear, {help = "Manage sequence"})
		div:tb_imgbtn("TestSequence", ClassClbk(self, "on_test_sequence", name), nil, icons.play, {help = "Test world camera sequence"})
	end
	if #self._sequence_list:Items() == 1 then
		self._sequence_list:divider("Empty", {label = "sequences", text = "There are no created camera sequences"})
	end
	self._holder:AlignItems(true)
end

function WorldCamTool:on_test_sequence(name)
	if name and #managers.worldcamera:world_camera_sequence(name) > 0 then
		managers.worldcamera:play_world_camera_sequence(name)
		self._sequence_test_done_callback = managers.worldcamera:add_sequence_done_callback(name, ClassClbk(self, "sequence_test_done"))
	end
end

function WorldCamTool:sequence_test_done()
	managers.editor:force_editor_state()
end

function WorldCamTool:on_stop_sequence()
	managers.worldcamera:stop_world_camera()
end

function WorldCamTool:on_manage_sequence(name)
	if name and managers.worldcamera:all_world_camera_sequences()[name] then
		local entry_values = {{name = "Sample Stop Time", key = "stop"}, {name = "Sample Start Time", key = "start"}}
		local list = {}
		for name, _ in pairs(managers.worldcamera:all_world_cameras()) do
			local entry = {name = name, values = {1, 0}}
			table.insert(list, entry)
		end

		local selected_list = {}
		for i, data in ipairs(managers.worldcamera:world_camera_sequence(name)) do
			local entry = {name = data.name, values = {data.stop, data.start}}
			table.insert(selected_list, entry)
		end

		BLE.SelectDialogValue:Show({
			selected_list = selected_list,
			list = list,
			entry_values = entry_values,
			callback = ClassClbk(self, "on_move_camera_in_sequence", name)
		})
	end
end

function WorldCamTool:on_move_camera_in_sequence(name, final_selected_list)
	local sequence = managers.worldcamera:world_camera_sequence(name)
	local sequences = #sequence
	for i = 1, sequences do
		managers.worldcamera:remove_camera_from_sequence(name, 1)
	end
	for i, data in pairs(final_selected_list) do
		local stop = math.clamp(data.values[1], 0, 1)
		local start = math.clamp(data.values[2], 0, 1)
		local camera_sequence_table = {name = data.name, stop = stop, start = start}
		managers.worldcamera:insert_camera_to_sequence(name, camera_sequence_table, i)
	end
	self:update_sequence_list()
end
