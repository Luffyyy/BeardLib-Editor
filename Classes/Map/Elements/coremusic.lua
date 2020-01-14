EditorMusic = EditorMusic or class(MissionScriptEditor)
function EditorMusic:create_element(...)
	EditorMusic.super.create_element(self, ...)
	self._element.class = "ElementMusic"
end

function EditorMusic:test_element()
	if self._element.values.music_event then
		managers.music:post_event(self._element.values.music_event)
	end
end

function EditorMusic:stop_test_element()
	managers.music:stop()
end

function EditorMusic:set_category(item)
	self._music:SetItems(managers.music:music_events(item:Value()))
	self._music:SetValue(1)
	self._element.music_event = self._music:SelectedItem()
end

function EditorMusic:_build_panel()
	self:_create_panel()
	self:StringCtrl("music_event")
	self:BooleanCtrl("use_instigator")
end