EditorTeleportPlayer = EditorTeleportPlayer or class(MissionScriptEditor)
function EditorTeleportPlayer:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTeleportPlayer"
	self._element.values.state = nil
	self._element.values.refill = false
	self._element.values.keep_carry = false
	self._element.values.equip_selection = "none"
	self._element.values.fade_in = 0
	self._element.values.sustain = 0
	self._element.values.fade_out = 0
end

function EditorTeleportPlayer:_build_panel()
	self:_create_panel()
	self:StateCtrl("state", table.list_add({""}, managers.player:player_states()), {help = "What state to put the player in after teleporting, set to nothing to not change states"})
	self:ComboCtrl("equip_selection", {
		"none",
		"primary",
		"secondary"
	}, {help = "Equips the given selection or keeps the current if none"})
	self:NumberCtrl("fade_in", {min = 0, floats = 2})
	self:NumberCtrl("sustain", {min = 0, floats = 2})
	self:NumberCtrl("fade_out", {min = 0, floats = 2})
	self:BooleanCtrl("refill", {help = "Refills the player's ammo and health after teleport"})
	self:BooleanCtrl("keep_carry", {help = "Should the player keep what they are carrying while teleporting"})
end

function EditorTeleportPlayer:StateCtrl(value_name, items, opt)
	opt = self:BasicCtrlInit(value_name, opt)
	local value = self:ItemData(opt)[value_name]
	return (opt.group or self._holder):combobox(value_name, ClassClbk(self, "set_state_data"), items, table.get_key(items, value), opt)
end

function EditorTeleportPlayer:set_state_data(item)
	if not item then
		return
	end

	if item:SelectedItem() == "" then
		local data = self:ItemData(item)
		local old_script = self._element.script
		self._element.values.state = nil
		data[item.name] = nil
		self:update_element(false, old_script)
	else
		self:set_element_data(item)
	end
end