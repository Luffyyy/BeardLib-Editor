if true then
    return
end

--[[
THE MAGIC DEVELOPEMENT CLASS THAT REFRESHES!!!
This is just an example, remove the class (SomeClass) below and apply it to your own class.
Then, remove the if true then return end above.
]]

function BLE:DestroyDev()
    if SomeClassGlobal then
        local data = SomeClassGlobal:Destroy()
        SomeClassGlobal = nil
        return data
    end
    return {}
end

function BLE:CreateDev(data)
    if not SomeClassGlobal then
        SomeClassGlobal = SomeClass:new(data)
    end
end

SomeClass = SomeClass or class()
function SomeClass:init(data)
    self._menu = MenuUI:new({})
end

--DEV ONLY--
function SomeClass:Destroy()
    local enabled = self._menu:Enabled()
    self._menu:Destroy()
    return {enabled = enabled}
end