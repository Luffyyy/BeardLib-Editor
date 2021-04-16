---Editor for BeardLib level module.
---@class ProjectInstanceEditor : ProjectLevelEditor
ProjectInstanceEditor = ProjectInstanceEditor or class(ProjectLevelEditor)
ProjectInstanceEditor.LEVELS_DIR = "levels/instances"
ProjectEditor.EDITORS.instance = ProjectInstanceEditor
ProjectEditor.ACTIONS["CloneInstance"] = function(parent)
    local instances = {}
    for _, path in pairs(BLE.Utils:GetEntries({type = "world"})) do
        if path:match("levels/instances") then
            table.insert(instances, path)
        end
    end

    BLE.ListDialog:Show({
        list = instances,
        callback = function(clone_path)
            BLE.ListDialog:hide()
            ProjectInstanceEditor:new(parent, nil, {clone_path = clone_path})
        end
    })
end

--- @param menu Menu
--- @param data table
function ProjectInstanceEditor:build_menu(menu, data)
    data.orig_id = data.orig_id or data.id
    menu:textbox("InstanceID", ClassClbk(self, "set_data_callback"), data.id, {forbidden_chars = {':','*','?','"','<','>','|'}})
end

function ProjectInstanceEditor:create(create_data)
    local instances = table.map_keys(BeardLib.managers.MapFramework._loaded_instances)
    BLE.InputDialog:Show({
        title = "Enter a name for the instance",
        yes = "Create",
        text = "",
        check_value = function(name)
            local warn

            if name == "" then
                warn = string.format("Id cannot be empty!", name)
            elseif string.begins(name, " ") then
                warn = "Invalid ID!"
            else
                if instances["levels/instances/mods/"..name] then
                    warn = string.format("An instance with the id %s already exists! Please use a unique id", name)
                end
            end
            if warn then
                BLE.Utils:Notify("Error", warn)
            end
            return warn == nil
        end,
        no_callback = function()
            if create_data.final_callback then
                create_data.final_callback(false)
            end
        end,
        callback = function(name)
            local template
            if create_data.clone_path then
                create_data.name = name
                template = self:clone_level(create_data)
            else
                template = deep_clone(BLE.MapProject._instance_module_template)
                template.id = name
                local proj_path = self._parent:get_dir()
                local level_path = Path:Combine(self.LEVELS_DIR, template.id)
                template.include.directory = level_path

                FileIO:MakeDir(Path:Combine(proj_path, level_path))
                FileIO:CopyToAsync(Path:Combine(BLE.MapProject._templates_directory, "Instance"), Path:Combine(proj_path, level_path))
            end
            self:finalize_creation(template, create_data)
            if create_data.final_callback then
                create_data.final_callback(true)
            end
        end
    })
end

function ProjectInstanceEditor:pre_clone_level(create_data)
    local name = create_data.name
    local level = deep_clone(BLE.MapProject._instance_module_template)
    level.id = name
    level.include.directory = Path:Combine(self.LEVELS_DIR, name)
    return level, create_data.clone_path:gsub("world", "")
end

--- The callback function for all items for this menu.
function ProjectInstanceEditor:set_data_callback()
    local data = self._data
    local instances = table.map_keys(BeardLib.managers.MapFramework._loaded_instances)

    local name_item = self:GetItem("InstanceID")
    local new_name = name_item:Value()
    local title = "Instance ID"
    if data.id ~= new_name then
        local exists = false
        for _, mod in pairs(self._parent:get_modules("instance")) do
            if mod.id == new_name then
                exists = true
            end
        end
        if exists or new_name == "" or (data.orig_id ~= new_name and instances[new_name]) then
            title = title .. "[Invalid]"
        else
            data.id = new_name
        end
    end
    name_item:SetText(title)
end

function ProjectInstanceEditor:delete()
    local id = self._data.id
    for _, mod in pairs(self._parent:get_modules("narrative")) do
        if mod.chain then
            for _, level in ipairs(mod.chain) do
                if level.level_id == id then
                    table.delete_value(mod.chain, level)
                    break
                else
                    for i, inner_level in pairs(level) do
                        if inner_level.level_id == id then
                            table.delete_value(level, inner_level)
                        end
                    end
                end
            end
        end
    end
    local path = Path:Combine(self._parent:get_dir(), self.LEVELS_DIR, self._data.orig_id or id)
    if FileIO:Exists(path) then
        FileIO:Delete(path)
    end
end