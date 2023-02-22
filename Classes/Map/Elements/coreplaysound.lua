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
	self:StringCtrl("sound_event", {text = "Sound ID"})
	self:BooleanCtrl("append_prefix", {help = "Append unit prefix"})
	self:BooleanCtrl("use_instigator", {help = "Play on instigator"})
	self:BooleanCtrl("interrupt", {help = "Interrupt existing sound"})
	self:BooleanCtrl("use_play_func", {help = "Use 'play' function in unit sound extension instead of 'say'"})
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

function EditorPlaySound:destroy()
	self:stop_test_element()
	if self._ss then
		self._ss:stop()
		self._ss:delete()
		self._ss = nil
	end
end
