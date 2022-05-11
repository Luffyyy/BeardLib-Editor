SelectSearchList = SelectSearchList or class(SearchList)
SelectSearchList.PER_PAGE = 100
function SelectSearchList:init(parent)
    SelectSearchList.super.init(self, parent)
    local tb = self._options:GetToolbar()
    if not self._no_select_all then
        tb:tb_imgbtn("SelectAll", ClassClbk(self, "select_all_visible"), nil, BLE.Utils.EditorIcons.select_all, {
            help = "Select all visible items (hold ctrl to select in addition to what you have selected)"
        })
    end
    if self.select_all_filtered then
        tb:tb_imgbtn("SelectFiltered", ClassClbk(self, "select_all_filtered"), nil, BLE.Utils.EditorIcons.select, {
            help = "Select all filtered items (every item from every page)"
        })
    end
end

function SelectSearchList:delete_object(object)
    local delete_item = nil
    local range_1, range_2 = self:get_page_ranges()

    for i, item in pairs(self._filtered) do
        if item.object == object then
            if i > range_1 and i <= range_2 then
                delete_item = item.gui_item
            end
            table.remove(self._filtered, i)
            break
        end
    end
    if alive(delete_item) then
        delete_item:Destroy()
        self:do_show(true)
    end
end

function SelectSearchList:set_selected_objects()
    if not self._filtered then
        return
    end
    local selected_units = self:selected_units()
    for _, item in pairs(self._filtered) do
        local gui_item = item.gui_item
        if alive(gui_item) then
            local selected = table.contains(selected_units, item.unit) and Color.green or self._list.border_color
            if selected ~= gui_item.border_color then
                gui_item:SetBorder({color = selected})
            end
        end
    end
end

function SearchList:get_border_color(item)
    return table.contains(self:selected_units(), item.unit) and Color.green or nil
end

function SelectSearchList:select_all_visible()
    self._select_all = true
    if not ctrl() then
        self:GetPart("static"):reset_selected_units()
    end
    for _, btn in pairs(self._list:Items()) do
        btn:RunCallback()
    end
    self._select_all = nil
end

function SelectSearchList:add_object(object)
    if self:insert_object(object) then
        self:sort_items()
        self:do_show()
    end
end
------------------------------------- Units -------------------------------------------

UnitSelectList = UnitSelectList or class(SelectSearchList)

function UnitSelectList:init(parent)
    UnitSelectList.super.init(self, parent)
    self._filtered_continents = {}

    self._filter = self._options:button("FilterContinents", ClassClbk(self, "filter_continents"), {help = "Select what continents to search for units from"})
    self._filter:lbl("Count", {text = "0/0", offset = 0, size_by_text = true, position = "RightTop"})
end

function UnitSelectList:do_search_list()
    local continents = #managers.editor._continents
    local used_continents = continents - #self._filtered_continents
    self._filter:GetItem("Count"):SetText(used_continents.."/"..continents)

    for _, unit in pairs(World:find_units_quick("disabled", "all")) do
        self:insert_object(unit)
    end
end

function UnitSelectList:insert_object(unit)
    local ud = unit:unit_data()
    if not ud or (ud.continent and table.contains(self._filtered_continents, ud.continent)) then
        return false
    end

    if ud.name and not ud.instance and (unit:enabled() or (ud.name_id and ud.continent)) then
        local text = ud.name_id .. " [" .. ud.unit_id .."]"
        if self:check_search(text, unit) then
            
            self:insert_item_to_filtered_list({name = text, object = unit, unit = unit})
            return true
        end
    end
    return false
end

function UnitSelectList:on_click_item(item)
    managers.editor:select_unit(item.object, self._select_all)
end

function UnitSelectList:select_all_filtered()
    local static = self:GetPart("static")
    local selected_units = ctrl() and static._selected_units or {}

    for _, item in pairs(self._filtered) do
        if not table.contains(selected_units, item.object) then
            table.insert(selected_units, item.object)
        end
    end
    static:set_selected_units(selected_units)
end

function UnitSelectList:filter_continents()
    local continents = clone(managers.editor._continents)
    for _, continent in ipairs(self._filtered_continents) do
        table.delete(continents, continent)
    end

    BLE.SelectDialog:Show({
        selected_list = continents,
        list = managers.editor._continents,
        callback = function(list) 
            local new_continent = {}
            for _, continent in ipairs(managers.editor._continents) do
                if not table.contains(list, continent) then
                    table.insert(new_continent, continent)
                end
            end
            self._filtered_continents = new_continent 
            self:do_search()
        end
    })
end
------------------------------------- Elements -------------------------------------------

ElementSelectList = ElementSelectList or class(SelectSearchList)

function ElementSelectList:init(parent)
    ElementSelectList.super.init(self, parent)
    self._filtered_scripts = {}

    self._filter = self._options:button("FilterScripts", ClassClbk(self, "filter_scripts"), {help = "Select what scripts to search for elements from"})
    self._filter:lbl("Count", {text = "0/0", offset = 0, size_by_text = true, position = "RightTop"})
end

