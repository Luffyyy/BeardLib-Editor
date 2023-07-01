EditorVehicleBoarding = EditorVehicleBoarding or class(MissionScriptEditor)
EditorVehicleBoarding.SAVE_UNIT_POSITION = false
EditorVehicleBoarding.SAVE_UNIT_ROTATION = false

function EditorVehicleBoarding:create_element()
    EditorVehicleBoarding.super.create_element(self)

	self._element.class = "ElementVehicleBoarding"
    self._element.values.vehicle = nil
	self._element.values.operation = "embark"
	self._element.values.teleport_points = {}

	self._seat_list = {}
end

function EditorVehicleBoarding:_build_panel(disable_params)
	self:_create_panel()
    
    self:BuildUnitsManage("vehicle", nil, ClassClbk(self, "set_vehicle"), {
        check_unit = ClassClbk(self, "check_unit"),
        single_select = true,
        not_table = true
    })
	self:BuildElementsManage("teleport_points", nil, {"ElementTeleportPlayer"})

	self:ComboCtrl("operation", {
        "embark", 
        "disembark"
    }, {help = "Specify wether heisters will enter or exit the vehicle"})

	self._seat_group = self._class_group:group("Seat Order")
	self:_populate_seats_list()
end

function EditorVehicleBoarding:link_managed(unit)
	if alive(unit) then
		if self:check_unit(unit) and unit:unit_data() then
			self:AddOrRemoveManaged("vehicle", {unit = unit}, {not_table = true}, ClassClbk(self, "set_vehicle"))
		elseif unit:mission_element() and unit:mission_element().element.class == "ElementTeleportPlayer" then
			self:AddOrRemoveManaged("teleport_points", {element = unit:mission_element().element})
		end
	end
end

function EditorVehicleBoarding:set_vehicle()
    local id = self._element.values.vehicle
    local vehicle_unit = managers.worlddefinition:get_unit(id)
    if self._vehicle_unit == vehicle_unit then
		return
    end

    self._vehicle_unit = vehicle_unit
	self._element.values.seats_order = nil

	self:_populate_seats_list()
end

function EditorVehicleBoarding:draw_links()
	EditorVehicleBoarding.super.draw_links(self)

	if self._element.values.vehicle then
		local unit = self:vehicle_unit()
		local selected_unit = self:selected_unit()
		local draw = unit and (not selected_unit or unit == selected_unit or self._unit == selected_unit)

		if draw then
			self:draw_link({
				g = 0.75,
				b = 0,
				r = 0,
				from_unit = self._unit,
				to_unit = unit
			})
		end
	end

	if self._element.values.teleport_points then
		for _, id in ipairs(self._element.values.teleport_points) do
			local unit = self:GetPart('mission'):get_element_unit(id)

			if alive(unit) then
				local r, g, b = unit:mission_element():get_link_color()

				self:draw_link({
					from_unit = self._unit,
					to_unit = unit,
					r = r,
					g = g,
					b = b
				})
			end
		end
	end
end

function EditorVehicleBoarding:_populate_seats_list()
	local vehicle = self:vehicle_unit()

	self._seat_group:ClearItems()
	self._seat_group:set_enabled(vehicle ~= nil)

	if not vehicle then
		return
	end

	self._seat_list = {}

	if not self._element.values.seats_order then
		self._element.values.seats_order = {}

		for seat_name, _ in pairs(vehicle:vehicle_driving()._seats) do
			table.insert(self._element.values.seats_order, seat_name)
		end
	end

	for i, seat_name in ipairs(self._element.values.seats_order) do
		table.insert(self._seat_list, seat_name)
	end

	self:_build_group()
	self._holder:AlignItems(true)
end

function EditorVehicleBoarding:_build_group()
	local tx = "textures/editor_icons_df"
	for i, seat_name in ipairs(self._seat_list or {}) do
		local lbl = self._seat_group:lbl(seat_name)

		lbl:tb_imgbtn("MoveUp", 
			ClassClbk(self, "set_seat_priority", i,  i - 1), 
			tx, BLE.Utils.EditorIcons["arrow_up"], {
			enabled = i > 1
		})
		lbl:tb_imgbtn("MoveDown", 
			ClassClbk(self, "set_seat_priority", i, i + 1), 
			tx, BLE.Utils.EditorIcons["arrow_down"], {
			enabled = i < #self._seat_list
		})
	end
end

function EditorVehicleBoarding:set_seat_priority( my_index, desired_index)
    local popped = table.remove(self._element.values.seats_order, my_index)
	table.insert(self._element.values.seats_order, desired_index, popped)

	self:_populate_seats_list()
end

function EditorVehicleBoarding:vehicle_unit()
	if not self._vehicle_unit or self._vehicle_unit:unit_data().unit_id ~= self._element.values.vehicle then
		self._vehicle_unit = managers.worlddefinition:get_unit(self._element.values.vehicle)
	end

	return self._vehicle_unit
end

function EditorVehicleBoarding:check_unit(unit)
	return unit:vehicle_driving()
end