EditorEnvironment = EditorEnvironment or class(MissionScriptEditor)
EditorEnvironment.ACTIONS = {"set"}
function EditorEnvironment:init(unit)
    EditorEnvironment.super.init(self, unit)
    self._actions = EditorEnvironment.ACTIONS
end
function EditorEnvironment:create_element()
    self.super.create_element(self)
    self._element.class = "ElementEnvironment"
    self._element.values.color_grading = 1
    self._element.values.chromatic_amount = 1
    self._element.values.brightness = 1
    self._element.values.contrast = 1
    self._element.values.min_amount = 1
    self._element.values.max_amount = 5
    self._element.values.elements = {} 
end
function EditorEnvironment:_build_panel()
    self:_create_panel()
    self:_build_value_combobox("color_grading", {
        "none",
        "color_off",
        "color_payday",
        "color_heat",
        "color_nice",
        "color_sin",
        "color_bhd",
        "color_xgen",
        "color_xxxgen",
        "color_matrix"
    }, "Select the color grading this element should apply")
    self:_build_value_number("chromatic_amount", {floats = 0}, "Sets the chromatic amount( -1 = off )")
    self:_build_value_number("brightness", {floats = 0}, "Sets the amount of brightness this element will apply to the level( -1 = off )")
    self:_build_value_number("contrast", {floats = 0}, "Sets the amount of contrast this element will apply to the level( -1 = off )")
    self:_build_value_number("min_amount", {floats = 0}, "Sets the minimum amount the random value can be")
    self:_build_value_number("max_amount", {floats = 0}, "Sets the maximum amount the random value can be")
    self:_build_value_checkbox("random")
end
