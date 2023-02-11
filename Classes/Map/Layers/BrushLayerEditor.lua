BrushLayerEditor = BrushLayerEditor or class(LayerEditor)

function BrushLayerEditor:init(parent)
    BrushLayerEditor.super.init(self, parent, "BrushLayerEditorEditor", {private = {h = parent._holder:ItemsHeight(1, 6)}})

	self._brush_names = {}
	self._brush_types = {}
	self._brush_size = 15
	self._brush_density = 3
	self._brush_pressure = 1
	self._random_roll = 0
	self._spraying = false
	self._erasing = false
	self._brush_height = 40
	self._angle_override = 0
	self._offset = 0
	self._visible = true
	self._erase_with_pressure = false
	self._erase_with_units = false
	self._overide_surface_normal = false
	self._brush_on_editor_bodies = false
	self._amount_dirty = true

	--self:load_unit_map_from_vector(CoreEditorUtils.layer_type("brush"))

	self._place_slot_mask = managers.slot:get_mask("brush_placeable")
	self._brush_slot_mask = managers.slot:get_mask("brushes")
	self._unit_brushes = {}
	self._brush_units = clone(BLE.Brushes)
	self._selected_unit_names = {}
	self._brushed_path = "core/temp/editor_temp/brushes"

	--self:load_brushes()
end

function BrushLayerEditor:save()
	if not self._needs_saving then
		return
	else
		self._needs_saving = false
	end

	local data = self._parent:data()
	data.brush = data.brush or {file = "massunit"}
	data.brush.preload_units = {}

	local file = data.brush.file
	local level_path = BLE.MapProject:current_level_path()
	local massunit_path = Path:Combine(level_path, file..".massunit")

	-- If the file doesn't exist, create a dummy one before the tool creates the real one to "fool" the saving function into thinking there's a massunit.
	if not FileIO:Exists(massunit_path) then
		FileIO:CopyFile(Path:Combine(BLE.MapProject._templates_directory, "Level/massunit.massunit"), massunit_path)
	end

	local massunit = {path = Path:Combine(Application:base_path(), massunit_path), units = {}}

	-- Add anything that was already in the massunit manager
	for _, unit_name in ipairs(MassUnitManager:list()) do
		local rotations = MassUnitManager:unit_rotations(unit_name)
		local positions = MassUnitManager:unit_positions(unit_name)

		local clean_positions = {}
		local clean_rotations = {}
		for _, pos in pairs(positions) do
			table.insert(clean_positions, {pos.x, pos.y, pos.z})
		end
		for _, rot in pairs(rotations) do
			table.insert(clean_rotations, math.rot_to_quat(rot))
		end

		local unhashed = BLE.Utils:Unhash(unit_name, "unit")
		if unhashed then
			table.insert(data.brush.preload_units, unhashed)
		else
			table.insert(data.brush.preload_units, unit_name)
		end

		table.insert(massunit.units, {
			path = unit_name:key(),
			positions = clean_positions,
			rotations = clean_rotations
		})
	end

	-- Save brushes spawned by the editor in this session
	for _, header in pairs(self._brush_types) do
		header:check_alive_units()

		local clean_positions = {}
		local clean_rotations = {}
		for _, unit in pairs(header._units) do
			local pos = unit:position()
			local rot = unit:rotation()

			table.insert(clean_positions, {pos.x, pos.y, pos.z})
			table.insert(clean_rotations, math.rot_to_quat(rot))
		end

		table.insert(data.brush.preload_units, header._name)
		table.insert(massunit.units, {
			path = header._name:key(),
			positions = clean_positions,
			rotations = clean_rotations
		})
	end

	local tools_path = Path:Combine(BLE.ModPath, "Tools")
	local temp_massunit = Path:Combine(tools_path, "Temp/massunit.json")
	FileIO:WriteTo(temp_massunit, json.encode(massunit), "w")

	os.execute('start /min '..Path:Combine(tools_path, "MassunitMaker.exe"))
end

