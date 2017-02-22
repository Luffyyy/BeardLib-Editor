MissionElementUnit = MissionElementUnit or class()
function MissionElementUnit:init(unit)
	self._unit = unit

	local iconsize = 64
	local root = self._unit:orientation_object()
	if root == nil then
		return
	end

	self._gui = World:newgui()
	local pos = self._unit:position() - Vector3(iconsize / 2, iconsize / 2, 0)
	self._ws = self._gui:create_linked_workspace(64, 64, root, pos, Vector3(iconsize, 0, 0), Vector3(0, iconsize, 0))
	self._ws:set_billboard(self._ws.BILLBOARD_BOTH)
	local colors = {
		Color("4689f4"),
		Color("46f455"),
		Color("f7ff11"),
		Color("b711ff"),
	}
	self._color = colors[math.random(0, #colors)]
	self._icon = self._ws:panel():bitmap({
		texture = "textures/editor_icons_df",
		texture_rect = {368, 14, 128, 128},
		render_template = "OverlayVertexColorTextured",
		color = self._color,
		rotation = 360,
		w = iconsize / 2,
		h = iconsize / 2,
	})	
	self._text = self._ws:panel():text({
		render_template = "OverlayVertexColorTextured",
		font = "fonts/font_large_mf",
		font_size = iconsize / 8,
		w = iconsize / 2,
		h = iconsize / 2,
		rotation = 360,
		align = "center",
		color = self._color,
		y = self._icon:bottom(),
		text = "",
	})
end

function MissionElementUnit:update(t, dt)
	if self.element and self._text and alive(self._text) then
		self._text:set_text(tostring(self.element.editor_name) .. "\n" .. tostring(self.element.class))
	end
end

function MissionElementUnit:set_enabled(enabled)
	if enabled then
		self._ws:show()
	else
		self._ws:hide()
	end
end

function MissionElementUnit:set_color(color)
	self._icon:set_color(color)
	self._text:set_color(color)
end

function MissionElementUnit:set_selected(selected)
	self:set_color(selected and Color("3911ff") or (self.element.values.enabled and self._color or Color("ff4c4c")))
end

function MissionElementUnit:destroy()
	self._gui:destroy_workspace(self._ws)
end