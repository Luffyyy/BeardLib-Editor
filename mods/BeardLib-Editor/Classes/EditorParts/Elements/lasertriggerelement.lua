EditorLaserTrigger = EditorLaserTrigger or class(MissionScriptEditor) --TODO: making connections and points
EditorLaserTrigger.SAVE_UNIT_POSITION = false
EditorLaserTrigger.SAVE_UNIT_ROTATION = false
EditorLaserTrigger.ON_EXECUTED_ALTERNATIVES = {
	"enter",
	"leave",
	"empty",
	"while_inside"
}
EditorLaserTrigger.USES_INSTIGATOR_RULES = true
EditorLaserTrigger.CLOSE_DISTANCE = 25
EditorLaserTrigger.COLORS = {
	red = {
		1,
		0,
		0
	},
	green = {
		0,
		1,
		0
	},
	blue = {
		0,
		0,
		1
	}
}
function EditorLaserTrigger:init(unit)
	EditorLaserTrigger.super.init(self, unit)
	self._dummy_unit_name = Idstring("units/payday2/props/gen_prop_lazer_blaster_dome/gen_prop_lazer_blaster_dome")
	self._element.class = "ElementLaserTrigger"
	self._element.values.trigger_times = 1
	self._element.values.interval = 0.1
	self._element.values.instigator = managers.mission:default_area_instigator()
	self._element.values.color = "red"
	self._element.values.visual_only = false
	self._element.values.skip_dummies = false
	self._element.values.cycle_interval = 0
	self._element.values.cycle_random = false
	self._element.values.cycle_active_amount = 1
	self._element.values.cycle_type = "flow"
	self._element.values.flicker_remove = nil
	self._element.values.points = {}
	self._element.values.connections = {}
end
function EditorLaserTrigger:update_editing(...)
	local ray = self:_raycast()
	if self._moving_point and ray then
		local moving_point = self._element.values.points[self._moving_point]
		moving_point.pos = ray.position
		moving_point.rot = Rotation(ray.normal, math.UP)
	end
end
function EditorLaserTrigger:begin_editing(...)
	self._dummy_unit = World:spawn_unit(self._dummy_unit_name, Vector3(), Rotation())
end
function EditorLaserTrigger:end_editing(...)
	EditorLaserTrigger.super.end_editing(self, ...)
	World:delete_unit(self._dummy_unit)
	self:_break_creating_connection()
	self:_break_moving_point()
end
function EditorLaserTrigger:update()
	for _, point in pairs(self._element.values.points) do
		self:_draw_point(point.pos, point.rot, 0, 0.5, 0)
	end
	for i, connection in ipairs(self._element.values.connections) do
		local s_p = self._element.values.points[connection.from]
		local e_p = self._element.values.points[connection.to]
		local r, g, b = unpack(self.COLORS[self._element.values.color])
		if self._selected_connection and self._selected_connection == i then
			Application:draw_line(s_p.pos, e_p.pos, 1, 1, 1)
		else
			Application:draw_line(s_p.pos, e_p.pos, r, g, b)
		end
	end
end
function EditorLaserTrigger:_raycast()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(100000)
	local ray = World:raycast(from, to, nil, managers.slot:get_mask("all"))
	if ray and ray.position then
		local index, point = self:_get_close_point(self._element.values.points, ray.position)
		local r, g, b = unpack(self.COLORS[self._element.values.color])
		if point then
			if self._creating_connection then
				local creating_point = self._element.values.points[self._creating_connection]
				Application:draw_line(creating_point.pos, point.pos, r * 0.6, g * 0.6, b * 0.6)
				self:_draw_point(point.pos, point.rot, 0, 1, 0)
			else
				self:_draw_point(point.pos, point.rot, 1, 0, 0)
			end
		else
			if self._creating_connection then
				local creating_point = self._element.values.points[self._creating_connection]
				Application:draw_line(creating_point.pos, ray.position, r * 0.6, g * 0.6, b * 0.6)
			end
			self:_draw_point(ray.position, Rotation(ray.normal, math.UP))
		end
		self._dummy_unit:set_position(ray.position)
		self._dummy_unit:set_rotation(Rotation(ray.normal, math.UP))
		return ray
	end
	return nil
end
function EditorLaserTrigger:_get_close_point(points, pos)
	for i, point in pairs(points) do
		if point.pos - pos:length() < self.CLOSE_DISTANCE then
			return i, point
		end
	end
	return nil, nil
end
function EditorLaserTrigger:_draw_point(pos, rot, r, g, b)
	r = r or 1
	g = g or 1
	b = b or 1
	local len = 25
	local scale = 0.05
	Application:draw_sphere(pos, 5, r, g, b)
	Application:draw_arrow(pos, pos + rot:x() * len, 1, 0, 0, scale)
	Application:draw_arrow(pos, pos + rot:y() * len, 0, 1, 0, scale)
	Application:draw_arrow(pos, pos + rot:z() * len, 0, 0, 1, scale)
end
function EditorLaserTrigger:_remove_any_close_point(pos)
	local index, point = self:_get_close_point(self._element.values.points, pos)
	if index then
		self:_check_remove_index(index)
		self._element.values.points[index] = nil
		return true
	end
	return false
end
function EditorLaserTrigger:_break_creating_connection()
	if alive(self._dummy_unit) then
		self._dummy_unit:set_enabled(true)
	end
	self._creating_connection = nil
end
function EditorLaserTrigger:_break_moving_point()
	self._moving_point = nil
	self._moving_point_undo = nil
