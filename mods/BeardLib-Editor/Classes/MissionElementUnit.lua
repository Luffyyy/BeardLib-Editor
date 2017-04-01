MissionElementUnit = MissionElementUnit or class()
function MissionElementUnit:init(unit)
    self._unit = unit

    local iconsize = 48
    local root = self._unit:get_object(Idstring("c_sphere"))
    if root == nil then
        return
    end

    self._gui = World:newgui()
    local pos = root:position() - Vector3(iconsize / 2, iconsize / 2, 0)
    self._ws = self._gui:create_linked_workspace(iconsize / 2, iconsize / 2, root, pos, Vector3(iconsize, 0, 0), Vector3(0, iconsize, 0))
    self._ws:set_billboard(self._ws.BILLBOARD_BOTH)
    local colors = {
        Color("4689f4"),
        Color("46f455"),
        Color("f7ff11"),
        Color("b711ff"),
    }
    self._color = colors[math.random(0, #colors)]   
    local texture, rect = "textures/editor_icons_df", {368, 14, 128, 128}
    local size = iconsize / 4
    local font_size = iconsize / 8
    self._icon = self._ws:panel():bitmap({
        texture = texture,
        texture_rect = rect,
        render_template = "OverlayVertexColorTextured",
        color = self._color,
        rotation = 360,
        y = font_size,
        x = font_size,
        w = size,
        h = size,
    }) 
    self._text = self._ws:panel():text({
        render_template = "OverlayVertexColorTextured",
        font = "fonts/font_large_mf",
        font_size = font_size,
        w = iconsize / 2,
        h = font_size,
        rotation = 360,
        align = "center",
        color = self._color,
        text = "",
    })

    self._text:set_bottom(self._icon:top() - font_size)
end

function MissionElementUnit:update(t, dt)
	if self.element and self._text and alive(self._text) then
		self._text:set_text(tostring(self.element.editor_name) .. "\n" .. tostring(self.element.class):gsub("Element", ""))
	end
end

function MissionElementUnit:set_enabled(enabled)
	if enabled then
		self._ws:show()
	else
		self._ws:hide()
	end
end

function MissionElementUnit:select()
    self._icon:set_texture_rect(230, 14, 128, 128)
end

function MissionElementUnit:unselect()
    self._icon:set_texture_rect(368, 14, 128, 128)
end

function MissionElementUnit:set_color(color)
	self._icon:set_color(color)
	self._text:set_color(color)
end

function MissionElementUnit:destroy()
	self._gui:destroy_workspace(self._ws)
end