if true then
    return
end

--[[
THE MAGIC DEVELOPEMENT CLASS THAT REFRESHES!!!
This is just an example, remove the class (SomeClass) below and apply it to your own class.
Then, remove the if true then return end above.
]]

function BLE:DestroyDev()
    local data = BeardLib.managers.mods_menu:Destroy()
    BeardLib.managers.mods_menu = nil
    return data
end

function BLE:CreateDev(data)
    if not BeardLib.managers.mods_menu then
        BeardLib.managers.mods_menu = BeardLibModsMenu:new(data)
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