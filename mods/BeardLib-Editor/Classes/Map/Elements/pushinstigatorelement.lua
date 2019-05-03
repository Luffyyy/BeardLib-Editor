EditorPushInstigator = EditorPushInstigator or class(MissionScriptEditor)
function EditorPushInstigator:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPushInstigator"
    self._element.values.mass = 100
    self._element.values.multiply = 1
    self._element.values.velocity = Vector3()
end

function EditorPushInstigator:_build_panel()
    self:_create_panel()
    self:NumberCtrl("mass", {floats = 2, min = 0.1, help = "Set the mass of the push"})  
    self:NumberCtrl("multiply", {floats = 2, min = 0.1, help = "Set the mass of the push"})  
    self:BooleanCtrl("no_z")
    self:BooleanCtrl("forward")
    self:Vector3Ctrl("velocity", {group = self._class_group})
end