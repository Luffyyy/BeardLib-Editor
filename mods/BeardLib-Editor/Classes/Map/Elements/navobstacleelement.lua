EditorNavObstacle = EditorNavObstacle or class(MissionScriptEditor)
function EditorNavObstacle:create_element()
	EditorNavObstacle.super.create_element(self)
	self._element.class = "ElementNavObstacle"
	self._element.values.obstacle_list = {}	
	self._element.values.operation = "add"	
	self._guis = {}
	self._obstacle_units = {}
	self._all_object_names = {}
end

function EditorUnitSequenceTrigger:set_selected_obstacle_object(menu, item)
	self._element.values.obstacle_list[self._menu:GetItem("obstacle_list"):Value()].obj_name = Idstring(item:SelectedItem())
	self:update_element()
end

function EditorNavObstacle:update_obstacle_list()
	local combo_obstacle_list = {}
	local obstacle_list = {}
	local obstacle_combo = self._menu:GetItem("obstacle_list")	
	local selected_obstacle = self._menu:GetItem("selected_obstacle")
	for _, obstacle_unit in pairs(self._element.values.obstacle_list) do
		local unit = managers.worlddefinition:get_unit_on_load(obstacle_unit.unit_id)  
		if alive(unit) then		
			table.insert(combo_obstacle_list, unit:unit_data().name_id .. "[" .. obstacle_unit.unit_id .. "]")
			table.insert(obstacle_list, obstacle_unit.unit_id)
		end
	end		
	if #obstacle_combo.items ~= #combo_obstacle_list then
		obstacle_combo:SetValue(1)
	end
	sequence_combo:SetItems(combo_obstacle_list)
	if #obstacle_list > 0 and obstacle_combo:SelectedItem() then
		local unit = managers.worlddefinition:get_unit_on_load(obstacle_list[obstacle_combo:Value()])   
		if alive(unit) then
			local objects = self:_get_objects_by_unit(unit)
			table.insert(objects, "")
			selected_obstacle:SetItems(objects)
			local obstacle_unit = self._element.values.obstacle_list[obstacle_combo:Value()]
			selected_obstacle:SetSelectedItem(obstacle_unit.sequence)
		end
	else
		selected_obstacle:SetItems()
	end
	self:update_element()
end

function EditorNavObstacle:_build_panel()
	self:_create_panel()
	self:ComboCtrl("operation", {"add", "remove"}, {help = "Choose if you want to add or remove an obstacle"})
	local obstacle_list = {}
	for _, unit in pairs(self._element.values.obstacle_list) do
		table.insert(obstacle_list, unit.unit_id)
	end
	self:ComboBox("obstacle_list", callback(self, self, "update_obstacle_list"), obstacle_list, nil, {group = self._class_group})
	self:ComboBox("selected_obstacle", callback(self, self, "set_selected_obstacle_object"), {}, nil, {group = self._class_group})
	self:BuildUnitsManage("obstacle_list", {key = "unit_id", orig = {unit_id = 0, object = ""}}, callback(self, self, "update_obstacle_list"))
end

function EditorNavObstacle:_get_objects_by_unit(unit)
	local all_object_names = {}
	if unit then
		local root_obj = unit:orientation_object()
		all_object_names = {}
		local tree_depth = 1
		local _process_object_tree
		function _process_object_tree(obj, depth)
			local indented_name = BeardLibEditor.Utils:Unhash(obj:name(), "other") --:s()
			for i = 1, depth do
				indented_name = indented_name
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
