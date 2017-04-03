dofile(BeardLibEditor.ElementsDir .. "feedbackelement.lua")
EditorExplosion = EditorExplosion or class(EditorFeedback)
function EditorExplosion:create_element()
	EditorExplosion.super.create_element(self)
	self._element.class = "ElementExplosion"
	self._element.values.damage = 40
	self._element.values.player_damage = 10
	self._element.values.explosion_effect = "effects/particles/explosions/explosion_grenade_launcher"
	self._element.values.no_raycast_check_characters = nil
	self._element.values.sound_event = "trip_mine_explode"
end
function EditorExplosion:_build_panel()
	self:_create_panel()
	self:NumberCtrl("damage", {floats= 0, min = 0, help = "The damage done to beings and props from the explosion"})
	self:NumberCtrl("player_damage", {floats= 0, min = 0, help = "The player damage from the explosion"})
	self:ComboCtrl("explosion_effect", table.list_add({"none"}, self:_effect_options()), {help = "Select and explosion effect"})
	self:ComboCtrl("sound_event", {"no_sound", "trip_mine_explode"})
	self:BooleanCtrl("no_raycast_check_characters", {"no_sound", "trip_mine_explode"})
	
	EditorExplosion.super._build_panel(self)
end