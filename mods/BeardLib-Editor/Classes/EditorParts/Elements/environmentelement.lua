EditorEnvironment = EditorEnvironment or class(MissionScriptEditor)
EditorEnvironment._actions = {"set"}
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
    self:ComboCtrl("color_grading", {"none", "color_off","color_payday","color_heat","color_nice","color_sin","color_bhd","color_xgen","color_xxxgen","color_matrix"}, {
        help = "Select the color grading this element should apply"
    })
    self:NumberCtrl("chromatic_amount", {floats = 0, help = "Sets the chromatic amount( -1 = off )"})
    self:NumberCtrl("brightness", {floats = 0, help ="Sets the amount of brightness this element will apply to the level( -1 = off )"})
    self:NumberCtrl("contrast", {floats = 0, help ="Sets the amount of contrast this element will apply to the level( -1 = off )"})
    self:NumberCtrl("min_amount", {floats = 0, help ="Sets the minimum amount the random value can be"})
    self:NumberCtrl("max_amount", {floats = 0, help ="Sets the maximum amount the random value can be"})
    self:BooleanCtrl("random")
end
