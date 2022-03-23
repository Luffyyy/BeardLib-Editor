EditorForceEndAssaultState = EditorForceEndAssaultState or class(MissionScriptEditor)
function EditorForceEndAssaultState:create_element()
	self.super.create_element(self)
	self._element.class = "ElementForceEndAssaultState"
end

function EditorForceEndAssaultState:_build_panel()
    self:_create_panel()
    self:Text("This element makes the assault end prematurely")
end
