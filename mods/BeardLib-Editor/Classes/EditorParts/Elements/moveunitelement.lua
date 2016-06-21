EditorMoveUnit = EditorMoveUnit or class(MissionScriptEditor)

function EditorMoveUnit:create_element()
    self.super.create_element(self)
    self._element.class = "ElementMoveUnit"
    self._element.values.unit_ids = {}
    self._element.values.speed = 5
    self._element.values.change_x = true
    self._element.values.change_y = true
    self._element.values.change_z = true
end
 
function EditorMoveUnit:show_all_units_dialog()
    BeardLibEditor.managers.Dialog:show({
        title = "Decide what unit this element should move",
        items = {},
        yes = "Apply",
        no = "Cancel",
        w = 600,
        h = 600,
    })
    self:load_all_units(BeardLibEditor.managers.Dialog._menu)
end

function EditorMoveUnit:update(t, dt)
    Application:draw_sphere(self._element.values.position, 10, 1, 0, 0)
end
function EditorMoveUnit:select_unit(unit, menu)
    self._element.values.unit_id = unit.unit_data and unit:unit_data().unit_id or nil
    self._element.values.to = unit.unit_data and unit:unit_data().position or Vector3(0,0,0)
    BeardLibEditor.managers.Dialog:hide()     
end

function EditorMoveUnit:_build_panel()
	self:_create_panel()
    self:_build_unit_list("unit_ids")
    self:_build_value_checkbox("change_x")
    self:_build_value_checkbox("change_y")
    self:_build_value_checkbox("change_z")
    self:_build_value_number("speed", {floats = 3, min = 0.1}, "Set the speed of unit movement")
     
end
