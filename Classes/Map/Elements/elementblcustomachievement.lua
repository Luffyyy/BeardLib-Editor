EditorBLCustomAchievement = EditorBLCustomAchievement or class(MissionScriptEditor)
function EditorBLCustomAchievement:create_element()
	self.super.create_element(self)
	self._element.class = "ElementBLCustomAchievement"
	self._element.values.amount_increase = 1
end

function EditorBLCustomAchievement:_build_panel()
	self:_create_panel()

	local packages = {""}
	for _, package_id in pairs(BeardLib.Managers.Achievement:FetchPackages()) do
		table.insert(packages, package_id)
	end

	self:ComboCtrl("package_id", packages, {free_typing = true, help = "Type here Package ID from your Custom Achievement config."})
	self:ComboCtrl("achievement_id", self:_fetch_achievements(), {free_typing = true, help = "Type here Achievement ID from your Custom Achievement config, providing it exists in the Package ID that you typed upper."})
	self:NumberCtrl("amount_increase", {min = 1, help = "It'll increase the Amount from config by the given number."})
	self:BooleanCtrl("award_instigator", {help = "Should only award the Instigator (the guy who executed this element) or other teammates also?"})
	self:BooleanCtrl("players_from_start", {help = "Enabling this you'll make soo only the Players that played from start of an heist will earn this achievement."})
end

function EditorBLCustomAchievement:set_element_data(params, ...)
	EditorBLCustomAchievement.super.set_element_data(self, params, ...)
	if params.name == "package_id" then
		self:GetItem("achievement_id"):SetItems(self:_fetch_achievements())
	end
end


function EditorBLCustomAchievement:_fetch_achievements()
	local t = {""}

	if self._element.values.package_id then
		local package = CustomAchievementPackage:new(self._element.values.package_id)

		if package then
			for achievement_id, _ in pairs(package:FetchAchievements()) do
				table.insert(t, achievement_id)
			end
		end
	end

	return t
end