EditorOverrideInstigator = EditorOverrideInstigator or class(MissionScriptEditor)
function EditorOverrideInstigator:create_element()
    self.super.create_element(self)
    self._element.class = "ElementOverrideInstigator"
end

function EditorOverrideInstigator:_build_panel()
    self:_create_panel()
    self:BuildUnitsManage("unit_id", nil, nil, {text = "Instigator", single_select = true, not_table = true})
end

function EditorOverrideInstigator:update_selected(t, dt)
    local unit = managers.worlddefinition:get_unit(self._element.values.unit_id)
    if alive(unit) then
        self:draw_link({
            from_unit = unit,
            to_unit = self._unit,
            r = 0,
            g = 0.75,
            b = 0
        })
        Application:draw(unit, 0, 0.75, 0)
    else
        self._element.values.unit_id = nil
        return
    end
end

function EditorOverrideInstigator:link_managed(unit)
	if alive(unit) and unit:unit_data() then
		self:AddOrRemoveManaged("unit_id", {unit = unit}, {not_table = true})
	end
end