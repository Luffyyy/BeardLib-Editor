EditorExplosionDamage = EditorExplosionDamage or class(MissionScriptEditor)
function EditorExplosionDamage:create_element()
	self.super.create_element(self)
	self._element.class = "ElementExplosionDamage"
	self._element.values.range = 100
	self._element.values.damage = 40 
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
