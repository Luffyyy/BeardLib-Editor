EditorMusic = EditorMusic or class(MissionScriptEditor)
function EditorMusic:create_element(...)
	EditorMusic.super.create_element(self, ...)
	self._element.class = "ElementMusic"
end

function EditorMusic:test_element()
	if self._element.values.music_event then
		managers.editor:set_wanted_mute(false)
		managers.editor:set_listener_enabled(true)
		managers.music:post_event(self._element.values.music_event)
	end
end

function EditorMusic:stop_test_element()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
	managers.music:stop()
end

function EditorMusic:destroy()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
end

function EditorMusic:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("use_instigator")
	local category = self._class_group:combobox("Category", ClassClbk(self, "_set_category"), {"music_heist", "track_ghost", "track_menu"}, 1)
	self:_set_category(category)
end

function EditorMusic:_set_category(item)
	self._class_group:ClearItems("events")
	local category = item:SelectedItem()
	if category == "music_heist" then
		self:ComboCtrl("music_event", table.list_add({"", "stop_all_music"}, table.map_values(tweak_data.music.default)), {label = "events", free_typing = true})
	elseif category == "track_ghost" then
		local t = {"", "stop_all_music", "suspense_1", "suspense_2", "suspense_3", "suspense_4", "suspense_5"}
		for _, event in ipairs(tweak_data.music.track_ghost_list) do 
			if event.track then
				table.insert(t, event.track)
			end
		end
		table.sort(t)
		self:ComboCtrl("music_event", t, {label = "events", free_typing = true})
	elseif category == "track_menu" then
		local t = {"", "stop_all_music"}
		for _, event in ipairs(tweak_data.music.track_menu_list) do 
			if event.track then
				table.insert(t, event.track)
			end
		end
		table.sort(t)
		self:ComboCtrl("music_event", t, {label = "events", free_typing = true})
	end
	self._holder:AlignItems(true)
end