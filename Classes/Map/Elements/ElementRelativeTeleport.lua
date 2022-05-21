EditorRelativeTeleport = EditorRelativeTeleport or class(MissionScriptEditor)
function EditorRelativeTeleport:create_element()
	self.super.create_element(self)
	self._element.class = "ElementRelativeTeleport"
	self._element.values.target = {}
end

function EditorRelativeTeleport:_build_panel()
	self:_create_panel()

	self:BuildElementsManage("target", nil, {"ElementRelativeTeleportTarget"}, nil, {
		single_select = true
	})
end

function EditorRelativeTeleport:update_selected(t, dt)
    if not alive(self._unit) then
        return
    end

	if self._element.values.target then
        for _, id in ipairs(self._element.values.target) do
            local unit = self:GetPart('mission'):get_element_unit(id)
			local r, g, b = unit:mission_element():get_link_color()
            if unit then
                self:draw_link(
                    {
                        g = g,
                        b = b,
                        r = r,
                        from_unit = self._unit,
                        to_unit = unit
                    }
                )
			else
				table.delete(self._element.values.target, id)
            end
        end
    end
end

function EditorRelativeTeleport:link_managed(unit)
	if alive(unit) and unit:mission_element() and unit:mission_element().element.class == "ElementRelativeTeleportTarget" then
		self:AddOrRemoveManaged("target", {element = unit:mission_element().element})
		return
	end
end