function BrushLayerEditor:unit_positions(name)
	local positions = MassUnitManager:unit_positions(name:id())
	local header = self._brush_types[name]
	if header then
		for _, unit in pairs(header._units) do
			if alive(unit) then
				table.insert(positions, unit:position())
			end
		end
	end
	return positions
end

function BrushLayerEditor:unit_rotations(name)
	local rotations = MassUnitManager:unit_rotations(name:id())
	local header = self._brush_types[name]
	if header then
		for _, unit in pairs(header._units) do
			if alive(unit) then
				table.insert(rotations, unit:rotation())
			end
		end
	end
	return rotations
end

function BrushLayerEditor:delete_units(name)
	MassUnitManager:delete_units(name:id())
	local header = self._brush_types[name]
	if header then
		for _, unit in pairs(header._units) do
			if alive(unit) then
				World:delete_unit(unit)
			end
		end
	end
	self._brush_types[name] = nil
end

function BrushLayerEditor:reposition_all()
	managers.editor:output("Reposition all brushes:")

	for _, name in pairs(self._brush_units) do
		local name_ids = name:id()
		local nudged_units = 0
		local positions = self:unit_positions(name)

		if #positions > 0 then
			local rotations = self:unit_rotations(name)

			self:delete_units(name)

			for counter = 1, #positions do
				local rot = rotations[counter]
				local pos = positions[counter]
				local from = pos + rot:z() * 50
				local to = pos - rot:z() * 110
				local ray_type = self._brush_on_editor_bodies and "body editor" or "body"
				local ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type, from, to)

				if ray then
					local brush_header = self:add_brush_header(name)
					local correct_pos = brush_header:spawn_brush(ray.position, rotations[counter])
					self._amount_dirty = true
					local nudge_length = (ray.position - correct_pos):length()

					if nudge_length > 0.05 then
						nudged_units = nudged_units + 1
					end
				else
					managers.editor:output(" * Lost one of type " .. name .. " - it was too alone at: " .. pos)
				end
			end
		end

		if nudged_units > 0 then
			managers.editor:output(" * Nudged " .. nudged_units .. " units of type " .. name)
		end
		self._amount_dirty = true
	end
end

function BrushLayerEditor:clear_all()
    BLE.Utils:YesNoQuestion("This will delete all brushes in this level, are you sure?", function()
		MassUnitManager:delete_all_units()
        for _, header in pairs(self._brush_types) do
			for _, unit in pairs(header._units) do
				if alive(unit) then
					World:delete_unit(unit)
				end
			end
        end
		self._brush_types = {}
        self._amount_dirty = true
    end)
end

function BrushLayerEditor:clear_unit()
    BLE.Utils:YesNoQuestion("This will delete all selected brushes in this level, are you sure?", function()
        for _, name in ipairs(self._brush_names) do
            self:delete_units(name)
        end

        self._amount_more_dirty = true
    end)
end

function BrushLayerEditor:_on_amount_updated()
	local brush_stats, total = self:get_brush_stats()

	local total_amount = total.amount
	local unique = 0
	for _, header in pairs(self._brush_types) do
		header:check_alive_units()
		local unit_count = #header._units
		if unit_count > 0 then
			unique = unique + 1
			total_amount = total_amount + #header._units
		end
	end

	self._debug_units_total:SetText("Total Units: " .. total_amount)
	self._debug_units_unique:SetText("Unique Units: " .. total.unique + unique)

	if self._debug_list and self._debug_list:visible() then
		self._debug_list:fill_unit_list()
	end
end

function BrushLayerEditor:set_visibility(cb)
	self._visible = cb:get_value()

	MassUnitManager:set_visibility(self._visible)
end

function BrushLayerEditor:select()
end

function BrushLayerEditor:spray_units()
	if not self._visible then
		return
	end

	self:erase_units_release()

	self._spraying = true
end

function BrushLayerEditor:spray_units_release()
	if self._spraying then
		self._spraying = false
	end
end

function BrushLayerEditor:erase_units()
	if not self._visible then
		return
	end

	self:spray_units_release()

	self._erasing = true
end

