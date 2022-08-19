EditorAIGraph = EditorAIGraph or class(MissionScriptEditor)
EditorAIGraph.LINK_ELEMENTS = {"elements"}
function EditorAIGraph:create_element()
	EditorAIGraph.super.create_element(self)
	self._element.class = "ElementAIGraph"
	self._element.values.graph_ids = {}
	self._element.values.operation = NavigationManager.nav_states[1]
	self._element.values.filter_group = "none"
end

function EditorAIGraph:check_unit(unit)
	return unit:type() == Idstring("ai")
end

function EditorAIGraph:update_selected(t, dt)
	for _, id in pairs(self._element.values.graph_ids) do
		local unit = managers.worlddefinition:get_unit(id)
		if alive(unit) then
			self:draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0,
				g = 0.75,
				b = 0
			})
		else
			table.delete(self._element.values.graph_ids, id)
			return
		end
	end
end

function EditorAIGraph:set_element_data(item)
	EditorAIGraph.super.set_element_data(self, item)

	local filter_group = self:GetItem("filter_group")
	if filter_group and item:Name() == "operation" then
		filter_group:SetEnabled(item:SelectedItem() == "forbid_custom")
	end
end

function EditorAIGraph:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("graph_ids", nil, nil, {text = "Graph Units", check_unit = ClassClbk(self, "check_unit")})
	local operation = self:ComboCtrl("operation", table.list_add(NavigationManager.nav_states, NavigationManager.nav_meta_operations))
	local filter_group = self:ComboCtrl("filter_group", table.list_add({"none"}, ElementSpecialObjective._AI_GROUPS), {help = "Select a custom filter group."})
	self:Text("The operation defines what to do with the selected graphs.\n\"Forbid Custom\" marks the selected graphs as disabled for that specific type of units.")

	filter_group:SetEnabled(operation:SelectedItem() == "forbid_custom")
end

function EditorAIGraph:link_managed(unit)
	if alive(unit) and unit:unit_data() and self:check_unit(unit) then
		self:AddOrRemoveManaged("graph_ids", {unit = unit})
	end
end
