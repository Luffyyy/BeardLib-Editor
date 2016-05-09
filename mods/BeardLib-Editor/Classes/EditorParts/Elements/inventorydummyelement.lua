EditorInventoryDummy = EditorInventoryDummy or class(MissionScriptEditor)
function EditorInventoryDummy:init(unit)
	MissionScriptEditor.init(self, unit)
end

function EditorInventoryDummy:create_element()
	self.super.create_element(self)
	self._element.class = "ElementInventoryDummy"
	self._element.values.category = "none"
	self._element.values.slot = 1 
end

function EditorInventoryDummy:_build_panel()
	self:_create_panel()
	self:_build_value_combobox("category", {
		"none",
		"secondaries",
		"primaries",
		"masks"
	}, "Select a crafted category.")
	self:_build_value_number("slot", {
		floats = 0,
		min = 1,
		max = 9
	}, "Set inventory slot to spawn")
end
