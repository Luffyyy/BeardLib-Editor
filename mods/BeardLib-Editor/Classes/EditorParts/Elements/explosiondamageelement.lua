EditorExplosionDamage = EditorExplosionDamage or class(MissionScriptEditor)
function EditorExplosionDamage:init(unit)
	EditorExplosionDamage.super.init(self, unit)
end
function EditorExplosionDamage:create_element()
	self.super.create_element(self)
	self._element.class = "ElementExplosionDamage"
	self._element.values.range = 100
	self._element.values.damage = 40 
end
function EditorExplosionDamage:_build_panel()
	self:_create_panel()
	self:_build_value_number("range", {min = 0}, "The range the explosion should reach")
	self:_build_value_number("damage", {
		min = 0,
		max = 100
	}, "The damage from the explosion")
end
