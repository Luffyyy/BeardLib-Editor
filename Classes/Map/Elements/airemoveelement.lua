EditorAIRemove = EditorAIRemove or class(MissionScriptEditor)
EditorAIRemove.ELEMENT_FILTER = {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"}
EditorAIRemove.LINK_ELEMENTS = {"elements"}
function EditorAIRemove:create_element()
	self.super.create_element(self)
	self._element.class = "ElementAIRemove"
	self._element.values.elements = {}
	self._element.values.use_instigator = false
	self._element.values.true_death = false
	self._element.values.force_ragdoll = false
	self._element.values.backup_so = nil
end

function EditorAIRemove:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
	self:BooleanCtrl("use_instigator", {text = "Remove Instigator"})
	self:BooleanCtrl("true_death")
	self:BooleanCtrl("force_ragdoll")
	self:BuildElementsManage("backup_so", nil, {"ElementSpecialObjective"}, nil, {
		text="Backup Special Objective", 
		help="If the enemy is invincible or an escort, they will execute this Special Objective instead of being removed", 
		single_select = true, 
		not_table = true
	})
end

function EditorAIRemove:update_selected(t, dt)
    if not alive(self._unit) then
        return
    end

    if self._element.values.elements then
        for _, id in ipairs(self._element.values.elements) do
            local unit = self:GetPart('mission'):get_element_unit(id)
			local r, g, b = unit:mission_element():get_link_color()
            if unit then
                self:draw_link(
                    {
                        g = g,
                        b = b,
                        r = r,
                        from_unit = self._unit,
                        to_unit = unit
                    }
                )
			else
				table.delete(self._element.values.elements, id)
            end
        end
    end
	if self._element.values.backup_so then
		local unit = self:GetPart('mission'):get_element_unit(self._element.values.backup_so)
		if unit then
			self:draw_link({
				g = 0,
				b = 0.75,
				r = 0,
				from_unit = self._unit,
				to_unit = unit
			})
		else
			self._element.values.backup_so = nil
		end
	end
end

function EditorAIRemove:link_managed(unit)
	if alive(unit) and unit:mission_element() and unit:mission_element().element.class == "ElementSpecialObjective" then
		self:AddOrRemoveManaged("backup_so", {element = unit:mission_element().element}, {not_table = true})
		return
	end
	EditorAIRemove.super.link_managed(self, unit)
end
