EditAIData = EditAIData or class(EditUnit)
function EditAIData:editable(unit) return unit:ai_editor_data() end
function EditAIData:UpdateLoc()   
	self._menu:GetItem("LocOfLocation"):SetText("Text = " .. managers.localization:text(self:selected_unit():ai_editor_data().location_id or "location_unknown"))
end

function EditAIData:build_menu(parent)
	local ai = self:Group("AIEditorData")
	self:TextBox("LocationId", callback(self._parent, self._parent, "set_unit_data"), "", {help = "Select a location id to be associated with this navigation point", group = ai})
	self:Divider("LocOfLocation", {text = "Text = " .. managers.localization:text("location_unknown"), group = ai})
	self:NumberBox("SuspicionMultiplier", callback(self._parent, self._parent, "set_unit_data"), 1, {min = 1, floats = 1, help = "multiplier applied to suspicion buildup rate", group = ai})
	self:NumberBox("DetectionMultiplier", callback(self._parent, self._parent, "set_unit_data"), 1, {min = 0.01, help = "multiplier applied to AI detection speed. min is 0.01", group = ai})
end


function EditAIData:set_menu_unit(unit)   
	self._menu:GetItem("LocationId"):SetValue(unit:ai_editor_data().location_id or "location_unknown")
	self._menu:GetItem("SuspicionMultiplier"):SetValue(unit:ai_editor_data().suspicion_multiplier)
	self._menu:GetItem("DetectionMultiplier"):SetValue(unit:ai_editor_data().detection_multiplier)	
	self:UpdateLoc()
end

function EditAIData:set_unit_data()
	local unit = self:selected_unit()
	if unit then
		unit:ai_editor_data().location_id = self._menu:GetItem("LocationId"):Value()
		unit:ai_editor_data().suspicion_multiplier = self._menu:GetItem("SuspicionMultiplier"):Value()
		unit:ai_editor_data().detection_multiplier = self._menu:GetItem("DetectionMultiplier"):Value()
 		self:UpdateLoc()
	end
end