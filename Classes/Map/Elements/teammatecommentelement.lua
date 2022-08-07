EditorTeammateComment = EditorTeammateComment or class(MissionScriptEditor)
function EditorTeammateComment:create_element()
	self.super.create_element(self)
	self._element.class = "ElementTeammateComment"
	self._element.values.comment = "none"
	self._element.values.close_to_element = false
	self._element.values.use_instigator = false
	self._element.values.radius = 0
end

function EditorTeammateComment:set_element_data(item)
	if item:Name() == "use_instigator" then
		self._instigator_alert:SetVisible(item:Value())
	end
	EditorTeammateComment.super.set_element_data(self, item)
end
 
function EditorTeammateComment:_build_panel()
	self:_create_panel()
	self:ComboCtrl("comment", table.list_add({"none"}, managers.groupai:state().teammate_comment_names), {help = "Select a comment"})
	self:BooleanCtrl("close_to_element", {text = "Play close to element"})
	self:BooleanCtrl("use_instigator", {text = "Play on instigator"})
	self._instigator_alert = self:Alert("Do not use when the expected instigator is not a Player or an AI otherwise the game will crash!")
	self:NumberCtrl("radius", {min = 0, help = "(Optional) Sets a distance to use with the check (in cm)"})
	self._test_robber = self._class_group:combobox("TestRobber", nil, self:get_criminals(), 1, {help = "Can be used to test different robber voice (not saved/loaded)"})
	self._instigator_alert:SetVisible(self._element.values.use_instigator)
end

function EditorTeammateComment:get_criminals()
	local t = {}
	for _, data in ipairs(tweak_data.criminals.characters) do
		table.insert(t, managers.localization:text("menu_" .. data.name))
	end

	return t
end

function EditorTeammateComment:update_selected(t, dt)
	if self._element.values.radius ~= 0 then
		Application:draw_sphere(self._unit:position(), self._element.values.radius, 1, 1, 1)
	end
end

function EditorTeammateComment:test_element()
	if self._element.values.comment then
		managers.editor:set_wanted_mute(false)
		managers.editor:set_listener_enabled(true)

		if self._ss then
			self._ss:stop()
		else
			self._ss = SoundDevice:create_source(self._unit:unit_data().name_id)
		end

		self._ss:set_position(self._unit:position())
		self._ss:set_orientation(self._unit:rotation())
		self._ss:set_switch("int_ext", "third")

		local data = tweak_data.criminals.characters[self._test_robber:Value()]
		local voice = data.static_data.voice

		self._ss:set_switch("robber", tostring(voice))
		self._ss:post_event(self._element.values.comment, ClassClbk(self, "stop_test_element"), self._unit, "end_of_event")
	end
end

function EditorTeammateComment:stop_test_element()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)

	if self._ss then
		self._ss:stop()
	end
end
 
function EditorTeammateComment:destroy()
	self:stop_test_element()
	if self._ss then
		self._ss:stop()
		self._ss:delete()
		self._ss = nil
	end
end