SelectSearchList = SelectSearchList or class(SearchList)
SelectSearchList.PER_PAGE = 100

------------------------------------- Units -------------------------------------------

UnitSelectList = UnitSelectList or class(SelectSearchList)
function UnitSelectList:do_search_list()
    for _, unit in pairs(World:find_units_quick("disabled", "all")) do
        local ud = unit:unit_data()
        if ud and ud.name and not ud.instance then
            if unit:enabled() or (ud.name_id and ud.continent) then
                if self:check_search(ud.name) then
                    self:insert_item_to_filtered_list({name = ud.name_id, id = unit})
                end
            end
        end
    end
end

function UnitSelectList:on_click_item(item)
    managers.editor:select_unit(item.id, ctrl())
end

function UnitSelectList:create_list_item(item)
    local unit = item.id
    local selected_units = self:GetPart("static"):selected_units()
    self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {
        border_left = true,
        border_color = table.contains(selected_units, unit) and Color.green or (not unit:enabled() and Color(0.5, 0.5, 0.5)) or nil,
        offset = {1, 4}
    })
end

ElementSelectList = ElementSelectList or class(SelectSearchList)

function ElementSelectList:do_search_list()
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for _, element in pairs(tbl.elements) do
                    local name = tostring(element.editor_name) .. " [" .. tostring(element.id) .."]"
                    if self:check_search(name) then
                        self:insert_item_to_filtered_list({name = name, id = element})
                    end
                end
            end
        end
    end
end

------------------------------------- Elements -------------------------------------------

function ElementSelectList:on_click_item(item)
    managers.editor:select_element(item.id, true)
end

function ElementSelectList:create_list_item(item)
    self._list:button(self:friendly_item_name(item), ClassClbk(self, "on_click_item", item), {
        border_left = true,
        offset = {1, 4}
    })
end

------------------------------------- Instances -------------------------------------------

InstanceSelectList = InstanceSelectList or class(SelectSearchList)

function InstanceSelectList:do_search_list()
    for _, name in pairs(managers.world_instance:instance_names()) do
        if self:check_search(name) then
            self:insert_item_to_filtered_list({name = name})
        end
    end
end

function InstanceSelectList:on_click_item(item)
    managers.editor:select_unit(FakeObject:new(managers.world_instance:get_instance_data_by_name(item.name)), ctrl())
end