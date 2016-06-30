EditorModifyPlayer = EditorModifyPlayer or class(MissionScriptEditor)
function EditorModifyPlayer:init(unit)
	EditorModifyPlayer.super.init(self, unit)
end

function EditorModifyPlayer:create_element()
    self.super.create_element(self)
    self._element.class = "ElementModifyPlayer"
    self._element.values.damage_fall_disabled = false
    self._element.values.invulnerable = nil   
end

function EditorModifyPlayer:_build_panel()
	self:_create_panel()
	self:_build_value_checkbox("damage_fall_disabled", "Set player damage fall disabled", nil, "Disabled damage fall")
	self:_build_value_checkbox("invulnerable", "Player cannot be hurt")
	self:_add_help_text("Modifies player properties. The changes are only applied to a player as instigator and cannot be used as a global state")
end
