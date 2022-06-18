ToolsMenu = ToolsMenu or class(EditorPart)
function ToolsMenu:init(parent, menu)
    ToolsMenu.super.init(self, parent, menu, "Tools", {make_tabs = ClassClbk(self, "make_tabs")})
    self.tools = {
        general = GeneralToolEditor:new(self),
        environment = EnvironmentToolEditor:new(self),
        debug = DebugToolEditor:new(self),
    }
    self._combat_debug = HUDCombatDebug:new()
end

function ToolsMenu:get_tool(name)
    return self.tools[name]
end

function ToolsMenu:make_tabs(tabs)
    local tools = {"general", "environment", "debug"}
    self._current_tool = self._current_tool or "general"
    for i, name in pairs(tools) do
        self._tabs:s_btn(name, ClassClbk(self, "open_tab", name:lower()), {
            text = string.capitalize(name),
            border_bottom = i == 1
        })
    end
end

function ToolsMenu:open_tab(name, item)
    item = item or self._tabs:GetItem(name)
    self._current_tool = name
    for _, tab in pairs(self._tabs:Items()) do
        tab:SetBorder({bottom = tab.name == item.name})
    end
    for tool_name, tool in pairs(self.tools) do
        if tool.set_visible then
            tool:set_visible(name == tool_name)
        end
    end
end

function ToolsMenu:reset()
    for _, editor in pairs(self.tools) do
        if editor.reset then
            editor:reset()
        end
    end
end

function ToolsMenu:destroy()
    for _, editor in pairs(self.tools) do
        if editor.destroy then
            editor:destroy()
        end
    end

    if self._combat_debug then
        self._combat_debug:clean_up()
        self._combat_debug = nil
    end
end

function ToolsMenu:loaded_continents(continents, current_continent)
    for name, manager in pairs(self.tools) do
        if manager.build_menu then
            manager:build_menu()
        end
    end
    self.tools.general:set_visible(true)
    self._loaded = true
end

function ToolsMenu:update(t, dt)
    self.super.update(self, t, dt)
    for _, editor in pairs(self.tools) do
        if editor.update and editor:active() then
            editor:update(t, dt)
        elseif not editor._built and managers.viewport:first_active_viewport() then
            editor:build_menu()
        end
    end
end

local elements = {"ElementAreaTrigger", "ElementAreaReportTrigger", "ElementLookAtTrigger"}
function ToolsMenu:disabled_update(t, dt)
    self._combat_debug:update(t, dt)
    if self._draw_triggers then
        for _, script in pairs(managers.mission:scripts()) do
            for _, trigger in pairs(elements) do
                if script:element_group(trigger) then
                    for _, element in pairs(script:element_group(trigger)) do
                        element:debug_draw()
                    end
                end
            end
        end
    end
end

function ToolsMenu:mouse_busy()
    for _, layer in pairs(self.tools) do
        if layer.mouse_busy and layer:mouse_busy(b, x, y) then
            return true
        end
    end
end

function ToolsMenu:mouse_pressed(b, x, y)
    for _, layer in pairs(self.tools) do
        if layer.mouse_pressed and layer:mouse_pressed(b, x, y) then
            return true
        end
    end
end

function ToolsMenu:mouse_released(b, x, y)
    for _, layer in pairs(self.tools) do
        if layer.mouse_released and layer:mouse_released(b, x, y) then
            return true
        end
    end
end

function ToolsMenu:refresh()
    self.tools.general:build_menu()
end

function ToolsMenu:set_combat_debug(enabled)
    self._combat_debug:set_enabled(enabled)
end