function ElementSelectList:do_search_list()
    local scripts = table.map_keys(managers.mission._scripts)
    local used_scripts = #scripts - #self._filtered_scripts
    self._filter:GetItem("Count"):SetText(used_scripts.."/"..#scripts)

    
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for _, element in pairs(tbl.elements) do
                    self:insert_object(element)
                end
            end
        end
    end
end

function ElementSelectList:insert_object(element)
    if table.contains(self._filtered_scripts, element.script) then
        return false
    end

    local mission = self:GetPart("mission")
    local name = tostring(element.editor_name) .. " - " .. tostring(element.class:gsub("Element", "")) .. " [" .. tostring(element.id) .. "]"
    if self:check_search(name) then
        self:insert_item_to_filtered_list({name = name, object = element.id, element = element, unit = mission:get_element_unit(element.id)})
        return true
    end
    return false
end

function ElementSelectList:on_click_item(item)
    managers.editor:select_element(item.element, self._select_all)
end

function ElementSelectList:select_all_filtered()
    self:GetPart("static"):reset_selected_units()
    for _, item in pairs(self._filtered) do
        managers.editor:select_element(item.element, true)
    end
end

function ElementSelectList:create_list_item(item)
    return self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {
        border_left = true,
        offset = {1, 4}
    })
end

function ElementSelectList:filter_scripts()
    local all_scripts = table.map_keys(managers.mission._scripts)
    local scripts = clone(all_scripts)
    for _, script in ipairs(self._filtered_scripts) do
        table.delete(scripts, script)
    end

    BLE.SelectDialog:Show({
        selected_list = scripts,
        list = all_scripts,
        callback = function(list) 
            local new_scripts = {}
            for _, script in ipairs(all_scripts) do
                if not table.contains(list, script) then
                    table.insert(new_scripts, script)
                end
            end
            self._filtered_scripts = new_scripts 
            self:do_search()
        end
    })
end

------------------------------------- Instances -------------------------------------------

InstanceSelectList = InstanceSelectList or class(SelectSearchList)

function InstanceSelectList:do_search_list()
    for _, name in pairs(managers.world_instance:instance_names()) do
        self:insert_object(name)
    end
end

function InstanceSelectList:on_click_item(item)
    managers.editor:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(item.object), {instance = true}), self._select_all)
end

function InstanceSelectList:select_all_filtered()
    self:GetPart("static"):reset_selected_units()
    for _, item in pairs(self._filtered) do
        managers.editor:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(item.object), {instance = true}), true)
    end
end

function InstanceSelectList:insert_object(name)
    if self:check_search(name) then
        local folder = managers.world_instance:get_instance_data_by_name(name).folder:gsub("levels/instances/", "")
        self:insert_item_to_filtered_list({name = name.. "("..folder..")", object = name})
        return true
    end
    return false
end

function InstanceSelectList:set_selected_objects()
    if not self._filtered then
        return
    end

    local selected_instances = {}
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:fake() and unit:unit_data().instance then
            table.insert(selected_instances, unit:object().name)
        end
    end

    for _, item in pairs(self._filtered) do
        local gui_item = item.gui_item
        if alive(gui_item) then
            local selected = table.contains(selected_instances, item.object) and Color.green or self._list.border_color
            if selected ~= gui_item.border_color then
                gui_item:SetBorder({color = selected})
            end
        end
    end
end

function InstanceSelectList:get_border_color(item)
    local selected_instances = {}
    for _, unit in pairs(self:selected_units()) do
        if alive(unit) and unit:fake() and unit:unit_data().instance then
            table.insert(selected_instances, unit:object().name)
        end
    end

    return table.contains(selected_instances, item.object) and Color.green or nil
end

------------------------------------- Groups -------------------------------------------

GroupSelectList = GroupSelectList or class(SelectSearchList)

function GroupSelectList:init(parent)
    self._no_select_all = true
    GroupSelectList.super.init(self, parent)
end

function GroupSelectList:set_selected_objects()
    if not self._filtered then
        return
    end
    local selected_group = self:GetPart("static")._selected_group
    for _, item in pairs(self._filtered) do
        local gui_item = item.gui_item
        if alive(gui_item) then
            local selected = selected_group and (selected_group == item.group and Color.green) or self._list.border_color
            if selected ~= gui_item.border_color then
                gui_item:SetBorder({color = selected})
            end
        end
    end
end

function GroupSelectList:do_search_list()
    local continents = managers.worlddefinition._continent_definitions
    for _, continent in pairs(managers.editor._continents) do
        if continents[continent].editor_groups then
            for _, editor_group in pairs(continents[continent].editor_groups) do
                if editor_group.units then
                    self:insert_object(editor_group)
                end
            end
        end
    end
end

function GroupSelectList:insert_object(editor_group)
    local name = tostring(editor_group.name) .. " - " .. tostring(#editor_group.units)
    if self:check_search(name) then
        self:insert_item_to_filtered_list({name = name, group = editor_group})
        return true
    end
    return false
end

function GroupSelectList:on_click_item(item)
    self:GetPart("static"):select_group(item.group)
end