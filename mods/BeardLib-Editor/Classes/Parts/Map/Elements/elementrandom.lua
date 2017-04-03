EditorRandom = EditorRandom or class(MissionScriptEditor)
function EditorRandom:create_element()
	EditorRandom.super.create_element(self)
    self._element.class = "ElementRandom"
	self._element.values.amount = 1
	self._element.values.amount_random = 0
	self._element.values.ignore_disabled = true
	self._element.values.counter_id = nil
end

function EditorRandom:select_element(item)
	self._element.values.counter_id = item.element.id
	BeardLibEditor.ListDialog:hide()
end

function EditorRandom:_build_panel()
	self:_create_panel()
	self:Button("Choose counter element", callback(self, SpawnSelect, "OpenSelectElementDialog", {
		on_click = callback(self, self, "select_element")
	}), {help = "Decide what counter element this element should handle"})
    self:NumberCtrl("amount", {floats = 0, min = 1, help = "Specifies the amount of elements to be executed"})
    self:NumberCtrl("amount_random", {floats = 0, min = 0, help = "Add a random amount to amount"})
	self:BooleanCtrl("ignore_disabled")
	self:Text("Use 'Amount' only to specify an exact amount of elements to execute. Use 'Amount Random' to add a random amount to 'Amount' ('Amount' + random('Amount Random').")
end
