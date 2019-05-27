EditorHeat = EditorHeat or class(MissionScriptEditor)
function EditorHeat:create_element()
	self.super.create_element(self)
	self._element.class = "ElementHeat"	
	self._element.values.points = 0
	self._element.values.level = 0 
end

function EditorHeat:_build_panel()
    self:_create_panel()
    self:NumberCtrl("points", {
        help = "Can increase or decrease the heat level", 
        text = "Heat points"
    })
    self:NumberCtrl("level", {
        min = 0, 
        max = 10, 
        help = "Use this to set the heat level (if it isn't this or hihger allready)", 
        text = "Heat level"
    })
    self:Text("If level is specified (level ~= 0) the result of this element will be to try increase the heat level (it will never lower it though). If the level == 0 then the heat points will be used to increase or decrese the heat.")
end

EditorHeatTrigger = EditorHeatTrigger or class(MissionScriptEditor)
function EditorHeatTrigger:create_element()
	EditorHeatTrigger.super.create_element(self)
	self._element.class = "ElementHeatTrigger"
	self._element.values.trigger_times = 1
	self._element.values.stage = 0
end

function EditorHeatTrigger:_build_panel()
	self:_create_panel()
	self:NumberCtrl("stage", {min = 0, max = 10, help = "Set the heat stage to get a trigger from ", text = "Heat stage"})
	self:Text("Set which heat stage to get a trigger from.")
end
