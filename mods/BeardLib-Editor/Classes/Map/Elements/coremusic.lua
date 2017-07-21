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

function EditorMusic:set_category(menu, item)
	self._music:SetItems(managers.music:music_events(item:Value()))
	self._music:SetValue(1)
	self._element.music_event = self._music:SelectedItem()
end

function EditorMusic:_build_panel()
	self:_create_panel()
	local paths = clone(managers.music:music_paths())
	if #paths <= 0 then
		self:Text("No music available in project!")
		return
	end

	self._element.values.music_event = self._element.values.music_event or managers.music:music_events(paths[1])[1]	
	self:ComboBox("Category", callback(self, self, "set_category"), managers.music:music_path(self._element.values.music_event), 1)
	self._music = self:ComboCtrl("music_event", managers.music:music_events(path_value))
	self:BooleanCtrl("use_instigator")
end