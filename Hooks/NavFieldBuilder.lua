if not Global.editor_mode then
	return
end

function NavFieldBuilder:_create_build_progress_bar(title, num_divistions)
	if not self._progress_dialog then
		local status = BLE.Utils:GetPart("status")
		self._progress_dialog = status:StatusDialog(title, "expanding room", {{name = "Cancel", callback = function()
			self._progress_dialog_cancel = true
			BLE.Utils:GetLayer("ai"):reenable_disabled_units()
		end}})
	end
end

function NavFieldBuilder:_update_progress_bar(percent_complete, title)
	if self._progress_dialog then
		self._progress_dialog:GetItem("Sub"):SetText(title)
	end
end

function NavFieldBuilder:_destroy_progress_bar()
	if self._progress_dialog then
		self._progress_dialog:Destroy()
		self._progress_dialog = nil
	end
end