EditorInstigatorRule = EditorInstigatorRule or class(MissionScriptEditor)
EditorInstigatorRule.SAVE_UNIT_POSITION = false
EditorInstigatorRule.SAVE_UNIT_ROTATION = false
function EditorInstigatorRule:create_element(...)
	EditorInstigatorRule.super.create_element(self, ...)
	self._element.class = "ElementInstigatorRule"
	self._element.values.instigator = "none"
	self._element.values.rules = {}
	self._element.values.invert = false
end

function EditorInstigatorRule:set_element_data(menu, item)
	self.super.set_element_data(self, menu, item)
	if item.name == "instigator" then
		self:_update_rules_panel()
	end
end

function EditorInstigatorRule:_build_panel()
	self:_create_panel()
	self:ComboCtrl("instigator", managers.mission:area_instigator_categories(), {help = "Select an instigator type for the area"})
	self:BooleanCtrl("invert", {text = "Invert Rule", help = "Check this to have the rule inverted, i.e. exclude one unit from triggering the connected element"})
	self:_update_rules_panel()
end

function EditorInstigatorRule:_update_rules_panel()
	self:ClearItems("rules")
	local t = self._element.values
	local instigator = t.instigator
	t.rules[instigator] = t.rules[instigator] or {}
	local data = t.rules[instigator]
	if instigator == "player" then
		self:ListSelector("states", managers.player:player_states(), {label = "rules", data = data})
		self:ListSelector("carry_ids", table.map_keys(tweak_data.equipments.specials), {label = "rules", data = data})
		self:ListSelector("mission_equipment", table.map_keys(tweak_data.equipments.specials), {label = "rules", data = data})
	elseif instigator == "enemies" then
		self:ListSelector("enemy_names", BeardLibEditor.Utils:GetUnits({slot = 12}), {label = "rules", data = data})
		self:ListSelector("pickup", EditorPickup.get_options(), {label = "rules", data = data})
	elseif instigator == "civilians" then
		self:ListSelector("civilian_names", BeardLibEditor.Utils:GetUnits({slot = 21}), {label = "rules", data = data})
		self:ListSelector("pickup", EditorPickup.get_options(), {label = "rules", data = data})
	elseif instigator == "loot" then
		self:ListSelector("carry_ids", tweak_data.carry:get_carry_ids(), {label = "rules", data = data})
	elseif instigator == "vehicle" then
		self:ListSelector("vehicle_names", BeardLibEditor.Utils:GetUnits({slot = 39}), {label = "rules", data = data})
	end
end