end
function EditorLaserTrigger:_rmb()
	if self._moving_point then
		self._element.values.points[self._moving_point] = self._moving_point_undo
		self:_break_moving_point()
		return
	end
	if self._creating_connection then
		self:_break_creating_connection()
		return
	end
	print("EditorLaserTrigger:_rmb()")
	local ray = self:_raycast()
	if not ray then
		return
	end
	local pos = ray.position
	local rot = Rotation(ray.normal, math.UP)
	if self:_remove_any_close_point(pos) then
		return
	end
	table.insert(self._element.values.points, {pos = pos, rot = rot})
end
function EditorLaserTrigger:_lmb()
	print("EditorLaserTrigger:_lmb()")
	if self._moving_point then
		return
	end
	local ray = self:_raycast()
	if not ray then
		return
	end
	local pos = ray.position
	local rot = Rotation(ray.normal, math.UP)
	local index, point = self:_get_close_point(self._element.values.points, pos)
	print("index", index)
	if not point then
		print("break starting connection")
		self:_break_creating_connection()
		return
	end
	if self._creating_connection then
		if self._creating_connection == index then
			print("break (same) starting connection")
		else
			print("finish starting connection")
			if not self:_check_remove_connection(self._creating_connection, index) then
				table.insert(self._element.values.connections, {
					from = self._creating_connection,
					to = index
				})
				self:_fill_connections_box()
			end
		end
		self:_break_creating_connection()
	else
		print("start creating connection")
		self._dummy_unit:set_enabled(false)
		self._creating_connection = index
	end
end
function EditorLaserTrigger:_emb()
	if self._creating_connection then
		return
	end
	print("EditorLaserTrigger:_emb()")
	local ray = self:_raycast()
	if not ray then
		return
	end
	local pos = ray.position
	local rot = Rotation(ray.normal, math.UP)
	local index, point = self:_get_close_point(self._element.values.points, pos)
	print("index", index)
	if not point then
		return
	end
	self._moving_point_undo = clone(point)
	self._moving_point = index
end
function EditorLaserTrigger:_release_emb()
	print("EditorLaserTrigger:_release_emb()")
	if self._moving_point then
		self:_break_moving_point()
	end
end
function EditorLaserTrigger:_check_remove_index(index)
	for i, connection in ipairs(clone(self._element.values.connections)) do
		if connection.from == index or connection.to == index then
			if self._selected_connection and self._selected_connection == i then
				self._selected_connection = nil
			end
			table.remove(self._element.values.connections, i)
			self:_fill_connections_box()
			self:_check_remove_index(index)
			return
		end
	end
end
function EditorLaserTrigger:_check_remove_connection(i1, i2)
	for i, connection in ipairs(clone(self._element.values.connections)) do
		if connection.from == i1 and connection.to == i2 or connection.from == i2 and connection.to == i1 then
			table.remove(self._element.values.connections, i)
			self:_fill_connections_box()
			if self._selected_connection and self._selected_connection == i then
				self._selected_connection = nil
			end
			return true
		end
	end
	return false
end
function EditorLaserTrigger:add_triggers(vc)
	EditorLaserTrigger.super.add_triggers(self, vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "_lmb"))
	vc:add_trigger(Idstring("rmb"), callback(self, self, "_rmb"))
	vc:add_trigger(Idstring("emb"), callback(self, self, "_emb"))
	vc:add_release_trigger(Idstring("emb"), callback(self, self, "_release_emb"))
end
function EditorLaserTrigger:_on_clicked_connections_box()
	print("EditorLaserTrigger:_on_clicked_connections_box()")
	local selected_index = self._connections_box:selected_index()
	if not selected_index then
		self._selected_connection = nil
		return
	end
	print(self._connections_box:get_string(selected_index))
	self._selected_connection = tonumber(self._connections_box:get_string(selected_index))
end
function EditorLaserTrigger:_fill_connections_box()
	--self._connections_box:clear()
	for i, connection in ipairs(self._element.values.connections) do
		--self._connections_box:append(i)
	end
end
function EditorLaserTrigger:_move_connection_up()
	print("EditorLaserTrigger:_move_connection_up()")
	if not self._selected_connection or self._selected_connection == 1 then
		return
	end
	local selected_index = self._connections_box:selected_index()
	table.insert(self._element.values.connections, self._selected_connection - 1, table.remove(self._element.values.connections, self._selected_connection))
	self:_fill_connections_box()
	self._connections_box:select_index(selected_index - 1)
	self:_on_clicked_connections_box()
end
function EditorLaserTrigger:_move_connection_down()
	print("EditorLaserTrigger:_move_connection_down()")
	if not self._selected_connection or self._selected_connection == #self._element.values.connections then
		return
	end
	local selected_index = self._connections_box:selected_index()
	table.insert(self._element.values.connections, self._selected_connection + 1, table.remove(self._element.values.connections, self._selected_connection))
	self:_fill_connections_box()
	self._connections_box:select_index(selected_index + 1)
	self:_on_clicked_connections_box()
end
function EditorLaserTrigger:_build_panel()
	self:_create_panel()
	self:NumberCtrl("interval", {floats = 2, min = 0.01, help = "Set the check interval for the laser, in seconds", text = "Check interval"})
	self:ComboCtrl("instigator", managers.mission:area_instigator_categories(), {help = "Select an instigator type"})
	self:ComboCtrl("color", {"red","green","blue"})
	self:BooleanCtrl("visual_only")
	self:BooleanCtrl("skip_dummies")
	self:BooleanCtrl("flicker_remove", {help = "Will flicker the lasers when removed"})
	self:BooleanCtrl("cycle_interval", {floats = 2, min = 0, help = "Set the check cycle interval for the laser, in seconds (0 == disabled)"})
	self:BooleanCtrl("cycle_active_amount", {floats = 0, min = 1, help = "Defines how many are active during cycle"})
 	self:ComboCtrl("cycle_type", {"flow", "pop"})
 	self:BooleanCtrl("cycle_random")
	self:_fill_connections_box()
end