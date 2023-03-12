EditorExplosionDamage = EditorExplosionDamage or class(MissionScriptEditor)
function EditorExplosionDamage:create_element()
	self.super.create_element(self)
	self._element.class = "ElementExplosionDamage"
	self._element.values.range = 100
	self._element.values.damage = 40 
end

function EditorExplosionDamage:update_selected(t, dt)
	if self._element.values.range ~= 0 then
		local brush = Draw:brush()
		brush:set_color(Color(0.15, 1, 1, 1))
		
		local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
		
		brush:sphere(self._element.values.position, self._element.values.range, 4)
		pen:sphere(self._element.values.position, self._element.values.range)
	end
end

function EditorExplosionDamage:_build_panel()
	self:_create_panel()
	self:NumberCtrl("range", {min = 0, help ="The range the explosion should reach"})
	self:NumberCtrl("damage", {
		min = 0,
		max = 100, 
		help ="The damage from the explosion"
	})
end
