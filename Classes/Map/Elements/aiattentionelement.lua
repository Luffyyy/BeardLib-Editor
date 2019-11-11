EditorAIAttention = EditorAIAttention or class(MissionScriptEditor)
function EditorAIAttention:create_element()  
	self.super.create_element(self)
	self._nav_link_filter = {}
	self._nav_link_filter_check_boxes = {}
	self._element.class = "ElementAIAttention"
	self._element.values.preset = "none"
	self._element.values.local_pos = nil
	self._element.values.local_rot = nil
	self._element.values.use_instigator = nil
	self._element.values.instigator_ids = {}
	self._element.values.parent_u_id = nil
	self._element.values.parent_obj_name = nil
	self._element.values.att_obj_u_id = nil
	self._element.values.operation = "set"
	self._element.values.override = "none"
	self._parent_unit = nil
	self._parent_obj = nil
	self._att_obj_unit = nil
end

function EditorAIAttention:on_script_activated()
	if self._element.values.parent_u_id then
		self._parent_unit = managers.worlddefinition:get_unit_on_load(self._element.values.parent_u_id, ClassClbk(self, "load_parent_unit"))

		if self._parent_unit then
			self._parent_obj = self._parent_unit:get_object(Idstring(self._element.values.parent_obj_name))
		end
	end

	if self._element.values.att_obj_u_id then
		self._att_obj_unit = managers.worlddefinition:get_unit_on_load(self._element.values.att_obj_u_id, ClassClbk(self, "load_att_obj_unit"))
	end
end

function EditorAIAttention:load_parent_unit(unit)
	self._parent_unit = unit

	if self._parent_unit then
		self._parent_obj = self._parent_unit:get_object(Idstring(self._element.values.parent_obj_name))
	end
end

function EditorAIAttention:load_att_obj_unit(unit)
	self._att_obj_unit = unit
end

function EditorAIAttention:draw_links()
	EditorAIAttention.super.draw_links(self)

	local selected_unit = self:selected_unit()
	if self._element.values.instigator_ids then
		for _, id in ipairs(self._element.values.instigator_ids) do
			local unit = self:GetPart('mission'):get_element_unit(id)
			local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit

			if draw then
				self:draw_link({
					g = 0,
					b = 0.75,
					r = 0,
					from_unit = unit,
					to_unit = self._unit
				})
			end
		end
	end

	if selected_unit and self._parent_unit ~= selected_unit and self._parent_unit ~= selected_unit and self._unit ~= selected_unit then
		return
	end

	if self._parent_unit then
		self:draw_link({
			g = 0.75,
			b = 0,
			r = 0,
			from_unit = self._unit,
			to_unit = self._parent_unit
		})
	end

	if self._att_obj_unit then
		self:draw_link({
			g = 0,
			b = 0.75,
			r = 0,
			from_unit = self._unit,
			to_unit = self._att_obj_unit
		})
	end
end

function EditorAIAttention:update_selected(t, dt)
	self:_chk_units_alive()
	
	local selected_unit = self:selected_unit()
	if selected_unit and self._parent_unit ~= selected_unit and self._att_obj_unit ~= selected_unit and self._unit ~= selected_unit then
		return
	end

	if self._parent_unit then
		self:draw_link({
			g = 0.75,
			b = 0,
			r = 0,
			from_unit = self._unit,
			to_unit = self._parent_unit
		})
	end

	if self._att_obj_unit then
		self:draw_link({
			g = 0,
			b = 0,
			r = 0.75,
			from_unit = self._unit,
			to_unit = self._att_obj_unit
		})
	end

	if self._element.values.instigator_ids then
		for _, id in ipairs(self._element.values.instigator_ids) do
			local unit = self:GetPart('mission'):get_element_unit(id)

			self:draw_link({
				g = 0,
				b = 0.75,
				r = 0,
				from_unit = unit,
				to_unit = self._unit
			})
		end
	end
end

function EditorAIAttention:_chk_units_alive()
    if self._parent_unit and not alive(self._parent_unit) then
        self._parent_unit = nil
        self._parent_obj = nil
        self._element.values.parent_obj_name = nil
        self._element.values.parent_u_id = nil

        self:_chk_set_link_values()
    end

    if self._att_obj_unit and not alive(self._att_obj_unit) then
        self._att_obj_unit = nil
        self._element.values.att_obj_u_id = nil

        self:_chk_set_link_values()
    end
end

function EditorAIAttention:_chk_set_link_values()
    if self._att_obj_unit and self._parent_unit then
        local att_obj_pos = self._att_obj_unit:position()
        local att_obj_rot = self._att_obj_unit:rotation()
        local parent_pos = self._parent_obj:position()
        local parent_rot = self._parent_obj:rotation()
        local parent_inv_rot = parent_rot:inverse()
        local world_vec = att_obj_pos - parent_pos
        self._element.values.local_pos = world_vec:rotate_with(parent_inv_rot)
    else
        self._element.values.local_pos = nil
        self._element.values.local_rot = nil
    end
end

function EditorAIAttention:nil_if_empty(value_name)
	if self._element.values[value_name] and #self._element.values[value_name] == 0 then
		self._element.values[value_name] = nil
	end
end

function EditorAIAttention:_build_panel()
	self:_create_panel()

	self:BuildUnitsManage("att_obj_u_id", nil, nil, {
		text = "Attention Object",
		single_select = true,
		not_table = true,
		check_unit = function(unit)
			return unit:in_slot(38)
		end
	})

	self:BuildElementsManage("instigator_ids", nil, {
		"ElementSpawnEnemyDummy",
		"ElementSpawnCivilian",
		"ElementSpawnEnemyGroup",
		"ElementSpawnCivilianGroup"
	}, ClassClbk(self, "nil_if_empty"))

	self:BooleanCtrl("use_instigator")
	self:ComboCtrl("preset", table.list_add({"none"}, tweak_data.attention.indexes), {help = "Select the attention preset."})
	self:ComboCtrl("operation", {"set","add","override"}, {help = "Select an operation."})
	self:ComboCtrl("override", table.list_add({"none"}, tweak_data.attention.indexes), {help = "Select the attention preset to be overriden. (valid only with override operation)"})
end