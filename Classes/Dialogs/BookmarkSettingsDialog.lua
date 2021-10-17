BookmarkSettingsDialog = BookmarkSettingsDialog or class(MenuDialog)
BookmarkSettingsDialog.type_name = "BookmarkSettingsDialog"
function BookmarkSettingsDialog:_Show(params)
    local p = table.merge({title = "Camera Bookmark Settings", yes = "Apply", no = "Cancel"}, params)
    if not self.super._Show(self, p) then
        return
    end
    local world_data = managers.worlddefinition._world_data
    local name = params.name
    self._current = name

    local bookmark = world_data.camera_bookmarks[name] 
    local is_default = world_data.camera_bookmarks.default == name

    ItemExt:add_funcs(self)
    self:textbox("Name", callback(self, self, "SetName"), name, {index = 2})
    self:Vector3("Position", nil, bookmark.position, {index = 3})
    self:Rotation("Rotation", nil, bookmark.rotation, {index = 4})
    self:button("SetCurrentPosition", callback(self, self, "SetCurrentPosition"), {text = "Set To Current Position", index = 5})
    self:tickbox("LevelStartLocation", nil, is_default, {help="Sets if this is the starting location for the camera when the level loads", index = 6})
end

function BookmarkSettingsDialog:SetCurrentPosition(item)
    self:GetItem("Position"):SetValue(managers.editor._camera_pos)
    self:GetItem("Rotation"):SetValue(managers.editor._camera_rot)
end

function BookmarkSettingsDialog:SetName(item)
    local name = item:Value()
    local warn = self:GetItem("NameWarning")
    if alive(warn) then
        warn:Destroy()
    end
    
    self._new_name = nil
    
    if name == "" then
        self:divider("NameWarning", {text = "Warning: Name cannot be empty, name will not be saved.", index = 2})
    elseif name == "default" or string.begins(name, " ") then
        self:divider("NameWarning", {text = "Warning: Name cannot begin with a space or be named as default, name will not be saved.", index = 2})
    elseif managers.worlddefinition._world_data.camera_bookmarks[name] then
        self:divider("NameWarning", {text = "Warning: Name already exists, name will not be saved.", index = 2})
    else
        self._new_name = name
    end
end

function BookmarkSettingsDialog:hide(success)
    local world_data = managers.worlddefinition._world_data
    if success then
        local current_name = self._current
        local new_name = self._new_name
        local bookmark = world_data.camera_bookmarks[current_name]

        bookmark.position = self:GetItem("Position"):Value()
        bookmark.rotation = self:GetItem("Rotation"):Value()

        if self:GetItem("LevelStartLocation"):Value() then
            world_data.camera_bookmarks.default = current_name
        elseif world_data.camera_bookmarks.default == current_name then
            world_data.camera_bookmarks.default = nil
        end

        if new_name and not (new_name == "" and new_name == "default" or string.begins(new_name, " ") and world_data.camera_bookmarks[new_name]) then
            world_data.camera_bookmarks[new_name] = deep_clone(bookmark)
            world_data.camera_bookmarks[current_name] = nil
            if world_data.camera_bookmarks.default == current_name then
                world_data.camera_bookmarks.default = new_name
            end
        end 
    end
    self._new_name = nil
    self._current = nil

    return BookmarkSettingsDialog.super.hide(self, success)
end