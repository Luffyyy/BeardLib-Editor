EditorAIGraph = EditorAIGraph or class(MissionScriptEditor)
EditorAIGraph.LINK_ELEMENTS = {"elements"}
function EditorAIGraph:create_element()
	EditorAIGraph.super.create_element(self)
	self._element.class = "ElementAIGraph"
	self._element.values.graph_ids = {}
	self._element.values.operation = NavigationManager.nav_states[1]
end

function EditorAIGraph:check_unit(unit)
	return unit:type() == Idstring("ai")
end

function EditorAIGraph:_build_panel()
	self:_create_panel()
	self:BuildUnitsManage("graph_ids", nil, nil, {text = "Graph Units", check_unit = callback(self, self, "check_unit")})
	self:ComboCtrl("operation", NavigationManager.nav_states)
	self:Text("The operation defines what to do with the selected graphs")
end
