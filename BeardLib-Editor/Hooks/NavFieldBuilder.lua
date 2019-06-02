if not Global.editor_mode then
	return
end

function NavFieldBuilder:_create_build_progress_bar(title, num_divistions)
	local status = BLE.Utils:GetPart("status")
	if not self._created_button then
		status._menu:Button({name = "Cancel", text_align = "right", callback = function()
			self._progress_dialog_cancel = true
			BLE.Utils:GetLayer("ai"):reenable_disabled_units()
		end})
		self._created_button = true
	end
	status:SetVisible(true)
	status:SetStatus(title)
end

function NavFieldBuilder:_update_progress_bar(percent_complete, title)
	BLE.Utils:GetPart("status"):SetStatus(title)
end

function NavFieldBuilder:_destroy_progress_bar()
	local status = BLE.Utils:GetPart("status")
	status:SetStatus()
	local cancel = status._menu:GetItem("Cancel")
	if cancel then
		cancel:Destroy()
	end
	self._created_button = false
end