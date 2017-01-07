EditorModifyPlayer = EditorModifyPlayer or class(MissionScriptEditor)
function EditorModifyPlayer:create_element()
    self.super.create_element(self)
    self._element.class = "ElementModifyPlayer"
    self._element.values.damage_fall_disabled = false
    self._element.values.invulnerable = nil   
end

function EditorModifyPlayer:_build_panel()
	self:_create_panel()
    self:BooleanCtrl("damage_fall_disabled", {help = "Set player damage fall disabled", text = "Disabled damage fall"})
    self:BooleanCtrl("invulnerable", {help = "Player cannot be hurt"})
	self:Text("Modifies player properties. The changes are only applied to a player as instigator and cannot be used as a global state")
end
