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
	self:ComboCtrl("operation", {"add", "remove"}, {help = "Choose if you want to add or remove an obstacle"})
	self:BuildUnitsManage("obstacle_list", {values_name = "Object", value_key = "obj_name", key = "unit_id", orig = {unit_id = 0, obj_name = "", guis_id = 1}, combo_items_func = function(name, value)
		-- get all obj idstrings and map them to unindented values
		-- why the fuck is this function called collect it should be called map AAAA
		local objects = table.collect(self:_get_objects_by_unit(value.unit), self._unindent_obj_name)
		return objects
	end})
end

function EditorNavObstacle:_get_objects_by_unit(unit)
	local all_object_names = {}

	if unit then
		local root_obj = unit:orientation_object()
		all_object_names = {}
		local tree_depth = 1

		local function _process_object_tree(obj, depth)
			local indented_name = obj:name():s()

			for i = 1, depth, 1 do
				indented_name = "-" .. indented_name
			end

			table.insert(all_object_names, indented_name)

			local children = obj:children()

			for _, child in ipairs(children) do
				_process_object_tree(child, depth + 1)
			end
		end

		_process_object_tree(root_obj, 0)
	end

	return all_object_names
end

function EditorNavObstacle._unindent_obj_name(obj_name)
	while string.sub(obj_name, 1, 1) == "-" do
		obj_name = string.sub(obj_name, 2)
	end

	-- get rid of @ID(obj_name)@
	return obj_name:match("@ID(.*)@")
end