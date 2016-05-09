EditorHeat = EditorHeat or class(MissionScriptEditor)
function EditorHeat:init(unit)
	EditorHeat.super.init(self, unit)
end

function EditorHeat:create_element()
	self.super.create_element(self)
	self._element.class = "ElementHeat"	
	self._element.values.points = 0
	self._element.values.level = 0 
end

function EditorHeat:_build_panel()
	self:_create_panel()
	self._build_value_number("points", {}, "Can increase or decrease the heat level", "Heat points")
	self._build_value_number("level", {min = 0, max = 10}, "Use this to set the heat level (if it isn't this or hihger allready)", "Heat level")
	self:add_help_text("If level is specified (level ~= 0) the result of this element will be to try increase the heat level (it will never lower it though). If the level == 0 then the heat points will be used to increase or decrese the heat.")
end
EditorHeatTrigger = EditorHeatTrigger or class(MissionScriptEditor)
function EditorHeatTrigger:init(unit)
	EditorHeatTrigger.super.init(self, unit)
	self._element.class = "ElementHeatTrigger"
	self._element.values.trigger_times = 1
	self._element.values.stage = 0
end
function EditorHeatTrigger:_build_panel()
	self:_create_panel()
	self._build_value_number("stage", {min = 0, max = 10}, "Set the heat stage to get a trigger from ", "Heat stage")
	self:add_help_text("Set which heat stage to get a trigger from.")
end
