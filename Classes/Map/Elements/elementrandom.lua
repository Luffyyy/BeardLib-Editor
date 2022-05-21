EditorRandom = EditorRandom or class(MissionScriptEditor)
function EditorRandom:create_element()
	EditorRandom.super.create_element(self)
    self._element.class = "ElementRandom"
	self._element.values.amount = 1
	self._element.values.amount_random = 0
	self._element.values.ignore_disabled = true
end

function EditorRandom:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("counter_id", nil, {"ElementCounter"}, nil, {
		text = "Counter element", single_select = true, not_table = true, help = "Decide what counter element this element should handle"
	})
    self:NumberCtrl("amount", {floats = 0, min = 1, help = "Specifies the amount of elements to be executed"})
    self:NumberCtrl("amount_random", {floats = 0, min = 0, help = "Add a random amount to amount"})
	self:BooleanCtrl("ignore_disabled")
	self:Text("Use 'Amount' only to specify an exact amount of elements to execute. Use 'Amount Random' to add a random amount to 'Amount' ('Amount' + random('Amount Random').")
end

function EditorRandom:update_selected(t, dt)
    if not alive(self._unit) then
        return
    end

    if self._element.values.counter_id then
		local unit = self:GetPart('mission'):get_element_unit(self._element.values.counter_id)
		local r, g, b = unit:mission_element():get_link_color()
		if unit then
			self:draw_link(
				{
					g = g,
					b = b,
					r = r,
					from_unit = self._unit,
					to_unit = unit
				}
			)
		else
			self._element.values.counter_id = nil
		end
    end
end

function EditorRandom:link_managed(unit)
	if alive(unit) then
		if unit:mission_element() and unit:mission_element().element.class == "ElementCounter" then
			self:AddOrRemoveManaged("counter_id", {element = unit:mission_element().element}, {not_table = true})
		end
	end
end