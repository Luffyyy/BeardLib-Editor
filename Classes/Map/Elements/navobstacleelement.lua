EditorNavObstacle = EditorNavObstacle or class(MissionScriptEditor) --Currently broken
function EditorNavObstacle:create_element()
    EditorNavObstacle.super.create_element(self)
    self._element.class = "ElementNavObstacle"
    self._element.values.obstacle_list = {}
    self._element.values.operation = "add"
    self._guis = {}
    self._obstacle_units = {}
    self._all_object_names = {}
end

function EditorNavObstacle:_build_panel()
    self:_create_panel()
    self:ComboCtrl("operation", { "add", "remove" }, { help = "Choose if you want to add or remove an obstacle" })
    self:BuildUnitsManage("obstacle_list", { values_name = "Object", value_key = "obj_name", key = "unit_id", orig = {unit_id = 0, obj_name = nil, guis_id = 1}, combo_items_func = function(name, value)
        -- get all obj idstrings and map them to unindented values
        return table.collect(self:_get_objects_by_unit(value.unit), self._unindent_obj_name)
    end})
end

function EditorNavObstacle:_get_objects_by_unit(unit)
    local all_object_names = {}

    if unit then
        local root_obj = unit:orientation_object()
        local function _process_object_tree(obj, depth)
            local name = obj:name()
            local indented_name = BLE.Utils:UnhashStr(name)
            local has_unhashed = indented_name == nil
            indented_name = indented_name or name:key()

            for i = 1, depth  do
                indented_name = "-" .. indented_name
            end

            table.insert(all_object_names, {unhashed = indented_name, hashed = name, has_unhashed = has_unhashed})

            local children = obj:children()

            for _, child in ipairs(children) do
                _process_object_tree(child, depth + 1)
            end
        end

        _process_object_tree(root_obj, 0)
    end

    return all_object_names
end

function EditorNavObstacle._unindent_obj_name(obj)
    local obj_name = obj.unhashed
    while string.sub(obj_name, 1, 1) == "-" do
        obj_name = string.sub(obj_name, 2)
    end

    return {text = obj_name, value = obj.hashed}
end