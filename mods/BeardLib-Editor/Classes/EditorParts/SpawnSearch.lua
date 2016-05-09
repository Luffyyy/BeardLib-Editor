SpawnSearch = SpawnSearch or class()

function SpawnSearch:init(parent, menu)
    self._parent = parent

    self._menu = menu:NewMenu({
        name = "find",
        text = "Find",
        help = "",
    })

    self:CreateItems()
end

function SpawnSearch:CreateItems()
    self._menu:ClearItems()
    self._menu:Button({
        name = "units_browser_button",
        text = "Add Unit..",
        label = "main",
        callback = callback(self, self, "browse")
    })
    self._menu:Button({
        name = "elements_list_button",
        text = "Add Mission Element..",
        label = "main",
        callback = callback(self, self, "show_elements_list")
    })
    self._menu:Button({
        name = "all_mission_elements",
        text = "Mission Elements",
        label = "main",
        callback = callback(self, self, "load_all_mission_elements")
    })
    self._menu:Button({
        name = "all_units",
        text = "Units",
        label = "main",
        callback = callback(self, self, "load_all_units")
    })
end


function SpawnSearch:browse()
    self._menu:ClearItems()
    self.current_dir = self.current_dir or ""
    local dir_split = string.split(self.current_dir, "/")

    local dir_tbl = BeardLibEditor.DBEntries
    for _, part in pairs(dir_split) do
        dir_tbl = dir_tbl[part]
    end

    BeardLibEditor:log(self.current_dir)
    self._menu:Button({
        name = "back_button",
        text = "Back",
        callback = callback(self, self, "CreateItems")
    })
    self._menu:Button({
        name = "uplevel_btn",
        text = "^ ( " .. (self.current_dir or self.custom_dir) .. " )",
        callback = callback(self, self, "folder_back"),
    })
    self._menu:Button({
        name = "search_btn",
        text = "Search",
        callback = callback(self, self, "file_search"),
    })    
    for key, data in pairs(dir_tbl) do
        if tonumber(key) ~= nil then
            if data.file_type == "unit" then
                self._menu:Button({
                    name = data.name,
                    text = data.name .. "." .. data.file_type,
                    label = "temp",
                    path = data.path,
                    color = PackageManager:has(Idstring("unit"), Idstring(data.path)) and Color.green or Color.red,
                    callback = callback(self, self, "file_click"),
                })
            end
        else
            self._menu:Button({
                name = key,
                text = key,
                label = "temp",
                callback = callback(self, self, "folder_click"),
            })
        end
    end
end


function SpawnSearch:file_search(menu, item)
    self._is_searching = false
    managers.system_menu:show_keyboard_input({
        text = "",
        title = "Search:",
        callback_func = callback(self, self, "search"),
    })
end

function SpawnSearch:folder_back(menu, item)
    if self._is_searching then
        self._is_searching = false
        self:browse()
    else
        local str = string.split(self.current_dir, "/")
        table.remove(str)
        self.current_dir = table.concat(str, "/")
        self:browse()
    end
end
function SpawnSearch:search(success, search)
    if not success then
        return
    end
    if not self._is_searching then
        self._menu:ClearItems("temp")
        self._is_searching = true
    end
    for _, unit_path in pairs(BeardLibEditor.DBPaths["unit"]) do
        local split = string.split(unit_path, "/")
        local unit = split[#split]
        if unit:match(search) then
            self._menu:Button({
                name = unit,
                text = unit,   
                path = unit_path,
                label = "temp",
                color = PackageManager:has(Idstring("unit"), Idstring(unit_path)) and Color.green or Color.red,
                callback = callback(self, self, "file_click"),
            })
        end
    end
end

function SpawnSearch:folder_click(menu, item)
    self.current_dir = self.current_dir .. "/" .. item.text
    self:browse()
    local after_folder_click = item.parent.after_folder_click
    if after_folder_click then
        after_folder_click()
    end
end

function SpawnSearch:load_all_mission_elements(menu, item)
    menu:ClearItems("main")
    menu:ClearItems("select_buttons")
    local searchbox
    if not self._menu:GetItem("searchbox") then
        menu:Button({
            name = "back_button",
            text = "Back",
            callback = callback(self, self, "CreateItems")
        })
        searchbox = menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "load_all_mission_elements")
        })
    else
        searchbox = self._menu:GetItem("searchbox")
    end
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                    --No limit = Slow scroll.
                    if #menu._items < 200 then
                        if (not searchbox.value or searchbox.value == "" or string.match(element.editor_name, searchbox.value) or string.match(element.id, searchbox.value)) or string.match(element.class, searchbox.value) then
                            local _element = managers.mission:get_mission_element(element.id)
                            menu:Button({
                                name = element.editor_name,
                                text = element.editor_name .. " [" .. element.id .."]",
                                label = "select_buttons",
                                color = _element and (_element.values.enabled and Color.green or Color.red) or nil,
                                callback = callback(self._parent, self._parent, "_select_element", element)
                            })
                        end
                    end
                end
            end
        end
    end
end
function SpawnSearch:show_elements_list(menu, item)
    menu:ClearItems("main")
    menu:ClearItems("select_buttons")
    local searchbox
    if not self._menu:GetItem("searchbox") then
        menu:Button({
            name = "back_button",
            text = "Back",
            callback = callback(self, self, "CreateItems")
        })
        searchbox = menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "show_elements_list")
        })
    else
        searchbox = self._menu:GetItem("searchbox")
    end
    for k, element in pairs(self._parent._mission_elements) do
        if (not searchbox.value or searchbox.value == "" or string.match(element, searchbox.value)) then
            menu:Button({
                name = element,
                text = element,
                label = "select_buttons",
                callback = callback(self._parent, self._parent, "add_element", element)
            })
        end
    end
end
function SpawnSearch:load_all_units(menu, item)
    menu:ClearItems("main")
    menu:ClearItems("select_buttons")
    local searchbox
    if not self._menu:GetItem("searchbox") then
        menu:Button({
            name = "back_button",
            text = "Back",
            callback = callback(self, self, "CreateItems")
        })
        searchbox = menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "load_all_units")
        })
    else
        searchbox = self._menu:GetItem("searchbox")
    end
    for k, unit in pairs(World:find_units_quick("all")) do
        if #menu._items < 200 then
            if unit:unit_data() and (unit:unit_data().name_id ~= "none" and not searchbox.value or searchbox.value == "" or string.match(unit:unit_data().name_id, searchbox.value or "") or string.match(unit:unit_data().unit_id, searchbox.value or "")) then
                menu:Button({
                    name = unit:unit_data().name_id,
                    text = unit:unit_data().name_id .. " [" .. (unit:unit_data().unit_id or "") .."]",
                    label = "select_buttons",
                    callback = callback(self._parent, self._parent, "_select_unit", unit)
                })
            end
        end
    end
end

function SpawnSearch:file_click(menu, item)
	local unit_path = item.path
	if item.color == Color.red then
		QuickMenu:new( "Warning", "Unit is not loaded, load it? (Might crash)",
		{[1] = {text = "Yes", callback = function()
			managers.dyn_resource:load(Idstring("unit"), Idstring(unit_path), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
			--self:browse(self._current_menu)
			self._parent:SpawnUnit(unit_path)
  		end
  		},[2] = {text = "No", is_cancel_button = true}}, true)
	else
		self._parent:SpawnUnit(unit_path)
	end
end
