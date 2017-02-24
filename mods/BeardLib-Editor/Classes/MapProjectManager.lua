MapProjectManager = MapProjectManager or class()
function MapProjectManager:init()
	self._templates_directory = BeardLib.Utils.Path:Combine(BeardLibEditor.ModPath, "Templates/map")
	local data = FileIO:ReadFrom(BeardLib.Utils.Path:Combine(self._templates_directory, "main.xml"))
	if data then
    	self._main_xml_template = ScriptSerializer:from_custom_xml(data)
    else
    	BeardLibEditor:log("[ERROR]")
    end
   	self._menu = BeardLibEditor.managers.Menu
	self._menu:make_page("New", "Projects", callback(self, self, "new_project"))
	self._menu:make_page("EditExisting", "Projects", callback(self, self, "select_project"))   	
	MenuUtils:new(self, self._menu._menus.Projects)
end

function MapProjectManager:get_projects_list()
    local list = {}
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        table.insert(list, {name = mod.Name, mod = mod})
    end
    return list
end

function MapProjectManager:get_project_by_narrative_id(narr)
	for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
		local narrative = BeardLib.Utils:GetNodeByMeta(data, "narrative")
		if narrative.id == narr.id then
			return mod
		end
	end
end

function MapProjectManager:select_project()
    self._menu._list_dia:Show({
        list = self:get_projects_list(),
        callback = function(selection)
            self._menu._list_dia:hide()   
            local old_name = selection.mod._clean_config.name
           	self._menu:select_page("Projects", nil, self._menu:GetItem("EditExisting"))
            self:edit_main_xml(selection.mod._clean_config, function()
            	FileIO:WriteTo(BeardLib.Utils.Path:Combine(selection.mod.ModPath, "main.xml"), FileIO:ConvertToScriptData(self._current_data, "custom_xml"))
                selection.mod._clean_config = self._current_data
                if self._current_data.name ~= old_name then
                	FileIO:MoveTo(selection.mod.ModPath, BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, self._current_data.name))
                end
            end)
        end
    }) 
end

function MapProjectManager:new_project()
	self._menu:select_page("Projects", nil, self._menu:GetItem("New"))
	self:edit_main_xml(self._main_xml_template, function()
		local new_map = BeardLib.Utils.Path:Combine(BeardLib.config.maps_dir, self._current_data.name)
		FileIO:CopyTo(self._templates_directory, new_map)
		FileIO:WriteTo(BeardLib.Utils.Path:Combine(new_map, "main.xml"), FileIO:ConvertToScriptData(self._current_data, "custom_xml"))
        self:disable()
	end)
end

function MapProjectManager:edit_main_xml(data, save_clbk)
	self:ClearItems()
	data = BeardLib.Utils:CleanCustomXmlTable(deep_clone(data)) 
	local level = BeardLib.Utils:GetNodeByMeta(data, "level")
	local narr = BeardLib.Utils:GetNodeByMeta(data, "narrative")
	if not level then
		table.insert(data, {_meta = "level"})
		narr = BeardLib.Utils:GetNodeByMeta(data, "level")
	end
	if not narr then
		table.insert(data, {_meta = "narrative"})
		level = BeardLib.Utils:GetNodeByMeta(data, "narrative")
	end
	local up = callback(self, self, "set_level_data")
	local basic = self:Group("Basic")
	self:TextBox("ModName", up, data.name, {group = basic})
	self:TextBox("LevelId", up, level.id, {group = basic})
	self:TextBox("NarrativeId", up, narr.id, {group = basic})
	local level_group = self:Group("Level")
	--self:ComboBox("AIGroupType", up)
	self:TextBox("BriefingDialog", up, level.briefing_dialog, {group = level_group})
	self:TextBox("OutroEvent", up, level.outro_event, {group = level_group})
	self:NumberBox("GhostBonus", up, level.ghost_bonus, {max = 1, min = 0, group = level_group})
	self:NumberBox("MaxBags", up, level.max_bags, {max = 999, min = 0, group = level_group})
	self:TextBox("BriefingEvent", up, narr.briefing_event, {group = level_group})
	local contacts = table.map_keys(tweak_data.narrative.contacts)
	self:ComboBox("Contact", up, contacts, table.get_key(contacts, narr.contact), {group = level_group})
	self._contract_costs = {}
	self._experience_multipliers = {}
	self._max_mission_xps = {}
	self._min_mission_xps = {}
	self._payouts = {}
	local contract_costs = BeardLib.Utils:GetNodeByMeta(narr, "contract_cost")
	local experience_multipliers = BeardLib.Utils:GetNodeByMeta(narr, "experience_mul")
	local max_mission_xps = BeardLib.Utils:GetNodeByMeta(narr, "max_mission_xp")
	local min_mission_xps = BeardLib.Utils:GetNodeByMeta(narr, "min_mission_xp")
	local payouts = BeardLib.Utils:GetNodeByMeta(narr, "payout")
	local diffs = {
		"Normal",
		"Hard",
		"Very Hard",
		"Overkill",
		"Mayhem",
		"Death Wish",
		"One Down"
	}
	for i, diff in pairs(diffs) do
		local group = self:Group("Difficulty settings for: "..diff)
		self._contract_costs[i] = self:NumberBox("ContractCost"..i, up, contract_costs[i], {max = 10000000, min = 0, group = group, text = "Contract Cost"})
		self._experience_multipliers[i] = self:NumberBox("ExperienceMul"..i, up, experience_multipliers[i], { max = 5, min = 0, group = group, text = "Stealth XP bonus"})
		self._max_mission_xps[i] = self:NumberBox("MaxMissionXp"..i, up, max_mission_xps[i], {max = 10000000, min = 0, group = group, text = "Minimum mission XP"})
		self._min_mission_xps[i] = self:NumberBox("minMissionXp"..i, up, min_mission_xps[i], {max = 100000, min = 0, group = group, text = "Maximum mission XP"})
		self._payouts[i] = self:NumberBox("Payout"..i, up, payouts[i], {max = 100000000, min = 0, group = group, text = "Payout"})
	end	
	local missionassets = self:Group("MissionAssets")
	self._assets = {}
	local assets = {}
	for _, v in pairs(BeardLib.Utils:GetNodeByMeta(level, "assets")) do
		if type(v) == "table" and v.name then
			assets[v.name] = true
		end
	end
	for asset in pairs(tweak_data.assets) do 
		--self._assets[asset] = self:Toggle(asset, up, assets[asset] ~= nil, {items_size = 14, group = levelassets}) 
	end
	self:Button("Save", save_clbk)
	self:Button("Back", callback(self, self, "disable"))
	self._current_data = data
end

function MapProjectManager:disable()
	self:ClearItems()
	self._menu:select_page()
end

function MapProjectManager:set_level_data(menu, item)
	local t = self._current_data
	local level = BeardLib.Utils:GetNodeByMeta(t, "level")
	local narr = BeardLib.Utils:GetNodeByMeta(t, "narrative")
	local narr_level_chain = BeardLib.Utils:GetNodeByMeta(narr, "chain")
	t.name = menu:GetItem("ModName"):Value()
	level.id = menu:GetItem("LevelId"):Value()
	level.name_id = string.format("heist_%s", level.id)	
	level.brief_id = string.format("heist_%s_brief", level.id)	
	narr.id = menu:GetItem("NarrativeId"):Value()
	narr.brief_id = string.format("narr_%s_brief", narr.id)
	narr.name_id = string.format("narr_%s", narr.id)
	narr_level_chain[1].level_id = level.id --Later point: Multiple levels!
end