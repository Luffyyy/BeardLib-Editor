SelectSearchList = SelectSearchList or class(SearchList)
SelectSearchList.PER_PAGE = 100
function SelectSearchList:init(parent)
    SelectSearchList.super.init(self, parent)
    local tb = self._options:GetToolbar()
    tb:tb_imgbtn("SelectAll", ClassClbk(self, "select_all_visible"), nil, BLE.Utils.EditorIcons.select, {
        help = "Select all visible items (hold ctrl to select in addition to what you have selected)"
    })
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
function UnitSelectList:do_search_list()
    for _, unit in pairs(World:find_units_quick("disabled", "all")) do
        self:insert_object(unit)
    end
end

function UnitSelectList:insert_object(unit)
    local ud = unit:unit_data()
    if not ud then
        return false
    end

    local text = ud.name_id .. " [" .. ud.unit_id .."]"

    if ud.name and not ud.instance and (unit:enabled() or (ud.name_id and ud.continent)) then
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
------------------------------------- Elements -------------------------------------------

ElementSelectList = ElementSelectList or class(SelectSearchList)

function ElementSelectList:do_search_list()
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

function ElementSelectList:create_list_item(item)
    return self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {
        border_left = true,
        offset = {1, 4}
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
        if unit:fake() and unit:unit_data().instance then
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
        if unit:fake() and unit:unit_data().instance then
            table.insert(selected_instances, unit:object().name)
        end
    end

    return table.contains(selected_instances, item.object) and Color.green or nil
end