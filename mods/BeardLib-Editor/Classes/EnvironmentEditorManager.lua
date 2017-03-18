EnvironmentEditorManager = EnvironmentEditorManager or class()

function EnvironmentEditorManager:init()
    self._handlers = {}
    local menu = BeardLibEditor.managers.Menu
    self._menu = menu:make_page("EnvironmentEditor")
    MenuUtils:new(self)
    self:PopulateEnvMenu()
end

function EnvironmentEditorManager:EnvironmentEditorExit(menu, item)
    if BeardLibEditor.path_text then
   --     BeardLibEditor.path_text:set_visible(false)
    end

end

function EnvironmentEditorManager:EnvEditorClbk(menu, item)
    self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true)
end

function EnvironmentEditorManager:EnvEditorVectorXClbk(menu, item)
    self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true, "x")
end

function EnvironmentEditorManager:EnvEditorVectorYClbk(menu, item)
    self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true, "y")
end

function EnvironmentEditorManager:EnvEditorVectorZClbk(menu, item)
    self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true, "z")
end

function EnvironmentEditorManager:EnvEditorStringClbk(menu, item)
    local split = string.split(item._parameters.path, "/")
    if split[#split] == "underlay" then
        if not managers.dyn_resource:has_resource(Idstring("scene"), Idstring(item._parameters.help_id), managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
            managers.dyn_resource:load(Idstring("scene"), Idstring(item._parameters.help_id), managers.dyn_resource.DYN_RESOURCES_PACKAGE, nil)
        end
    end

    self:SetValue(self._active_environment, item._parameters.path_key, item._parameters.help_id, item._parameters.path, true)
end

 

function EnvironmentEditorManager:GetHandler(file_key)
    return self._handlers[file_key] and self._handlers[file_key] or nil
end

function EnvironmentEditorManager:AddHandlerValue(file_key, path_key, value, path)
    local handler = self:GetHandler(file_key)
    if not handler then
        handler = EnvironmentEditorHandler:new(file_key)
        self._handlers[file_key] = handler
    end

    handler:AddValue(path_key, value, path)
end

function EnvironmentEditorManager:SetActiveEnvironment(file_key)
    self._active_environment = file_key or self._active_environment or nil
end

function EnvironmentEditorManager:SetValue(file_key, path_key, value, path, editor, vtype)
    if not file_key then
        file_key = self._active_environment
    end

    local handler = self:GetHandler(file_key)
    if not handler then
        BeardLibEditor:log("[ERROR] Handler does not exist " .. tostring(file_key))
        return
    end

    handler:SetValue(path_key, value, path, editor, vtype)
end

function EnvironmentEditorManager:ApplyValue(path_key, data)
    if managers.viewport and managers.viewport:viewports() then
        for _, viewport in pairs(managers.viewport:viewports()) do
            if viewport and viewport._env_handler and viewport:get_environment_path():key() == self._active_environment then
                local editorHandler = self:GetHandler(self._active_environment)
                local handler = viewport._env_handler
                local value = viewport:get_environment_value(path_key)
                local val_to_save = data.value

                if CoreClass.type_name(value) == "Vector3" then
                    local new_value
                    if CoreClass.type_name(data.value) == "number" then
                        new_value = Vector3(data.vtype == "x" and data.value or value.x, data.vtype == "y" and data.value or value.y, data.vtype == "z" and data.value or value.z)
                    else
                        new_value = Vector3(data.value.x or value.x, data.value.y or value.y, data.value.z or value.z)
                    end
                    handler:editor_set_value(path_key, new_value)
                    val_to_save = new_value
                else
                    handler:editor_set_value(path_key, data.value)
                end

                if data.editor then
                    editorHandler._current_data[path_key] = {path = data.path, value = val_to_save}
                end
            end
        end
    end
end

function EnvironmentEditorManager:update(t, dt)
    local viewport = managers.menu_scene and managers.menu_scene._vp or managers.player and managers.player:player_unit() and managers.player:player_unit():camera() and managers.player:player_unit():camera()._vp or nil
    if viewport then
        self._active_environment = viewport:get_environment_path():key()
    end
    self:ApplyValues()
end

function EnvironmentEditorManager:paused_update(t, dt)
    self:ApplyValues()
end

function EnvironmentEditorManager:ApplyValues()
    local handler = self:GetHandler(self._active_environment)
    if handler and table.size(handler._apply_data) > 0 then
        for key, data in pairs(handler._apply_data) do
            setup:add_end_frame_clbk(function()
                self:ApplyValue(key, data)
                handler._apply_data[key] = nil
            end)
        end
    end
end


function EnvironmentEditorManager:FilenameEnteredCallback(success, value)
    if success then
        self.current_filename = value
        local handler = self:GetHandler(self._active_environment)
        local data = handler:GetEditorValues()
        local fileName = self.current_filename
        local write_data = {
            _meta = "environment",
            metadata = {_meta="metadata"},
            data = {}
        }
        local add_param = function(_, value)
            local param_split = string.split(value.path, "/")
            local param_name = table.remove(param_split)
            local cur_tbl = write_data.data
            for _, tbl_name in pairs(param_split) do
                cur_tbl[tbl_name] = cur_tbl[tbl_name] or {_meta = tbl_name}
                cur_tbl = cur_tbl[tbl_name]
            end
            table.insert(cur_tbl, {
                _meta="param",
                key = param_name,
                value = value.value
            })
        end
        for i, val in pairs(data) do
            add_param(i, val)
        end
        local file = io.open(fileName, "w+")
        file:write(ScriptSerializer:to_custom_xml(write_data))
        file:close()
    end
end

EnvironmentEditorManager.KeyMinMax = {
	[("ambient_scale"):key()] = {min = -0.99, max = 0.99},
	[("ambient_color_scale"):key()] = {min = -50, max = 50},
	[("sun_range"):key()] = {min = 1, max = 150000},
	[("fog_min_range"):key()] = {min = -500, max = 1000},
	[("fog_max_range"):key()] = {min = -500, max = 4000},
	[("ambient_falloff_scale"):key()] = {min = -20, max = 20},
	[("sky_bottom_color_scale"):key()] = {min = -50, max = 50},
	[("sky_top_color_scale"):key()] = {min = -50, max = 50},
	[("sun_ray_color_scale"):key()] = {min = -100, max = 100},
	[("color2_scale"):key()] = {min = -15, max = 15},
	[("color0_scale"):key()] = {min = -15, max = 15},
	[("color1_scale"):key()] = {min = -15, max = 15},
    [("sky_orientation/rotation"):key()] = {min = 0, max = 360}
}

function EnvironmentEditorManager:AddEditorButton(key, path, value)
	local path_split = string.split(path, "/")
    local button_name = path_split[#path_split]
    local min = self.KeyMinMax[key] and self.KeyMinMax[key].min
    local max = self.KeyMinMax[key] and self.KeyMinMax[key].max
	if tonumber(value) ~= nil then
        self:Slider(id, callback(self, self, "EnvEditorClbk"),  value, {min = min or -300, max = max or 300, step = 0.01, text = button_name, path = path, path_key = key})
	elseif value.x then
        self:Slider(path .. "-x", callback(self, self, "EnvEditorVectorXClbk"), value.x, {min = min or - 1, max = max or 1, step = 0.01, text = button_name .. "-X", path = path, path_key = key})
        self:Slider(path .. "-y", callback(self, self, "EnvEditorVectorYClbk"), value.y, {min = min or - 1, max = max or 1, step = 0.01, text = button_name .. "-Y", path = path, path_key = key})
        self:Slider(path .. "-z", callback(self, self, "EnvEditorVectorZClbk"), value.z, {min = min or - 1, max = max or 1, step = 0.01, text = button_name .. "-Z", path = path, path_key = key})
	else
        self:Button(path, callback(self, self, "EnvEditorStringClbk"), {text = button_name, string_value = value, path = path, path_key = key, input = true})
	end
end

function EnvironmentEditorManager:SaveEnvtable(menu, item)
    managers.system_menu:show_keyboard_input({text = "EnvModification" .. tostring(self._active_environment) .. ".txt", title = "Environment Mod Filename", callback_func = callback(self, self, "FilenameEnteredCallback")})
end

function EnvironmentEditorManager:ResetEnvEditor(menu, item)
    local handler = self:GetHandler(self._active_environment)
    if handler then
        handler._current_data = {}
        for key, params in pairs(handler:GetEditorValues()) do
            self:SetValue(self._active_environment, key, params.value)
        end
    end

    self:PopulateEnvMenu()
    local selected_node = managers.menu:active_menu().logic:selected_node()
    managers.menu:active_menu().renderer:refresh_node(selected_node)
    local selected_item = selected_node:selected_item()
    selected_node:select_item(selected_item and selected_item:name())
    managers.menu:active_menu().renderer:highlight_item(selected_item)
end

function EnvironmentEditorManager:PopulateEnvMenu()
    self:ClearItems()
    self:Button("Save", callback(self, self, "SaveEnvtable"))
    self:Button("Reset", callback(self, self, "ResetEnvEditor"))

    local viewport = managers.menu_scene and managers.menu_scene._vp or managers.player and managers.player:player_unit() and managers.player:player_unit():camera() and managers.player:player_unit():camera()._vp or nil

    if viewport and self._active_environment and self:GetHandler(viewport._env_handler:get_path():key()) then
        local viewport_path = viewport._env_handler:get_path()
        local envHandler = self:GetHandler(viewport_path:key())

        local panel = self._menu:Panel()

        BeardLibEditor.path_text = alive(BeardLibEditor.path_text) and BeardLibEditor.path_text or panel:text({
            name = "BeardLibPathText",
            text = "",
            font =  tweak_data.menu.pd2_medium_font,
            font_size = 25,
            layer = 20,
            color = Color.yellow
        })
        BeardLibEditor.path_text:set_visible(true)
        BeardLibEditor.path_text:set_text(viewport_path)
        local x, y, w, h = BeardLibEditor.path_text:text_rect()
        BeardLibEditor.path_text:set_size(w, h)
        BeardLibEditor.path_text:set_position(0, 0)

        for key, params in pairs(envHandler:GetEditorValues()) do
            log(tostring( key ))
            log(tostring( params ))
            local value = params.value or viewport:get_environment_value(key)
            local parts = string.split(params.path, "/")
            local menu_id = "BeardLibEditor_" .. table.concat(parts, "/", 1, #parts - 1)
       --[[     if not self:GetItem(menu_id .. "button") then
                log(tostring( e ))
                self:Button(menu_id .. "button", )
                MenuHelperPlus:AddButton({
                    id = menu_id .. "button",
                    title = table.concat(parts, "/", 1, #parts - 1),
                    next_node = menu_id,
                    node = node,
                    localized = false
                })
            end]]
            if value then
                self:AddEditorButton(key, params.path, value)
            end
        end
    end
end
