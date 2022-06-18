if not Global.editor_mode then
	return
end

function ElementLookAtTrigger:debug_draw()
    local brush = Draw:brush(Color(0.2, self:enabled() and 0 or 1, self:enabled() and 1, 0))
    local pen = Draw:pen(Color(1, self:enabled() and 0 or 1, self:enabled() and 1, 0))
    if self._values.in_front then
        brush:half_sphere(self._values.position, self._values.distance, -self._values.rotation:y(), 3)
        pen:half_sphere(self._values.position, self._values.distance, -self._values.rotation:y())
    else
        brush:sphere(self._values.position, self._values.radius or self._values.distance or 1, 3)
        pen:sphere(self._values.position, self._values.radius or self._values.distance or 1)
    end 
end