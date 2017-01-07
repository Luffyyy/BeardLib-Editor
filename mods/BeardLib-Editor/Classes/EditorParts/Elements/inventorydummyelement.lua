EditorInventoryDummy = EditorInventoryDummy or class(MissionScriptEditor)
function EditorInventoryDummy:create_element()
	self.super.create_element(self)
	self._element.class = "ElementInventoryDummy"
	self._element.values.category = "none"
	self._element.values.slot = 1 
end

function EditorInventoryDummy:_build_panel()
	self:_create_panel()
	self:ComboCtrl("category", {
		"none",
		"secondaries",
		"primaries",
		"masks"
	}, {help = "Select a crafted category."})
	self:NumberCtrl("slot", {
		floats = 0,
		min = 1,
		max = 9, 
		help = "Set inventory slot to spawn"
	})
end
