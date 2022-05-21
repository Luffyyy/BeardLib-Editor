EditorEnableUnit = EditorEnableUnit or class(MissionScriptEditor)
function EditorEnableUnit:create_element()
    EditorEnableUnit.super.create_element(self)
    self._element.class = "ElementEnableUnit"
    self._element.values.unit_ids = {}
end

function EditorEnableUnit:get_units()
    if not self._element.values.unit_ids then
        return
    end
    self._units = {}
    for _, unit_id in pairs(self._element.values.unit_ids) do
        local unit = managers.worlddefinition:get_unit(unit_id)
        if alive(unit) then
            table.insert(self._units, unit)
        end
    end
end

function EditorEnableUnit:update_element(...)
    EditorEnableUnit.super.update_element(self, ...)
    self:get_units()
end

function EditorEnableUnit:update_selected()
    if self._units then
        for id, unit in pairs(self._units) do
            if not alive(unit) then
                table.delete(self._element.values.unit_ids, id)

                self._units[id] = nil
            else
                local params = {
                    g = 1,
                    b = 0,
                    r = 0,
                    from_unit = self._unit,
                    to_unit = unit
                }

                self:draw_link(params)
                Application:draw(unit, 0, 1, 0)
            end
        end
    end
end

function EditorEnableUnit:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("unit_ids")
end

EditorDisableUnit = EditorDisableUnit or class(EditorEnableUnit)
function EditorDisableUnit:create_element()
    EditorEnableUnit.super.create_element(self)
    self._element.class = "ElementDisableUnit"
    self._element.values.unit_ids = {}
end