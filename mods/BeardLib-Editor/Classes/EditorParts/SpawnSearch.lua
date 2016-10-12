SpawnSearch = SpawnSearch or class()

function SpawnSearch:init(parent, menu)
    self._parent = parent
    self._tabs = menu:NewMenu({
        name = "spawnsearch_tabs",
        w = 220,
        h = 20,
        offset = 0,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,
        items_size = 14,
        size_by_text = true,
        row_max = 1,
        visible = true,
    })
    self._menu = menu:NewMenu({
        name = "find",
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.4,
        w = 220,
        h = 250,
        visible = true,
    })
    self._menu:Panel():set_world_bottom(self._menu:Panel():parent():world_bottom())
    self._menu:Panel():set_world_right(self._menu:Panel():parent():world_right())
    self._tabs:Panel():set_leftbottom(self._menu:Panel():lefttop())
    self._tabs:ContextMenu({
        name = "units",
        text = "Units",
        label = "main",
        items = {
            {text = "New", callback = callback(self, self, "browse")},
            {text = "Select", callback = callback(self, self, "load_all_units")}
        }
    })
    self._tabs:ContextMenu({
        name = "mission_elements",
        text = "Mission elements",
        label = "main",
        items = {
            {text = "New", callback = callback(self, self, "show_elements_list")},
            {text = "Select", callback = callback(self, self, "load_all_mission_elements")}
        }
    })
    self._tabs:Button({
        name = "prefabs",
        text = "Prefabs",
        label = "main",
        callback = callback(self, self, "load_prefabs")
    })
    self:browse()
end


function SpawnSearch:load_prefabs()
    self:clear()
    for _, prefab in pairs(BeardLibEditor.Options._storage.Prefabs) do
        if type(prefab) == "table" and type(prefab.value) == "table" then
            self._menu:Button({
                name = prefab.value.name,
                text = prefab.value.name,
                callback = callback(self, self, "spawn_prefab", prefab.value.units),
                label = "select_buttons"
            })
        end
    end
end

function SpawnSearch:spawn_prefab(prefab)
    self._parent.managers.UnitEditor._selected_units = {}
    for _, unit in pairs(prefab) do
        self._parent:SpawnUnit(unit.name, nil, true)
    end
    local reference = self._parent.managers.UnitEditor._selected_units[1]
    for k, unit in pairs(self._parent.managers.UnitEditor._selected_units) do
        if unit ~= reference then
            unit:unit_data().position = prefab[k].position
            local pos = prefab[1].position
            local rot = prefab[1].rotation
            unit:unit_data().local_pos = prefab[k].position - pos 
            unit:unit_data().local_rot = rot:inverse() * unit:rotation()
        end
    end
    self._parent:set_unit_positions(reference:position())     
end
function SpawnSearch:clear()
    self._menu:ClearItems("temp1")
    self._menu:ClearItems("temp2")
    self._menu:ClearItems("select_buttons")
end
function SpawnSearch:browse()
    self._menu:ClearItems("temp1")
    self._menu:ClearItems("select_buttons")
    self._menu:ClearItems("search")
    self._current_menu = nil
    self.current_dir = self.current_dir or ""
    local dir_split = string.split(self.current_dir, "/")

    local dir_tbl = BeardLibEditor.DBEntries
    for _, part in pairs(dir_split) do
        dir_tbl = dir_tbl[part]
    end
    local show_not_loaded = self._menu:GetItem("show_not_loaded") or self._menu:Toggle({
        name = "show_not_loaded",
        text = "Show not loaded units",
        value = false,
        callback = callback(self, self, "browse"),
        label = "temp2"
    })    
    show_not_loaded:SetCallback(callback(self, self, "browse"))
    local search_btn = self._menu:GetItem("search_btn") or self._menu:Button({
        name = "search_btn",
        text = "Search",
        callback = callback(self, self, "file_search"),
        label = "temp2"
    })        
    self._menu:Button({
        name = "uplevel_btn",
        text = "^ ( " .. (self.current_dir or self.custom_dir) .. " )",
        callback = callback(self, self, "folder_back"),
        label = "temp1"
    })        
    for key, data in pairs(dir_tbl) do
        if tonumber(key) ~= nil then
            if data.file_type == "unit" and (PackageManager:has(Idstring("unit"), Idstring(data.path)) or show_not_loaded.value) then
                self._menu:Button({
                    name = data.name,
                    text = data.name .. "." .. data.file_type,
                    label = "temp1",
                    path = data.path,
                    color = PackageManager:has(Idstring("unit"), Idstring(data.path)) and Color.green or Color.red,
                    callback = callback(self, self, "file_click"),
                })
            end
        else
            self._menu:Button({
                name = key,
                text = key,
                label = "temp1",
                callback = callback(self, self, "folder_click"),
            })
        end
    end
