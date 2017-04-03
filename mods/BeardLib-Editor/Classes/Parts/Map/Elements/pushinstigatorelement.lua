EditorPushInstigator = EditorPushInstigator or class(MissionScriptEditor)
function EditorPushInstigator:create_element()
    self.super.create_element(self)
    self._element.class = "ElementPushInstigator"
    self._element.values.mass = 100
    self._element.values.multiply = 1
    self._element.values.velocity = Vector3()
end

function EditorPushInstigator:set_velocity()
    self._element.values.velocity = Vector3(self:GetItem("velocity_x"):Value(), self:GetItem("velocity_y"):Value(), self:GetItem("velocity_z"):Value())
    self:update_element()
end

function EditorPushInstigator:_build_panel()
    self:_create_panel()
    self:NumberCtrl("mass", {floats = 2, min = 0.1, help = "Set the mass of the push"})  
    self:NumberCtrl("multiply", {floats = 2, min = 0.1, help = "Set the mass of the push"})  
    self:BooleanCtrl("no_z")
    self:BooleanCtrl("forward")
    local vel = self._element.values.velocity
    self:Slider("velocity_x", callback(self, self, "set_velocity"), vel.x or 0)
    self:Slider("velocity_y", callback(self, self, "set_velocity"), vel.y or 0)
    self:Slider("velocity_z", callback(self, self, "set_velocity"), vel.z or 0)     
end