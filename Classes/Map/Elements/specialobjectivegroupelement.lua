EditorSpecialObjectiveGroup = EditorSpecialObjectiveGroup or class(MissionScriptEditor)
function EditorSpecialObjectiveGroup:create_element()
    self.super.create_element(self)
	self._element.class = "ElementSpecialObjectiveGroup"
	self._element.values.base_chance = 1
	self._element.values.use_instigator = false
	self._element.values.followup_elements = nil
	self._element.values.spawn_instigator_ids = nil
	self._element.values.mode = "randomizer"
end

function EditorSpecialObjectiveGroup:update_selected(t, dt)
    if self._element.values.spawn_instigator_ids then
        local selected_unit = self:selected_unit()
        for _, id in ipairs(self._element.values.spawn_instigator_ids) do
            local unit = self:GetPart('mission'):get_element_unit(id)
            local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit

            if draw then
                self:draw_link(
                    {
                        g = 0,
                        b = 0.75,
                        r = 0,
                        from_unit = unit,
                        to_unit = self._unit
                    }
                )
            end
        end
    end
    if self._element.values.followup_elements then
		for _, element_id in ipairs(self._element.values.followup_elements) do
			local unit = self:GetPart("mission"):get_element_unit(element_id)
			if alive(unit) then
				self:draw_link({
					from_unit = self._unit,
					to_unit = unit,
					r = 0,
					g = 0.75,
					b = 0
				})
			end
		end
	end
end

function EditorSpecialObjectiveGroup:_build_panel()
	self:_create_panel()
	self:ComboCtrl("mode", {"randomizer","forced_spawn","recurring_cloaker_spawn","recurring_spawn_1"}, {
		help = "Randomizer: assigns SOs to instigators. Forced Spawn: Will spawn a new group of choice. Recurring: Spawns new group. After failure, a new group will be spawned with a delay."
	})
	self:BooleanCtrl("use_instigator")
	self:NumberCtrl("base_chance", {min = 0, max = 1, floats = 2, help = "Used to specify chance to happen (1==absolutely!)"})
	self:BuildElementsManage("spawn_instigator_ids", nil, {"ElementSpawnEnemyGroup"})
	self:BuildElementsManage("followup_elements", nil, {"ElementSpecialObjective"})
end

function EditorSpecialObjectiveGroup:link_managed(unit)
	if alive(unit) and unit:mission_element() then
		local element = unit:mission_element().element
		if element.class == "ElementSpawnEnemyGroup" then
			self:AddOrRemoveManaged("spawn_instigator_ids", {element = element})
        elseif element.class == "ElementSpecialObjective" then
			self:AddOrRemoveManaged("followup_elements", {element = element})
		end
	end
end
