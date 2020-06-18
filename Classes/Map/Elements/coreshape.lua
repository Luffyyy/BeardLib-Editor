core:import("CoreShapeManager")
EditorShape = EditorShape or class(MissionScriptEditor)
function EditorShape:create_element()
	EditorShape.super.create_element(self)
	self._timeline_color = Vector3(1, 1, 0)
	self._brush = Draw:brush()
	self._element.class = "ElementShape"
	self._element.values.trigger_times = 0
	self._element.values.shape_type = "box"
	self._element.values.width = 500
	self._element.values.depth = 500
	self._element.values.height = 500
	self._element.values.radius = 250
end

function EditorShape:update_selected(t, dt, selected_unit, all_units)
	if not alive(self._unit) then
		return
	end
	local shape = self:get_shape(self)
	if shape then
		shape:draw(t, dt, 1, 1, 1)
	end
	EditorAreaTrigger.update_shape_position(self)
end

EditorShape.destroy = EditorAreaTrigger.destroy

function EditorShape:set_element_data(params, ...)
	EditorShape.super.set_element_data(self, params, ...)
	if params.name == "shape_type" then
		EditorAreaTrigger.set_shape_type(self)
	end
end

function EditorShape:_build_panel()
	self:_create_panel()
	self._shape_type = self:ComboCtrl("shape_type", {"box", "cylinder", "sphere"}, {help = "Select shape for area"})
	if not self._shape then
		EditorAreaTrigger.create_shapes(self)
	end
	self._width = self:NumberCtrl("width", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Width[cm]:", help ="Set the width for the shape"})
	self._depth = self:NumberCtrl("depth", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Depth[cm]:", help ="Set the depth for the shape"})
	self._height = self:NumberCtrl("height", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Height[cm]:", help ="Set the height for the shape"})
	self._radius = self:NumberCtrl("radius", {floats = 0, min = 0, on_callback = SimpleClbk(EditorAreaTrigger.set_shape_property, self), text = "Radius[cm]:", help ="Set the radius for the shape"})

	EditorAreaTrigger.set_shape_type(self)
end

function EditorShape:get_shape()
	return EditorAreaTrigger.get_shape(self)
end

--

EditorAreaDespawn = EditorAreaDespawn or class(EditorShape)
EditorAreaDespawn.LINK_ELEMENTS = {
	"shape_elements"
}
function EditorAreaDespawn:init(...)
	local unit = EditorAreaDespawn.super.init(self, ...)
	self._scripts = {}
	return unit
end

function EditorAreaDespawn:create_element(unit)
	EditorAreaDespawn.super.create_element(self, unit)

	self._element.class = "ElementAreaDespawn"
	self._hed.test_type = "unit_position"
	self._hed.shape_elements = nil

	self:build_slots_map()
end

function EditorAreaDespawn:build_slots_map()
	self._slots_map = {}

	for _, slot in ipairs(self._hed.slots or {}) do
		self._slots_map[slot] = true
	end
end

function EditorAreaDespawn:update_selected(t, dt)
	if self._hed.shape_elements then
		for _, id in ipairs(self._hed.shape_elements) do

			--This is awful tbh. Would be better to have these scripts exist all the time in a way. Last time I think I had issues with that.
			if not self._scripts[id] then
                local element = managers.mission:get_mission_element(id)
                local clss = MissionEditor:get_editor_class(element.class)
                if clss then
                    self._scripts[id] = clss:new(element)
                end
            else
				if not self._scripts[id]._shape then
					EditorAreaTrigger.create_shapes(self._scripts[id])
				end

                local shape = EditorAreaTrigger.get_shape(self._scripts[id])
                shape:draw(t, dt, 0.85, 0.85, 0.85)
			end
		end
	else
		EditorAreaDespawn.super.update_selected(self, t, dt)
	end
end

--One day we should implement these..
function EditorAreaDespawn:add_shape()
	local ray = managers.editor:unit_by_raycast({
		ray_type = "editor",
		mask = 10
	})

	if not ray then
		return
	end

	if getmetatable(ray.unit:mission_element()) ~= ShapeUnitElement then
		return
	end

	self._hed.shape_elements = self._hed.shape_elements or {}
	local id = ray.unit:unit_data().unit_id

	if table.contains(self._hed.shape_elements, id) then
		table.delete(self._hed.shape_elements, id)
	else
		table.insert(self._hed.shape_elements, id)
	end

	if #self._hed.shape_elements == 0 then
		self._hed.shape_elements = nil
	end

	EditorAreaTrigger.set_shape_type(self)
end

function EditorAreaDespawn:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_shape"))
end

function EditorAreaDespawn:draw_links(t, dt, selected_unit, all_units)
	EditorAreaDespawn.super.draw_links(self, t, dt, selected_unit, all_units)

	if self._hed.shape_elements then
		for _, id in ipairs(self._hed.shape_elements) do
			local unit = self:GetPart('mission'):get_element_unit(id)

			if self:_should_draw_link(selected_unit, unit) then
				local r, g, b = unit:mission_element():get_link_color()

				self:draw_link({
					from_unit = unit,
					to_unit = self._unit,
					r = r,
					g = g,
					b = b
				})
			end
		end
	end
end

function EditorAreaDespawn:set_element_data(data)
	if data.ctrlr == self._slots_presets_list.ctrlr then
		local slot_mask = managers.slot:get_mask(data.ctrlr:get_value())
		local slots = {}

		for match in string.gmatch(tostring(slot_mask), "%d+") do
			slots[tonumber(match)] = true
		end

		for i = 1, 63, 1 do
			self._slot_boxes[i]:set_value(slots[i], true)

			self._slots_map[i] = slots[i]
		end
	else
		EditorAreaDespawn.super.set_element_data(self, data)
	end
end

function EditorAreaDespawn:_slot_box_clicked(item)
	if item:Value() then
		self._slots_map[tonumber(item:Name())] = true
	else
		self._slots_map[tonumber(item:Name())] = nil
	end
	self._hed.slots = self._slots_map and table.map_keys(self._slots_map) or {}
end

function EditorAreaDespawn:set_slots_preset(item)
	local slot_mask = managers.slot:get_mask(item:SelectedItem())
	local slots = {}

	for match in string.gmatch(tostring(slot_mask), "%d+") do
		slots[tonumber(match)] = true
	end

	for i = 1, 63, 1 do
		self._slot_boxes[i]:set_value(slots[i] == true, true)

		self._slots_map[i] = slots[i]
	end
end

function EditorAreaDespawn:_build_panel()
	if not self._slots_map then
		self:build_slots_map()
	end

	self:_create_panel()

	self:BuildElementsManage("shape_elements", nil, {"ElementShape"}, nil, {nil_on_empty = true})
	self:ComboCtrl("test_type", {"unit_position","intersection"})

	local slot_masks = table.map_keys(managers.slot._masks)
	self._slots_presets_list = self:combobox("SlotsPresets", ClassClbk(self, "set_slots_preset"), slot_masks)

	local slots = self:group("Slots")
	local slot_boxes = {}

	for i = 0, 7 do
		local row_sizer = slots:holder("Row", {align_method = "grid"})

		for j = 0, 7 do
			local slot_number = i * 8 + j
			local checkbox = row_sizer:tickbox(tostring(slot_number), ClassClbk(self, "_slot_box_clicked"), self._slots_map[slot_number], {size_by_text = true, size = 12})
			checkbox:set_enabled(slot_number ~= 0)
			slot_boxes[slot_number] = checkbox
		end
	end

	self._slot_boxes = slot_boxes

	EditorAreaDespawn.super._build_panel(self)
end
