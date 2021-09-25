EditorExecuteCode = EditorExecuteCode or class(MissionScriptEditor)
function EditorExecuteCode:create_element()
    EditorExecuteCode.super.create_element(self)
    self._element.class = "ElementExecuteCode"
    self._element.values.use_path = "mod"
end

function EditorExecuteCode:_build_panel()
	self:_create_panel()
    self._class_group:info([[
Define a file that this element should execute. The file should return a function. Example: 
return function(instigator, mod)
    log("Hello instigator and mod", tostring(instigator), tostring(mod))
end
If you want to avoid executing the on_executed of this element, return false from that function.
]])
    self:FSPathCtrl("file", "lua", {
        process_path = function(path)
            local use_path = self._element.values.use_path
            if use_path == "mod" then
                return path:gsub(BLE.MapProject:current_path() or "", "")
            elseif use_path == "level" then
                return path:gsub(BLE.MapProject:current_level_path() or "", "")
            elseif use_path == "full" then
                return path
            end
        end
    })
    self:ComboCtrl("use_path", {"mod", "level", "full"})
end

EditorExecuteWithCode = EditorExecuteWithCode or class(MissionScriptEditor)
function EditorExecuteWithCode:_build_panel()
	self:_create_panel()
    self:alert("This element has been deprecated! You should use ElementExecuteCode instead!")
    self:StringCtrl("code", {min = 0, help = "The code that should run for this element and in the end supposed to return a bool that determines whether this element should execute, you should copy paste your code."})
end