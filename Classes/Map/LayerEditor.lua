LayerEditor = LayerEditor or class(EditorPart)

function LayerEditor:loaded_continents()
    --Better handle this event, don't recreate things as it may cause pointless slowdowns/problems.
    for _, unit in pairs(clone(self._created_units)) do
        local ud = unit:unit_data()
        local obj = ud.environment_area or ud.emitter
        if obj then
            obj._unit = nil --Doesn't fully fix issue #300 but fixes when doing the same in SoundEnvironmentManager.lua
        end
        unit:set_slot(0)
        World:delete_unit(unit)
        table.delete(self._created_units, unit)
    end
end

function LayerEditor:destroy()
    for _, unit in pairs(self._created_units) do
		managers.editor:DeleteUnit(unit)
	end
end