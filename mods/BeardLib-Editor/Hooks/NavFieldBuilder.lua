if not Global.editor_mode then
	return
end
function NavFieldBuilder:_create_build_progress_bar(title, num_divistions)
	local status = managers.editor.managers.status
	if not self._created_button then
		status._menu:Button({name = "Cancel", text_align = "right", callback = function()
			self._progress_dialog_cancel = true
		end})
		self._created_button = true
	end
	status:SetStatus(title)
end

function NavFieldBuilder:_update_progress_bar(percent_complete, title)
	managers.editor.managers.status:SetStatus(title)
end

function NavFieldBuilder:update(t, dt)
	if self._building then
		self._building.task_clbk(self)
	end
end

function NavFieldBuilder:update(t, dt)
	if self._building then
		if self._progress_dialog_cancel then
			self._progress_dialog_cancel = nil

			self:clear()
			self:_destroy_progress_bar()

			self._building = nil
			self._created_dialog = nil
		else
			self._building.task_clbk(self)
		end
	end
end

function NavFieldBuilder:_destroy_progress_bar()
	local status = managers.editor.managers.status
	status:SetStatus()
	local cancel = status._menu:GetItem("Cancel")
	if cancel then
		cancel:Destroy()
	end
	self._created_button = false
end