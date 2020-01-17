EditorCheckDLC = EditorCheckDLC or class(MissionScriptEditor)
function EditorCheckDLC:create_element(...)
	EditorCheckDLC.super.create_element(self, ...)
	self._element.class = "ElementCheckDLC"
	self._element.values.dlc_ids = {}
	self._element.values.require_all = false
	self._element.values.invert = false
end

function EditorCheckDLC:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("require_all", {text = "Require all DLCs to execute"})
	self:BooleanCtrl("invert", {text = "Execute only if DLCs not owned"})
	local dlcs_alphabetical = {}
	for dlc_name, dlc_data in pairs(Global.dlc_manager.all_dlc_data) do
		table.insert(dlcs_alphabetical, dlc_name)
	end
	table.sort(dlcs_alphabetical, function(a, b) return a < b end)
	self:ListSelector("dlc_ids", dlcs_alphabetical, {label = "DLCs"})
end