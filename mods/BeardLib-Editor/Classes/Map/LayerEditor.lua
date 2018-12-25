LayerEditor = LayerEditor or class(EditorPart)

function LayerEditor:loaded_continents()
    for _, unit in pairs(self._created_units) do
        unit:set_slot(0)
        World:delete_unit(unit)
    end
    self._created_units = {}
end