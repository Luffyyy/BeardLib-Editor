SelectSearchList = SelectSearchList or class(SearchList)
SelectSearchList.PER_PAGE = 100
function SelectSearchList:init(parent)
    SelectSearchList.super.init(self, parent)
    local tb = self._options:GetToolbar()
    tb:tb_imgbtn("SelectAll", ClassClbk(self, "select_all_visible"), nil, BLE.Utils.EditorIcons.select)
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

------------------------------------- Units -------------------------------------------

UnitSelectList = UnitSelectList or class(SelectSearchList)
function UnitSelectList:do_search_list()
    for _, unit in pairs(World:find_units_quick("disabled", "all")) do
        local ud = unit:unit_data()
        if ud and self:check_search(ud.name_id, unit) then
            self:insert_item_to_filtered_list({name = ud.name_id, object = unit})
        end
    end
end

function UnitSelectList:check_search(check, unit)
    local ud = unit:unit_data()
    if not ud then
        return false
    end
    local ok = ud.name and not ud.instance and (unit:enabled() or (ud.name_id and ud.continent))
    return ok and UnitSelectList.super.check_search(self, check)
end

function UnitSelectList:on_click_item(item)
    managers.editor:select_unit(item.object, self._select_all)
end

function UnitSelectList:add_object(unit)
    local ud = unit:unit_data()
    if ud and self:check_search(ud.name, unit) then
        self:insert_item_to_filtered_list({name = ud.name_id, object = unit})
        self:sort_items()
        self:do_show()
    end
end
------------------------------------- Elements -------------------------------------------

ElementSelectList = ElementSelectList or class(SelectSearchList)

function ElementSelectList:do_search_list()
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for _, element in pairs(tbl.elements) do
                    local name = tostring(element.editor_name) .. " [" .. tostring(element.id) .."]"
                    if self:check_search(name) then
                        self:insert_item_to_filtered_list({name = name, object = element.id, element = element})
                    end
                end
            end
        end
    end
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

function ElementSelectList:add_object(element)
    local name = tostring(element.editor_name) .. " [" .. tostring(element.id) .."]"
    if self:check_search(name) then
        self:insert_item_to_filtered_list({name = name, object = element.id, element = element})
        self:sort_items()
        self:do_show()
    end
end
------------------------------------- Instances -------------------------------------------

InstanceSelectList = InstanceSelectList or class(SelectSearchList)

function InstanceSelectList:do_search_list()
    for _, name in pairs(managers.world_instance:instance_names()) do
        if self:check_search(name) then
            local folder = managers.world_instance:get_instance_data_by_name(name).folder:gsub("levels/instances/", "")
            self:insert_item_to_filtered_list({name = name.. "("..folder..")", object = name})
        end
    end
end

function InstanceSelectList:on_click_item(item)
    managers.editor:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(item.object)), self._select_all)
end

function InstanceSelectList:add_object(name)
    local folder = managers.world_instance:get_instance_data_by_name(name).folder:gsub("levels/instances/", "")
    if self:check_search(name) then
        self:insert_item_to_filtered_list({name = name.. "("..folder..")", object = name})
        self:sort_items()
        self:do_show()
    end
end