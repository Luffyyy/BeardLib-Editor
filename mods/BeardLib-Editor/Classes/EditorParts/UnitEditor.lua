UnitEditor = UnitEditor or class()

function UnitEditor:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "selected_unit",
        text = "Selected Unit",
        help = "",
    })

    self._modded_units = {}
    self._selected_units = {}
    self._disabled_units = {}

    self:InitItems()
end

function UnitEditor:InitItems()
    self._menu:Button({
        name = "deselect_unit",
        text = "Deselect unit",
        help = "",
        callback = callback(self, self, "deselect_unit"),
    })
    self._menu:Button({
        name = "add_to_prefabs",
        text = "Add to prefabs",
        value = "",
        help = "",
        callback = callback(self, self, "add_unit_to_prefabs"),
    })
    self._menu:TextBox({
        name = "unit_name",
        text = "Name: ",
        value = "",
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:TextBox({
        name = "unit_id",
        text = "ID: ",
        value = "",
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:ComboBox({
        name = "unit_mesh_variation",
        text = "Mesh variation: ",
        value = 1,
        items = {},
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:ComboBox({
        name = "unit_continent",
        text = "Continent: ",
        value = 1,
        items = {},
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:TextBox({
        name = "unit_path",
        text = "Unit path: ",
        value = "",
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "positionx",
        text = "Position x: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "positiony",
        text = "Position Y: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "positionz",
        text = "Position z: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "rotationyaw",
        text = "Rotation yaw: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "rotationpitch",
        text = "Rotation pitch: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Slider({
        name = "rotationroll",
        text = "Rotation roll: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })
    self._menu:Button({
        name = "unit_delete_btn",
        text = "Delete unit",
        help = "",
        callback = callback(self, self, "delete_unit"),
    })
    self._menu:Divider({
        text = "Modifiers",
        size = 30,
        color = Color.green,
    })
end

function UnitEditor:deselect_unit(menu, item)
    self:set_unit(nil)
end

function UnitEditor:set_unit_data(menu, item)
    if alive(self._selected_unit) then
        self:set_position(Vector3(menu:GetItem("positionx").value, menu:GetItem("positiony").value, menu:GetItem("positionz").value), Rotation(menu:GetItem("rotationyaw").value, menu:GetItem("rotationpitch").value, menu:GetItem("rotationroll").value))
        if self._selected_unit:unit_data() and self._selected_unit:unit_data().unit_id then
            self._selected_unit:unit_data().name_id = self._menu:GetItem("unit_name").value
            self._selected_unit:unit_data().position = self._selected_unit:position()
            self._selected_unit:unit_data().rotation = self._selected_unit:rotation()
            local mesh_variations = managers.sequence:get_editable_state_sequence_list(self._selected_unit:name()) or {}
            self._selected_unit:unit_data().mesh_variation = mesh_variations[self._menu:GetItem("unit_mesh_variation").value]
            local mesh_variation = self._selected_unit:unit_data().mesh_variation
            if mesh_variation and mesh_variation ~= "" then
                managers.sequence:run_sequence_simple2(mesh_variation, "change_state", self._selected_unit)
            end
            local old_continent = self._selected_unit:unit_data().continent
            self._selected_unit:unit_data().continent = self._menu:GetItem("unit_continent"):SelectedItem()
            local new_continent = self._selected_unit:unit_data().continent
            self._selected_unit:unit_data().name = self._menu:GetItem("unit_path").value -- Later will add button to unit browser.
            managers.worlddefinition:set_unit(self._selected_unit:unit_data().unit_id, self._selected_unit:unit_data(), old_continent, new_continent)
        end
    end
end

function UnitEditor:add_unit_to_prefabs(menu, item)
    if self._selected_unit and not self._parent._menu:GetItem("prefabs"):GetItem(self._selected_unit:unit_data().name_id) then
        self._parent._menu:GetItem("prefabs"):Button({
            name = self._selected_unit:unit_data().name_id,
            text = self._selected_unit:unit_data().name_id,
            callback = callback(self._parent, self._parent, "SpawnUnit", self._selected_unit:unit_data().name)
        })
    end
end


function UnitEditor:select_unit(select_more)
	local cam = self._parent._camera_object
	local ray
	if self._parent._menu:GetItem("units_visibility").value then
        ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000, "ray_type", "body editor walk", "slot_mask", self._parent._editor_all)
    else
        ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000)
    end
	if ray then
		BeardLibEditor:log("ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
        if not select_more then
    		local current_unit
    		if self._selected_unit == ray.unit then
    			current_unit = true
    		end
    		if alive(self._selected_unit) then
    			self:set_unit(nil)
    		end
    		if not current_unit then
    			self:set_unit(ray.unit)
    			self._selected_body = ray.body
    			self._modded_units[ray.unit:editor_id()] = self._modded_units[ray.unit:editor_id()] or {}
    			self._modded_units[ray.unit:editor_id()]._default_position = self._modded_units[ray.unit:editor_id()]._default_position or ray.unit:position()
    			self._modded_units[ray.unit:editor_id()]._default_rotation = self._modded_units[ray.unit:editor_id()]._default_rotation or ray.unit:rotation()
    			self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
    			self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
    		end
    		if self._modded_units[ray.unit:editor_id()] and self._modded_units[ray.unit:editor_id()]._modded_offset_position then
    			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
    		end
    		if self._modded_units[ray.unit:editor_id()] and self._modded_units[ray.unit:editor_id()]._modded_offset_rotation then
    			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
    		end
        elseif ray.unit ~= self._selected_unit then
            table.insert(self._selected_units, ray.unit)
        end
	else
		BeardLibEditor:log("no ray")
	end
end

function UnitEditor:set_unit(unit)
    self._selected_unit = unit
    self._selected_units = {}
    self._menu:GetItem("unit_name"):SetValue(alive(unit) and unit:unit_data().name_id or "")
    self._menu:GetItem("unit_path"):SetValue(alive(unit) and unit:unit_data().name or "")
    self._menu:GetItem("unit_id"):SetValue(alive(unit) and unit:unit_data().unit_id or "")
    local mesh_variations = managers.sequence:get_editable_state_sequence_list(alive(unit) and unit:name() or "") or {}
    self._menu:GetItem("unit_mesh_variation"):SetItems(mesh_variations)
    self._menu:GetItem("unit_mesh_variation"):SetValue(alive(unit) and unit:unit_data().mesh_variation and table.get_key(mesh_variations, unit:unit_data().mesh_variation) or nil)
    local continent_item = self._menu:GetItem("unit_continent")
    continent_item:SetValue(alive(unit) and unit:unit_data().continent and table.get_key(continent_item.items, unit:unit_data().continent) or nil)
    self._menu:GetItem("positionx"):SetValue(alive(unit) and unit:position().x or 0)
    self._menu:GetItem("positiony"):SetValue(alive(unit) and unit:position().y or 0)
    self._menu:GetItem("positionz"):SetValue(alive(unit) and unit:position().z or 0)
    self._menu:GetItem("rotationyaw"):SetValue(alive(unit) and unit:rotation():yaw() or 0)
    self._menu:GetItem("rotationpitch"):SetValue(alive(unit) and unit:rotation():pitch() or 0)
    self._menu:GetItem("rotationroll"):SetValue(alive(unit) and unit:rotation():roll() or 0)

    self._menu:ClearItems("elements")

    for _, element in pairs(managers.mission:get_modifiers_of_unit(unit)) do
        self._menu:Button({
            name = element.editor_name,
            text = element.editor_name .. " [" .. (element.id or "") .."]",
            label = "elements",
            callback = callback(self._parent, self._parent, "_select_element", element)
        })
    end
end

function UnitEditor:delete_unit(menu, item)
	if alive(self._selected_unit) then
		managers.worlddefinition:delete_unit(self._selected_unit)
		World:delete_unit(self._selected_unit)
	end
    for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            managers.worlddefinition:delete_unit(unit)
            World:delete_unit(unit)
        end
    end
    self:set_unit()
end

function UnitEditor:set_position(position, rotation)
	local unit = self._selected_unit
	unit:set_position(position)
	unit:set_rotation(rotation)
	local objects = unit:get_objects_by_type(Idstring("model"))
	for _, object in pairs(objects) do
		object:set_visibility(not object:visibility())
		object:set_visibility(not object:visibility())
	end
	local num = unit:num_bodies()
	for i = 0, num - 1 do
		local unit_body = unit:body(i)
		unit_body:set_enabled(not unit_body:enabled())
		unit_body:set_enabled(not unit_body:enabled())
	end
end

function UnitEditor:update(t, dt)
    if alive(self._selected_unit) and managers.viewport:get_current_camera() then
        local brush = Draw:brush(Color(0, 0.5, 0.85))
        brush:set_render_template(Idstring("OverlayVertexColorTextured"))

		Application:draw(self._selected_unit, 0, 0.5, 0.85)
        brush:sphere(self._selected_unit:position(), 10)
    	local cam_up = managers.viewport:get_current_camera():rotation():z()
    	local cam_right = managers.viewport:get_current_camera():rotation():x()
    	brush:set_font(Idstring("fonts/font_medium"), 32)
    	brush:center_text(self._selected_unit:position() + Vector3(-10, -10, 200), self._selected_unit:unit_data().name_id .. "[ " .. self._selected_unit:editor_id() .. " ]", cam_right, -cam_up)
	end
    for _, unit in pairs(self._selected_units) do
        Application:draw(unit, 0, 0.5, 0.85)
        local brush = Draw:brush(Color(0, 0.5, 0.85))
        brush:sphere(unit:position(), 5)
    end
end

function UnitEditor:set_unit_enabled(enabled)
	if self._selected_unit then
		self._selected_unit:set_enabled(enabled)
	end
end
