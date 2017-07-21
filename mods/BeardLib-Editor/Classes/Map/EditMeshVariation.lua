EditMeshVariation = EditMeshVariation or class(EditUnit)
function EditMeshVariation:editable(unit)
    local mesh_variations = table.merge(managers.sequence:get_editable_state_sequence_list(unit:name()) or {}, managers.sequence:get_triggable_sequence_list(unit:name()) or {})
    return #mesh_variations > 0
end

function EditMeshVariation:build_menu(units)
	self:ComboBox("MeshVariation", callback(self._parent, self._parent, "set_unit_data"), {}, 1, {group = self._menu:GetItem("Main")})
end

function EditMeshVariation:set_unit_data()
	local unit = self:selected_unit()
    unit:unit_data().mesh_variation = self._menu:GetItem("MeshVariation"):SelectedItem()
    local mesh_variation = unit:unit_data().mesh_variation
    if mesh_variation and mesh_variation ~= "" then
        managers.sequence:run_sequence_simple2(mesh_variation, "change_state", unit)
    end
end

function EditMeshVariation:set_menu_unit(unit)
    local mesh = self._menu:GetItem("MeshVariation")
    local items = table.merge(managers.sequence:get_editable_state_sequence_list(unit:name()), managers.sequence:get_triggable_sequence_list(unit:name()))
    table.insert(items, "")
    mesh:SetItems(items)
    mesh:SetSelectedItem(unit:unit_data().mesh_variation or "")
end