EditorSpotter = EditorSpotter or class(MissionScriptEditor)
EditorSpotter.USES_POINT_ORIENTATION = true
EditorSpotter.ON_EXECUTED_ALTERNATIVES = {
	"on_outlined",
	"on_spotted"
}
function EditorSpotter:create_element()
    self.super.create_element(self)
    self._element.class = "ElementSpotter"
end

function EditorSpotter:update_selected(time, rel_time)
    local brush = Draw:brush(Color.white:with_alpha((1 - (math.sin(time * 100) + 1) / 2) * 0.15))
    local len = (math.sin(time * 100) + 1) / 2 * 3000

    brush:cone(self._unit:position(), self._unit:position() + self._unit:rotation():y() * len, len)
    brush:set_color(Color.white:with_alpha(0.15))
    brush:cone(self._unit:position(), self._unit:position() + self._unit:rotation():y() * 3000, 3000)
    Application:draw_cone(
        self._unit:position(),
        self._unit:position() + self._unit:rotation():y() * 3000,
        3000,
        0.75,
        0.75,
        0.75,
        0.1
    )
end