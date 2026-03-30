EditorPlaySound = EditorPlaySound or class(MissionScriptEditor)
EditorPlaySound.ELEMENT_FILTER = {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"}
function EditorPlaySound:create_element()
	EditorPlaySound.super.create_element(self)
	self._element.class = "ElementPlaySound"
	self._element.values.elements = {}
	self._element.values.append_prefix = false
	self._element.values.use_instigator = false
	self._element.values.interrupt = true
	self._element.values.use_play_func = false
end

function EditorPlaySound:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)

	self._manual_sound_id_strctrl = self:StringCtrl("sound_event", {text = "Sound ID"})
	self:BooleanCtrl("append_prefix", {help = "Append unit prefix"})
	self:BooleanCtrl("use_instigator", {help = "Play on instigator"})
	self:BooleanCtrl("interrupt", {help = "Interrupt existing sound"})
	self:BooleanCtrl("use_play_func", {help = "Use 'play' function in unit sound extension instead of 'say'"})
	
	local banks = {}
	for bank, _ in pairs(Global.WwiseBanks) do
		table.insert(banks, bank)
	end
	table.sort(banks)

	self:combobox("Soundbank", callback(self, self, "clbk_soundbank_selected"), banks, nil, {
		help = "Vanilla Wwise soundbank to filter available sound IDs to those contained inside it; leave blank to enter the ID manually. Selecting a soundbank will load it automatically",
		searchbox = true
	})
	self._bank_sound_id_combobox = self:combobox("Bank Sound ID", callback(self, self, "clbk_bank_sound_id_selected"), nil, nil, {
		help = "The event to use from the selected bank",
		not_close = true, 
        searchbox = true, 
	})
	self._bank_sound_id_combobox:SetEnabled(false)
end

function EditorPlaySound:test_element()
	if self._element.values.sound_event then
		managers.editor:set_wanted_mute(false)
		managers.editor:set_listener_enabled(true)

		if self._ss then
			self._ss:stop()
		else
			self._ss = SoundDevice:create_source(self._unit:unit_data().name_id)
		end

		self._ss:set_position(self._unit:position())
		self._ss:set_orientation(self._unit:rotation())
		self._ss:post_event(self._element.values.sound_event, ClassClbk(self, "stop_test_element"), self._unit, "end_of_event")
	end
end

function EditorPlaySound:stop_test_element()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)

	if self._ss then
		self._ss:stop()
	end
end

local assets = managers.editor.parts.assets
function EditorPlaySound:clbk_soundbank_selected(item)
	self._manual_sound_id_strctrl:SetEnabled(false)
	self._soundbank = item:SelectedItem()

	if not assets:is_asset_loaded("bnk", "soundbanks/" .. self._soundbank) then
		assets:quick_load_from_db("bnk", "soundbanks/" .. self._soundbank, nil, nil, {load = true})
	end

	self._bank_sound_id_combobox:SetEnabled(true)
	self._bank_sound_id_combobox:SetValue("")
	self._bank_sound_id_combobox:SetItems(Global.WwiseBanks[self._soundbank]["events"] or {"No events in this bank!"})
end

function EditorPlaySound:clbk_bank_sound_id_selected(item)
	self._element.values.sound_event = item:SelectedItem()
	self:test_element()
end

function EditorPlaySound:destroy()
	self:stop_test_element()
	if self._ss then
		self._ss:stop()
		self._ss:delete()
		self._ss = nil
	end
end