function BrushLayerEditor:erase_units_release()
	if self._erasing then
		self._erasing = false
	end
end

function BrushLayerEditor:is_my_unit()
	return false
end

function BrushLayerEditor:update(time, rel_time)
	if not self:active() then
		return
	end

	if self._amount_dirty then
		self._amount_dirty = nil
		self._needs_saving = true

		self:_on_amount_updated()
	end

	if self._amount_more_dirty then
		self._amount_more_dirty = nil
		self._amount_dirty = true
	end

	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(5000)
	local ray_type = self._brush_on_editor_bodies and "body editor" or "body"
	local ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type)
	local base, tip = nil

	if ray then
		Application:draw_circle(ray.position + ray.normal * 0.1, self._brush_size, 0, 0.7, 0, ray.normal)
		Application:draw_circle(ray.position + ray.normal * 0.1 + ray.normal * self._offset, self._brush_size, 0, 1, 0, ray.normal)

		base = ray.position - ray.normal * 40 - ray.normal * self._offset
		tip = ray.position + ray.normal * self._brush_height + ray.normal * self._offset

		Application:draw_circle(tip, self._brush_size, 0, 0.7, 0, ray.normal)
	else
		local ray_normal = (to - from):normalized()
		base = from + ray_normal * 1000
		tip = from + ray_normal * 10000
		local tunnel = 9000

		while tunnel > 0 do
			Application:draw_circle(base + ray_normal * tunnel, self._brush_size, 0.3 + 0.7 * tunnel / 9000, 0, 0, ray_normal)

			tunnel = tunnel * 0.9 - 100
		end

		Application:draw_circle(base, self._brush_size, 0.3, 0.2, 0.2, ray_normal)
	end

	if self._spraying and ray or self._erasing then
		local units = World:find_units_quick("cylinder", base, tip, self._brush_size, self._brush_slot_mask)
		local area = math.pi * math.pow(self._brush_size / 100, 2)
		local density = #units / area

		if self._spraying then
			local created = 0

			while created < self._brush_pressure and density <= self._brush_density do
				local nudge_amount = 1 - math.rand(self._brush_size * self._brush_size) / (self._brush_size * self._brush_size)
				local rand_nudge = ray.normal:random_orthogonal() * self._brush_size * nudge_amount
				local place_ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type, tip + rand_nudge, base + rand_nudge)

				self:create_brush(place_ray)

				created = created + 1
				density = (#units + created) / area
			end

			if self._brush_density == 0 then
				self:spray_units_release()
			end
		elseif self._erasing then
			if self._erase_with_pressure and ray then
				local removed = 0

				while removed < self._brush_pressure and removed < #units do
					removed = removed + 1
					local found = true

					if self._erase_with_units then
						found = false

						while not found and removed <= #units do
							if self:brush_names_contain(units[removed]:name()) then
								found = true
							else
								removed = removed + 1
							end
						end
					end

					if found then
						World:delete_unit(units[removed])

						self._amount_dirty = true
					end
				end

				if self._brush_density == 0 then
					self:erase_units_release()
				end
			else
				for _, brush in ipairs(units) do
					if not self._erase_with_units or self._erase_with_units and self:brush_names_contain(brush:name()) then
						World:delete_unit(brush)

						self._amount_dirty = true
					end
				end
			end
		end
	end

	if self._debug_draw_unit_orientation then
		self:_draw_unit_orientations()
	end
end

function BrushLayerEditor:brush_names_contain(name)
	for _, unit_name in pairs(self._brush_names) do
		return unit_name:id() == name
	end
end

function BrushLayerEditor:_draw_unit_orientations()
	local brush_stats = self:get_brush_stats()

	for _, stats in ipairs(brush_stats) do
		for i = 1, stats.amount do
			Application:draw_rotation(stats.positions[i], stats.rotations[i])
		end
	end
end

function BrushLayerEditor:add_brush_header(name)
	if not self._brush_types[name] then
		local header = BrushHeader:new()

		header:set_name(name)

		self._brush_types[name] = header

		return header
	else
		return self._brush_types[name]
	end
end

function BrushLayerEditor:create_brush(ray)
	if #self._brush_names > 0 and ray then
		local name = self._brush_names[math.floor(1 + math.rand(#self._brush_names))]

		self:add_brush_header(name)

		local brush_type = self._brush_types[name]
		local at = Vector3(0, 0, 1)
		local up = self._overide_surface_normal and Vector3(0, 0, 1) or ray.normal
		local rand_rotator = Rotation(up, math.rand(self._random_roll) - self._random_roll / 2)

		if self._angle_override ~= 0 then
			rand_rotator = Rotation(up, self._angle_override)
		end

		local right = nil

		if math.abs(up.z) > 0.7 then
			local camera_rot = managers.editor._vp:camera():rotation()

			if camera_rot:z():dot(up) < 0.7 then
				right = camera_rot:z():cross(up):rotate_with(rand_rotator)
				at = up:cross(right)
			else
				at = up:cross(camera_rot:x()):rotate_with(rand_rotator)
				right = at:cross(up)
			end
		else
			right = at:cross(up):rotate_with(rand_rotator)
			at = up:cross(right)
		end

		brush_type:spawn_brush(ray.position + up * self._offset, Rotation(right, at, up))

		self._amount_dirty = true
	end
end

function BrushLayerEditor:build_menu()
	self:GetPart("opt"):add_save_callback("save_massunit", ClassClbk(self, "save"))

	local h = self._holder:ItemsHeight(2)
	local icons = BLE.Utils.EditorIcons
    local controls = self._holder:group("Main", {align_method = "grid", auto_height = false, h = h*1/2})
	local tb = controls:GetToolbar()

	tb:tb_imgbtn("RepositionAll", ClassClbk(self, "reposition_all"), nil, icons.repos_brush, {help = "Tries to reposition all brushes down or to the sides"})
	tb:tb_imgbtn("ClearSelected", ClassClbk(self, "clear_unit"), nil, icons.cross_box, {help = "Clear all selected brushes"})
	tb:tb_imgbtn("ClearAll", ClassClbk(self, "clear_all"), nil, icons.trash, {help = "Clear all brushes"})

    local up = ClassClbk(self, "update_item")
    controls:numberbox("random_roll", up, self._random_roll, {min = 0, max = 360, text = "Random Roll [deg]"})
    self._radius_ctrl = controls:numberbox("brush_size", up, self._brush_size, {min = 1, max = 1000, text = "Radius [cm]"})
    controls:numberbox("brush_height", up, self._brush_height, {min = 0, max = 1000, text = "Height [cm]"})
    controls:numberbox("angle_override", up, self._angle_override, {min = 0, max = 360, text = "Angle [deg]"})
    controls:numberbox("offset", up, self._offset, {min = -30, max = 1000, text = "Offset [cm]]"})
    controls:slider("brush_density", up, self._brush_density, {min = 0, max = 30, text = "Density [/m^2]"})
    controls:slider("brush_pressure", up, self._brush_pressure, {min = 1, max = 20, text = "Pressure"})

    controls:tickbox("erase_with_pressure", up, self._erase_with_pressure, {text = "Pressure Erase", size_by_text = true})
    controls:tickbox("erase_with_units", up, self._erase_with_units, {text = "Erase with Selected Units", size_by_text = true})
    controls:tickbox("overide_surface_normal", up, self._overide_surface_normal, {text = "Override Surface Normal Rotation", size_by_text = true})
    controls:tickbox("brush_on_editor_bodies", up, self._brush_on_editor_bodies, {text = "Brush on Editor Bodies", size_by_text = true})
    controls:tickbox("Visible", ClassClbk(self, "set_visibility"), self._visible, {size_by_text = true})

	local debug = controls:group("Debug", {align_method = "grid", closed = true})

    debug:tickbox("debug_draw_unit_orientation", up, self._debug_draw_unit_orientation, {text = "Draw unit orientations"})
    --debug:s_btn("OpenDebugList", ClassClbk(self, "_on_gui_open_debug_list"), {enabled = false})

	self._debug_units_total = debug:lbl("Total Units:", {size_by_text = true})
	self._debug_units_unique = debug:lbl("Unique Units:", {size_by_text = true})

    self._unit_list = self._holder:divgroup("Units", {h = h*1/2, auto_height = false, auto_align = false, text = "Brushes"})
	self._unit_list:GetToolbar():textbox("Search", ClassClbk(self, "search_units"), "", {text = " ", control_slice = 1, w = self._unit_list:ItemsWidth() * 0.75, position = "RightCenteryOffset-x"})
	self:search_units()

    local brushes = self._holder:group("Brushes", {h = h, auto_height = false, align_method = "grid", visible = false})
	local brushes_tb = brushes:GetToolbar()

	brushes_tb:tb_imgbtn("Remove", ClassClbk(self, "remove_brush"), nil, icons.cross, {highlight_color = Color.red, help = "Remove brush"})
	brushes_tb:tb_imgbtn("AddScript", ClassClbk(self, "show_create_brush"), nil, icons.plus, {help = "Add Brush"})

    self._brush_list = brushes:pan("BrushList")
	for name, _ in pairs(self._unit_brushes) do
        self._brush_list:button(name, ClassClbk(self, "select_brush"), {text = name})
	end
end

function BrushLayerEditor:search_units(item)
	item = item or self._unit_list:GetItem("Search")
	local search = item:Value():lower():escape_special()
	self._unit_list:ClearItems("units")
	for _, name in pairs(self._brush_units) do
		if name:lower():match(search) then
			self._unit_list:button(name, ClassClbk(self, "select_unit"), {label = "units", text = name:gsub("units/", "")})
		end
	end
	self._unit_list:AlignItems()
end

function BrushLayerEditor:show_create_brush(data)
	if #self._brush_names > 0 then
        BLE.InputDialog:Show({
            title = "Enter name for the new brush configuration:",
            text = "",
            callback = function(name)
                if name and name ~= "" then
                    if self._unit_brushes[name] then
                        self:show_create_brush(data)
                    else
                        self._unit_brushes[name] = clone(self._brush_names)

                        local brush = self._brush_list:button(name, ClassClbk(self, "select_brush"), {text = name})

                        self:save_brushes()
                        self:select_brush(brush)
                    end
                end
            end
        })
	end
end

function BrushLayerEditor:hide_create_brush(data)
	data.dialog:end_modal()

	self._cancel_dialog = data.cancel
end

function BrushLayerEditor:remove_brush(brushes)
	local i = brushes:selected_index()

	if i >= 0 then
		self._unit_brushes[brushes:get_string(i)] = nil

		brushes:remove(i)
		self:save_brushes()

		self._brush_names = {}
	end
end

function BrushLayerEditor:save_brushes()
	if true then
		return
	end
	local f = SystemFS:open(managers.database:base_path() .. self._brushed_path .. ".xml", "w")

	f:puts("<brushes>")

	for name, unit_names in pairs(self._unit_brushes) do
		f:puts("\t<brush name=\"" .. name .. "\">")

		for _, unit_name in ipairs(unit_names) do
			f:puts("\t\t<unit name=\"" .. unit_name .. "\"/>")
		end

		f:puts("\t</brush>")
	end

	f:puts("</brushes>")
	f:close()
	managers.database:recompile(self._brushed_path)
end

function BrushLayerEditor:load_brushes()
	if DB:has("xml", self._brushed_path) then
		local node = DB:load_node("xml", self._brushed_path)

		for brush in node:children() do
			local name = brush:parameter("name")
			local unit_names = {}

			for unit in brush:children() do
				table.insert(unit_names, unit:parameter("name"))
			end

			self._unit_brushes[name] = unit_names
		end
	end
end

function BrushLayerEditor:select_unit(item)
	local name = item.name
	self._unit_name = name
	if not ctrl() then
		self._selected_unit_names = {}
	end
	if table.contains(self._selected_unit_names, name) then
		table.delete(self._selected_unit_names, name)
	else
		table.insert(self._selected_unit_names, name)
	end
	for _, unit_item in pairs(self._unit_list:Items()) do
		unit_item:SetBorder({left = table.contains(self._selected_unit_names, unit_item.name)})
	end

	self._brush_names = {}

	for _, unit_name in ipairs(self._selected_unit_names) do
		table.insert(self._brush_names, unit_name)
	end
end

function BrushLayerEditor:select_brush(item)
	for _, brush_item in pairs(self._brush_list:Items()) do
		brush_item:SetBorder({left = brush_item.name == item.name})
	end

	self._brush_names = {}
    self._selected_brush = item.name

	for _, name in ipairs(self._unit_brushes[item.name]) do
		table.insert(self._brush_names, name)
	end
end

function BrushLayerEditor:update_item(item)
	self["_"..item.name] = item:Value()
end

function BrushLayerEditor:get_brush_stats()
	local brush_stats = {}
	local total = {
		unique = 0,
		amount = 0
	}

	for _, unit_name in ipairs(MassUnitManager:list()) do
		local rotations = MassUnitManager:unit_rotations(unit_name)
		local positions = MassUnitManager:unit_positions(unit_name)
		local stats = {
			unit_name = unit_name,
			amount = #rotations,
			positions = positions,
			rotations = rotations
		}

		table.insert(brush_stats, stats)

		total.amount = total.amount + #rotations
		total.unique = total.unique + 1
	end

	return brush_stats, total
end

function BrushLayerEditor:active()
	return self._visible and self._holder:Visible()
end

function BrushLayerEditor:mouse_busy()
	return self:active()
end

function BrushLayerEditor:mouse_pressed(b, x, y)
	if not self:active() then
		return
	end
    if b == Idstring("0") then
        self:spray_units()
    elseif b == Idstring("1") then
        self:erase_units()
	elseif b == Idstring("mouse wheel up") then
		self._brush_size = math.clamp(self._brush_size+10, 1, 1000)
		self._radius_ctrl:SetValue(self._brush_size)
	elseif b == Idstring("mouse wheel down") then
		self._brush_size = math.clamp(self._brush_size-10, 1, 1000)
		self._radius_ctrl:SetValue(self._brush_size)
    end
	return true
end

function BrushLayerEditor:mouse_released(b, x, y)
	if not self._visible then
		return
	end
    if b == Idstring("0") then
        self:spray_units_release()
    elseif b == Idstring("1") then
        self:erase_units_release()
    end
	return true
end

------------------------------------- Brush Header -------------------------------------------

BrushHeader = BrushHeader or class()

function BrushHeader:init()
	self._name = ""
	self._distance = 0
	self._units = {}
end

function BrushHeader:check_alive_units()
	local new_units = {}
	for _, unit in pairs(self._units) do
		if alive(unit) then
			table.insert(new_units, unit)
		end
	end
	self._units = new_units
end

function BrushHeader:set_name(name)
	self._name = name

	if self._name then
		CoreUnit.editor_load_unit(self._name)
	end

	self:setup_brush_distance()
end

function BrushHeader:setup_brush_distance()
	if self._name then
		local ud = PackageManager:unit_data(self._name:id())
		local node = ud and ud.script_data and ud:script_data() or nil
		if node then
			for data in node:children() do
				if data:name() == "brush" then
					self._distance = tonumber(data:parameter("distance"))
				end
			end
		end
	end
end

function BrushHeader:get_spawn_dist()
	return self._distance
end

function BrushHeader:spawn_brush(position, rotation)
	local assets = managers.editor.parts.assets

	position = position + rotation:z() * self:get_spawn_dist()

	local function start_spawning()
		-- Massunit spawn function DOES NOT work properly. Glitches easily.
		table.insert(self._units, safe_spawn_unit(Idstring(self._name), position, rotation))
	end

	if assets:is_asset_loaded("unit", self._name) then
		start_spawning()
	else
		assets:quick_load_from_db("unit", self._name, start_spawning)
	end

	return position
end
