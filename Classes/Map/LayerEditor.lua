LayerEditor = LayerEditor or class(EditorPart)
LayerEditor._created_units = {}

function LayerEditor:loaded_continents()
    self:destroy_units_temp()
end

function LayerEditor:destroy_units_temp()
    for _, unit in pairs(clone(self._created_units)) do
        local ud = unit:unit_data()
        local obj = ud.environment_area or ud.emitter or ud.occ_shape
        if obj then
            obj._unit = nil --Doesn't fully fix issue #300 but fixes when doing the same in SoundEnvironmentManager.lua
        end
        unit:set_slot(0)
        World:delete_unit(unit)
        table.delete(self._created_units, unit)
    end
end

function LayerEditor:destroy()
    self:destroy_units_temp()
end