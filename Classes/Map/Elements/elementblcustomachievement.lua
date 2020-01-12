EditorBLCustomAchievement = EditorBLCustomAchievement or class(MissionScriptEditor)
function EditorBLCustomAchievement:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBLCustomAchievement"
	self._element.values.amount_increase = 1
end

function EditorBLCustomAchievement:_build_panel()
	self:_create_panel()
	self:StringCtrl("package_id", {help = "Type here Package ID from your Custom Achievement config."})
	self:StringCtrl("achievement_id" ,{help = "Type here Achievement ID from your Custom Achievement config, providing it exists in the Package ID that you typed upper."})
	self:NumberCtrl("amount_increase", {min = 1, help = "It'll increase the Amount from config by the given number."})
	self:BooleanCtrl("award_instigator", {help = "Should only award the Instigator (the guy who executed this element) or other teammates also?"})
	self:BooleanCtrl("players_from_start", {help = "Enabling this you'll make soo only the Players that played from start of an heist will earn this achievement."})
end
