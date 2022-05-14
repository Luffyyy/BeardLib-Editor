EditMeshVariation = EditMeshVariation or class(EditUnit)
function EditMeshVariation:editable(unit)
    local mesh_variations = table.list_union(
        managers.sequence:get_editable_state_sequence_list(unit:name()) or {},
        managers.sequence:get_triggable_sequence_list(unit:name())
    )
    local materials = self:get_material_configs_from_meta(unit)

    return #mesh_variations > 0 or #materials > 0
end

function EditMeshVariation:build_menu(units)
    local main = self._menu:GetItem("Main")
	main:combobox("MeshVariation", ClassClbk(self._parent, "set_unit_data"), {}, 1, {free_typing = true})
	main:pathbox("MaterialVariation", ClassClbk(self._parent, "set_unit_data"), "", "material_config", {custom_list = {}, control_slice = 0.58})
end

function EditMeshVariation:set_unit_data()
    local unit = self:selected_unit()
    local ud = unit:unit_data()
    ud.mesh_variation = self._menu:GetItem("MeshVariation"):SelectedItem()
    local mesh_variation = ud.mesh_variation
    if mesh_variation and mesh_variation ~= "" then
        
        --The delayed collision update breaks animations in the sequence, so this needs a delay too
        BeardLib:AddDelayedCall("BLEMeshVariation"..tostring(mesh_variation), 0.015, function()
            managers.sequence:run_sequence_simple2(mesh_variation, "change_state", unit)
        end, true)
    end

    local material = self._menu:GetItem("MaterialVariation"):Value()
    local default = material == "default"
    ud.material_variation = nil

    local node = not default and BLE.Utils:ParseXml("material_config", material)
    if default or (DB:has(Idstring("material_config"), material:id()) and self:material_config_ok(node, unit)) then
        ud.material_variation = material
    end

    material = ud.material_variation
    if material == "default" then
        material = nil
    end

    local final_mat = (material and Idstring(material)) or PackageManager:unit_data(unit:name()):material_config()
    if ud.material ~= ud.material_variation and DB:has(Idstring("material_config"), final_mat) then
        unit:set_material_config((material and Idstring(material)) or PackageManager:unit_data(unit:name()):material_config(), true)
        ud.material = ud.material_variation
    end
end

function EditMeshVariation:material_config_ok(node, unit)
    if node then
        for material in node:children() do
            if not unit:material(material:parameter("name"):id()) then
                return false
            end
        end
    end
    return true
end

function EditMeshVariation:get_material_configs_from_meta(unit)
    local unit_name = unit:unit_data().name
    if not unit_name then
        return {}
    end

    local name = unit_name:id()
	self._avalible_material_groups = self._avalible_material_groups or {}

	if self._avalible_material_groups[name:key()] then
		return self._avalible_material_groups[name:key()]
	end

	local node = PackageManager:unit_data(name):model_script_data()
	local available_groups = {}
	local groups = {}

	for child in node:children() do
		if child:name() == "metadata" and child:parameter("material_config_group") ~= "" then
			table.insert(groups, child:parameter("material_config_group"))
		end
    end

    if #groups > 0 then
        local list = BLE.Utils:GetEntries({type = "material_config", loaded = false, match = Path:GetDirectory(unit_name, "/"), filenames = false})
        for _, entry in ipairs(list) do
            local node = BLE.Utils:ParseXml("material_config", entry)
            if not node then
                local asset = BeardLibFileManager:Get("material_config", entry)
                if asset and FileIO:Exists(asset.file) then
                    node = SystemFS:parse_xml(asset.file, "r")
                end
            end

            if node then
                for _, group in ipairs(groups) do
                    local group_name = node:has_parameter("group") and node:parameter("group")

                    if group_name == group and not table.contains(available_groups, entry) then
                        if self:material_config_ok(node, unit) then
                            table.insert(available_groups, entry)
                        end
                    end
                end
            end
        end

        table.insert(available_groups, "default")
	end

	self._avalible_material_groups[unit_name:key()] = available_groups

	return available_groups
end

function EditMeshVariation:set_menu_unit(unit)
    local mesh = self._menu:GetItem("MeshVariation")
    local material = self._menu:GetItem("MaterialVariation")
    local mesh_variations = table.list_union(managers.sequence:get_editable_state_sequence_list(unit:name()), managers.sequence:get_triggable_sequence_list(unit:name()))
    local materials = self:get_material_configs_from_meta(unit)

    mesh:SetVisible(#mesh_variations > 0)
    table.insert(mesh_variations, "")
    mesh:SetItems(mesh_variations)
    mesh:SetSelectedItem(unit:unit_data().mesh_variation or "")

    material:SetVisible(#materials > 0)
    material.custom_list = materials
    material:SetValue(unit:unit_data().material_variation or "")
end