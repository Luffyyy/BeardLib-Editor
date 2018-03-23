if BLE:RunningFix() then
    Hooks:PreHook(CoreUnitDamage, "save", "BeardLibPreUnitDamageSave", function(self, data)
        if self._state then
            for element_name, data in pairs(self._state) do
                if element_name == "body" then
                    local new_data = {}
                    local i = 0
                    for body_id, cat_data in pairs(data) do
                        local body = self._unit:body(body_id)
                        if body and not body:has_ray_type(Idstring("editor")) then
                            new_data[i] = cat_data
                            i = i + 1
                        end
                    end
                    self._state[element_name] = new_data
                end
            end
        end
    end)
end