end

function SpawnSearch:refresh_search()
    if self._current_menu then
        self._current_menu(self._menu)
    end
end

function SpawnSearch:file_search(menu, item)
    self._is_searching = false
    managers.system_menu:show_keyboard_input({
        text = "",
        title = "Search:",
        callback_func = callback(self, SpawnSearch, "_search", menu),
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
function SpawnSearch:_search(menu, success, search)
    if not success then
        return
    end    
    self:search(menu, search)
end
function SpawnSearch:search(menu, search)
    search = type(search) == "string" and search or self._last_search
    if not search or search == "" then
        return
    end     
    self._last_search = search
    self._current_menu = callback(self, self, "search", menu)
    self._menu:ClearItems("temp1")
    self._is_searching = true
    
    menu:GetItem("show_not_loaded"):SetCallback(self._current_menu)

    menu:Button({
        name = "uplevel_btn",
        text = "Back",
        callback = callback(self, self, "folder_back"),
        label = "temp1"
    })
    for _, unit_path in pairs(BeardLibEditor.DBPaths["unit"]) do
        local split = string.split(unit_path, "/")
        local unit = split[#split]
        if unit:match(search) and (PackageManager:has(Idstring("unit"), Idstring(unit_path)) or menu:GetItem("show_not_loaded").value) then
            menu:Button({
                name = unit,
                text = unit,   
                path = unit_path,
                label = "temp1",
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
    self:clear()
    self._current_menu = callback(self, self, "load_all_mission_elements", self._menu)
    local searchbox
    if not self._menu:GetItem("searchbox") then
        searchbox = self._menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "load_all_mission_elements"),
            label = "search"
        })
    else
        searchbox = self._menu:GetItem("searchbox")
    end
    searchbox:SetCallback(callback(self, self, "load_all_mission_elements"))
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do
                    --No limit = Slow scroll.
                    if #self._menu._items < 200 then
                        if (not searchbox.value or searchbox.value == "" or string.match(element.editor_name, searchbox.value) or string.match(element.id, searchbox.value)) or string.match(element.class, searchbox.value) then
                            local _element = managers.mission:get_mission_element(element.id)
                            self._menu:Button({
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
    self:clear()
    self._current_menu = nil
    local searchbox
    if not self._menu:GetItem("searchbox") then
        searchbox = self._menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "show_elements_list"),
            label = "search",
        })
    else
        searchbox = self._menu:GetItem("searchbox")
    end
    searchbox:SetCallback(callback(self, self, "show_elements_list"))
    for k, element in pairs(ElementEditor._mission_elements) do
        if (not searchbox.value or searchbox.value == "" or string.match(element, searchbox.value)) then
            self._menu:Button({
                name = element,
                text = element,
                label = "select_buttons",
                callback = callback(self._parent, self._parent, "add_element", element)
            })
        end
    end
end
function SpawnSearch:load_all_units(menu, item)
    self:clear()
    self._current_menu = callback(self, self, "load_all_units", self._menu)
    local searchbox
    if not self._menu:GetItem("searchbox") then
        searchbox = self._menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "load_all_units"),
            label = "search"
        })       
    else
        searchbox = self._menu:GetItem("searchbox")
    end
    searchbox:SetCallback(callback(self, self, "load_all_units"))
    for k, unit in pairs(World:find_units_quick("all")) do
        if #self._menu._items < 200 then
            if unit:unit_data() and (unit:unit_data().name_id ~= "none" and not searchbox.value or searchbox.value == "" or string.match(unit:unit_data().name_id, searchbox.value or "") or string.match(unit:unit_data().unit_id, searchbox.value or "")) then
                self._menu:Button({
                    name = tostring(unit:unit_data().name_id),
                    text = tostring(unit:unit_data().name_id) .. " [" .. (unit:unit_data().unit_id or "") .."]",
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
			self._parent:SpawnUnit(unit_path)
  		end
  		},[2] = {text = "No", is_cancel_button = true}}, true)
	else
		self._parent:SpawnUnit(unit_path)
	end
end
