SaveOptions = SaveOptions or class()

function SaveOptions:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "save_options",
        text = "Save",
        help = "",
    })

    self:CreateItems()
end

function SaveOptions:CreateItems()
    local level =  "/" .. (Global.game_settings.level_id or "")
    self._menu:TextBox({
        name = "savepath",
        text = "Save path: ",
        value = BeardLib.MapsPath .. level,
        help = "",
    })
    self._menu:Divider({
        name = "continents_div",
        size = 30,
        text = "Continents",
    })
    self._menu:ComboBox({
        name = "continents_filetype",
        text = "Type: ",
        value = 1,
        items = {"custom_xml", "generic_xml", "json"},
        help = "",
    })
    self._menu:Button({
        name = "continents_savebtn",
        text = "Save",
        help = "",
        callback = callback(self, self, "save_continents"),
    })
    self._menu:Divider({
        name = "missions_div",
        size = 30,
        text = "Missions",
    })
    self._menu:ComboBox({
        name = "missions_filetype",
        text = "Type: ",
        value = 2,
        items = {"custom_xml", "generic_xml", "json"},
        help = "",
    })
    self._menu:Button({
        name = "missions_savebtn",
        text = "Save",
        help = "",
        callback = callback(self, self, "save_missions"),
    })
    self._menu:Divider({
        name = "nav_data_div",
        size = 30,
        text = "Navigation",
    })
    self._menu:Button({
        name = "build_nav",
        text = "Build navdata",
        help = "",
        callback = callback(self, self, "_build_nav_segments"),
    })
    self._menu:Button({
        name = "save_nav_data",
        text = "Save nav data",
        help = "",
        callback = callback(self, self, "save_nav_data"),
    })
    self._menu:Button({
        name = "save_cover_data",
        text = "Save cover data",
        help = "",
        callback = callback(self, self, "save_cover_data"),
    })
end

function SaveOptions:save_continents(menu)
	local item = menu:GetItem("continents_filetype")
	local type = item.items[item.value]
	local path = menu:GetItem("savepath").value:gsub("\\" , "/")
	local world_def = managers.worlddefinition
    log(path)
	if not file.DirectoryExists( path ) then
        os.execute("mkdir \"" .. path .. "\"")
    end
    if file.DirectoryExists( path ) then
		for continent_name, data in pairs(world_def._continent_definitions) do
			if menu:GetItem("continent_" .. continent_name).value then
				self:save_continent(continent_name, data, type, path)
			end
		end
	else
		BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
	end
end

function SaveOptions:save_continent(continent, data, type, path)
    local sub_path = path .. "/" .. continent .. "/"
    if not file.DirectoryExists(sub_path) then
        os.execute("mkdir \"" .. sub_path .. "\"")
    end

	local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(data, type)
	local continent_file = io.open(sub_path .. "/" .. continent .. ".continent." .. type, "w+")
	_G.BeardLibEditor:log("Saving continent: " .. continent .. " as a " .. type .. " in " .. path)
	if continent_file then
	   	continent_file:write(new_data)
	    continent_file:close()
	else
		_G.BeardLibEditor:log("Failed to save continent: " .. continent .. " path: " .. path)
	end
end

function SaveOptions:save_missions(menu)
	local item = menu:GetItem("missions_filetype")
	local type = item.items[item.value]
	local path = menu:GetItem("savepath").value:gsub("\\" , "/")
    if not file.DirectoryExists( path ) then
        os.execute("mkdir \"" .. path .. "\"")
    end
	if file.DirectoryExists( path ) then
		for mission_name, data in pairs(managers.mission._missions) do
			if menu:GetItem("mission_" .. mission_name).value then
				self:save_mission_file(mission_name, data, type, path)
			end
		end
	else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
	end
end

function SaveOptions:save_mission_file(mission, data, type, path)
    local sub_path = path .. "/" .. mission .. "/"
    if not file.DirectoryExists(sub_path) then
        os.execute("mkdir \"" .. sub_path .. "\"")
    end

	local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(data, type)
	local mission_file = io.open(sub_path .. "/" .. mission .. ".mission." .. type, "w+")
	_G.BeardLib:log("Saving mission: " .. mission .. " as a " .. type .. " in " .. path)
	if mission_file then
		mission_file:write(new_data)
		mission_file:close()
	else
		_G.BeardLib:log("Failed to save mission: " .. mission .. " path: " .. path)
	end
end

function SaveOptions:save_nav_data(menu)
    local path = menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end
    if file.DirectoryExists( path ) then
        if managers.navigation:get_save_data() then
            local file = io.open(path .. "/nav_manager_data.nav_data", "w+")
            file:write(managers.navigation._load_data)
            file:close()
        else
            BeardLibEditor:log("Save data is not ready!")
        end
    else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
    end
end

function SaveOptions:save_cover_data(menu)
    local path = menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end
    if file.DirectoryExists( path ) then
        local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))
        local covers = {
            positions = {},
            rotations = {}
        }
        for i, unit in pairs(all_cover_units) do
            local pos = Vector3()
            unit:m_position(pos)
            mvector3.set_static(pos, math.round(pos.x), math.round(pos.y), math.round(pos.z))
            table.insert(covers.positions, pos)
            local rot = unit:rotation()
            table.insert(covers.rotations, math.round(rot:yaw()))
        end
        local file = io.open(path .. "/cover_data.cover_data", "w+")
        local new_data = _G.BeardLibEditor.managers.ScriptDataConveter:GetTypeDataTo(covers, "custom_xml")
        file:write(new_data)
        file:close()
    else
        BeardLibEditor:log("Directory doesn't exists(Failed to create directory?)")
    end
end

function SaveOptions:_build_nav_segments()
    QuickMenu:new( "Info", "This will disable the player and AI and build the nav data proceed?",
    {[1] = {text = "Yes", callback = function()
        local settings = {}
        local units = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                table.insert(units, unit)
            end
        end
        for _, unit in ipairs(units) do
            local ray = World:raycast(unit:position() + Vector3(0, 0, 50), unit:position() - Vector3(0, 0, 150), nil, managers.slot:get_mask("all"))
            if ray and ray.position then
                table.insert(settings, {
                    position = unit:position(),
                    id = unit:editor_id(),
                    color = Color(),
                    location_id = unit:ai_editor_data().location_id
                })
            end
        end
        if #settings > 0 then
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:in_slot(managers.slot:get_mask("persons"))   then
                    unit:set_enabled(false)
                    if unit:brain() then
                       unit:brain()._current_logic.update = nil
                    end
                    if self._parent.managers.UnitEditor._disabled_units then
                        table.insert(self._parent.managers.UnitEditor._disabled_units, unit)
                    end
                    for _, extension in pairs(unit:extensions()) do
                        unit:set_extension_update_enabled(Idstring(extension), false)
                    end
                end
            end
            managers.navigation:clear()
            managers.navigation:build_nav_segments(settings, callback(self, self, "_build_visibility_graph"))
        else
            BeardLibEditor:log("No nav surface found.")
        end
    end
    },[2] = {text = "No", is_cancel_button = true}}, true)
end

function SaveOptions:_build_visibility_graph()
    local all_visible = true
    local exclude, include
    if not all_visible then
        exclude = {}
        include = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                exclude[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_exlude_filter
                include[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_include_filter
            end
        end
    end
    local ray_lenght = 150
    managers.navigation:build_visibility_graph(callback(self, self, "_finish_visibility_graph"), all_visible, exclude, include, ray_lenght)
end

function SaveOptions:_finish_visibility_graph(menu, item)
    managers.groupai:set_state("none")
end
