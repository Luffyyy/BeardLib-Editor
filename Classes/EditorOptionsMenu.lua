EditorOptionsMenu = EditorOptionsMenu or class()
local Options = EditorOptionsMenu
function Options:init()
	local O = BLE.Options
	local EMenu = BLE.Menu
	local icons =  BLE.Utils.EditorIcons
	local page = EMenu:make_page("Options", nil, {scrollbar = false})
	self._elem_colors = O:GetValue("Map/ElementColorGroups")
	ItemExt:add_funcs(self, page)
	local w = page:ItemsWidth(2, 0)
	local h = page:ItemsHeight(2, 6)

	local main = self:divgroup("Main", {w = w / 2, auto_height = false, h = h * 1/2})
	main:GetToolbar():tb_imgbtn("ResetMainOptions", ClassClbk(self, "show_reset_dialog", main), nil, icons.reset_settings, {img_scale = 0.7, help = "Reset main settings"})
	main:button("ResetAllOptions", ClassClbk(self, "show_reset_dialog", page))
	main:button("ReloadEditor", ClassClbk(self, "reload"), {help = "A reload button if you wish to see your changes in effect faster. Pleae don't use this when actually working on a project."})
	main:button(FileIO:Exists("mods/saves/BLEDisablePhysicsFix") and "EnablePhysicsFix" or "DisablePhysicsFix", ClassClbk(self, "show_disable_physics_fix_dialog"))

	main:separator()
	main:numberbox("AutoSaveMinutes", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/AutoSaveMinutes"), {help = "Set the time for auto saving"})
    main:tickbox("AutoSave", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/AutoSave"), {help = "Saves your map automatically, unrecommended for large maps."})
    main:tickbox("SaveBeforePlayTesting", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/SaveBeforePlayTesting"), {help = "Saves your map as soon as you playtest your map"})
    main:tickbox("SaveMapFilesInBinary", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/SaveMapFilesInBinary"), {
		help = "Saving your map files in binary cuts down in map file size which is highly recommended for release!"
	})
    main:tickbox("BackupMaps", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/BackupMaps"))
    main:tickbox("SaveWarningAfterGameStarted", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/SaveWarningAfterGameStarted"), {
		help = "Show a warning message when trying to save after play testing started the heist, where you can allow or disable saving for that session"
	})
	main:tickbox("MuteSoundsInEditor", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/MuteSoundsInEditor"), {text = "Mute Sounds In Editor During Playtest", help = "Switching to editor mode while playtesting is active will mute all sounds. They will get unmuted again when switching back to play mode."})
	main:separator()
    main:tickbox("KeepMouseActiveWhileFlying", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/KeepMouseActiveWhileFlying"))
	main:tickbox("OnlyMoveWhileFlying", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/OnlyMoveWhileFlying"))
    main:tickbox("QuickAccessToolbar", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/QuickAccessToolbar"))
    main:tickbox("ShowHints", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/ShowHints"), {help = "Shows hints in the main tab of the world menu"})
	main:tickbox("RotationInfo", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/RotationInfo"), {help = "Shows how much you are rotating the current selection by"})
	main:tickbox("RemoveOldLinks", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/RemoveOldLinks"), {
        text = "Remove Old Links Of Copied Elements",
        help = "Should the editor remove old links(ex: elements inside the copied element's on_executed list that are not part of the copy) when copy pasting elements"
    })
	main:tickbox("AllowMultiWidgets", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/AllowMultiWidgets"), {
        text = "Allow Multiple Active Widgets",
        help = "When activating the Move or the Rotation Widgets, should the other one be allowed to stay active, or deactivate automatically."
    })
	main:separator()

	main:numberbox("UndoHistorySize", ClassClbk(self, "set_clbk"), O:GetValue("UndoHistorySize"), {min = 1, max = 100000})
	main:numberbox("InstanceIndexSize", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/InstanceIndexSize"), {max = 100000, floats = 0, min = 1, help = "Sets the default index size for instances."})
	main:numberbox("Scrollspeed", ClassClbk(self, "set_clbk"), O:GetValue("Scrollspeed"), {max = 100, floats = 1, min = 1})

	local visual = self:divgroup("Visual", {w = w / 2, auto_height = false, h = h * 1/2})
	visual:GetToolbar():tb_imgbtn("ResetVisualOptions", ClassClbk(self, "show_reset_dialog", visual), nil, icons.reset_settings, {img_scale = 0.7, help = "Reset visual settings"})
	visual:tickbox("GUIOnRight", ClassClbk(self, "set_clbk"), O:GetValue("GUIOnRight"), {text = "Place Editor GUI on the right side"})
	visual:combobox("ToolbarPosition", ClassClbk(self, "set_clbk"), {"Top Corner", "Top Middle", "Bottom Middle"}, O:GetValue("ToolbarPosition"))
	visual:slider("MapEditorPanelWidth", ClassClbk(self, "set_clbk"), O:GetValue("MapEditorPanelWidth"), {min = 300, max = 1600})
	visual:slider("MapEditorFontSize", ClassClbk(self, "set_clbk"), O:GetValue("MapEditorFontSize"), {min = 8, max = 42})
	visual:slider("StatusMenuFontSize", ClassClbk(self, "set_clbk"), O:GetValue("StatusMenuFontSize"), {min = 8, max = 32})
	visual:slider("ParticleEditorPanelWidth", ClassClbk(self, "set_clbk"), O:GetValue("ParticleEditorPanelWidth"), {min = 300, max = 1600})
	visual:slider("QuickAccessToolbarSize", ClassClbk(self, "set_clbk"), O:GetValue("QuickAccessToolbarSize"), {min = 18, max = 38})
	visual:slider("BoxesXOffset", ClassClbk(self, "set_clbk"), O:GetValue("BoxesXOffset"), {min = 0, max = 16})
	visual:slider("BoxesYOffset", ClassClbk(self, "set_clbk"), O:GetValue("BoxesYOffset"), {min = 0, max = 16})
	visual:slider("ItemsXOffset", ClassClbk(self, "set_clbk"), O:GetValue("ItemsXOffset"), {min = 0, max = 16})
	visual:slider("ItemsYOffset", ClassClbk(self, "set_clbk"), O:GetValue("ItemsYOffset"), {min = 0, max = 16})
	visual:colorbox("AccentColor", ClassClbk(self, "set_clbk"), O:GetValue("AccentColor"))
	visual:colorbox("BackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("BackgroundColor"))
	visual:colorbox("ItemsHighlight", ClassClbk(self, "set_clbk"), O:GetValue("ItemsHighlight"))
	visual:colorbox("ContextMenusBackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("ContextMenusBackgroundColor"))
	visual:colorbox("BoxesBackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("BoxesBackgroundColor"))
	visual:colorbox("ToolbarBackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("ToolbarBackgroundColor"))
	visual:colorbox("ToolbarButtonsColor", ClassClbk(self, "set_clbk"), O:GetValue("ToolbarButtonsColor"))
	visual:separator()
	visual:slider("ElementsSize", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/ElementsSize"), {max = 64, min = 16, floats = 0})
	visual:tickbox("UniqueElementIcons", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/UniqueElementIcons"))
    visual:tickbox("RandomizedElementsColor", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/RandomizedElementsColor"))
	local colors = visual:group("ElementColors", {enabled = not O:GetValue("Map/RandomizedElementsColor"), auto_align = false})
	colors:GetToolbar():tb_imgbtn("AddColorGroup", ClassClbk(self, "add_color_group", colors), nil, icons.plus, {img_scale = 0.7, help = "Add new element color group"})
	colors:colorbox("ElementsColor", ClassClbk(self, "set_map_clbk"), BLE.Options:GetValue("Map/ElementsColor"), {text = "Default", use_alpha = false})
	self:build_color_groups(colors)

	local input = self:divgroup("Input", {w = w / 2, h = page:ItemsHeight(1, 6), auto_height = false, position = function(item)
		if alive(main) then
			local panel = main:Panel()
			item:Panel():set_position(panel:right() + 12, panel:y())
		end
	end})
	local function keybind(setting, supports_mouse, text, help)
		return input:keybind("Input/"..setting, ClassClbk(self, "set_clbk"), O:GetValue("Input/"..setting), {text = text or string.pretty2(setting), help = help, supports_mouse = supports_mouse, supports_additional = true})
	end
	input:GetToolbar():tb_imgbtn("ResetInputOptions", ClassClbk(self, "show_reset_dialog", input), nil, icons.reset_settings, {img_scale = 0.7, help = "Reset input settings"})

	keybind("CopyUnit")
	keybind("PasteUnit")
	keybind("SaveMap")
	keybind("Undo")
	keybind("Redo")
	keybind("DeleteSelection")
	keybind("Deselect")
	input:separator()
	keybind("ToggleMoveWidget")
	keybind("ToggleRotationWidget")
	keybind("ToggleTransformOrientation")
	keybind("ToggleEditorUnits")
	keybind("ToggleElements")
	keybind("ToggleSurfaceMove")
	keybind("ToggleSnappoints")
	keybind("ToggleMapEditor", nil, "Toggle Playtesting")
	input:separator()
	keybind("IncreaseCameraSpeed")
	keybind("DecreaseCameraSpeed")
	keybind("IncreaseGridSize")
	keybind("DecreaseGridSize")
	keybind("IncreaseGridAltitude")
	keybind("DecreaseGridAltitude")
	keybind("ToggleLight")
	keybind("ToggleGUI")
	keybind("ToggleRuler")
	input:separator()
	keybind("TeleportToSelection")
	keybind("LinkManaged", nil, "Link To Element Managed List")
	keybind("OpenManageList", nil, "Open Element Managed List")
	keybind("OpenOnExecutedList", nil, "Open Element On Executed List")
	keybind("SettleUnits")
	keybind("HideUnits", nil, "Hide Selected Units", "+alt to unhide all, +shift to hide not selected")
	keybind("ResetRotation", nil, nil, "Reset the rotation of selected units. +ctrl to also reset yaw")
	keybind("RotateSpawnDummyYaw")
	keybind("RotateSpawnDummyPitch")
	keybind("RotateSpawnDummyRoll")
	input:separator()
	keybind("WorldMenu")
	keybind("SelectionMenu")
	keybind("SpawnMenu")
	keybind("SelectMenu")
	keybind("ToolsMenu")
	keybind("OptionsMenu")
	input:separator()
	keybind("SpawnUnit")
	keybind("SpawnElement")
	keybind("SelectUnit")
	keybind("SelectElement")
	keybind("SpawnInstance")
	keybind("SpawnPrefab")
	keybind("SelectInstance")
	keybind("SelectGroup")
end

function Options:show_disable_physics_fix_dialog()
	local file = "mods/saves/BLEDisablePhysicsFix"
	local disabled = FileIO:Exists(file)
	BLE.Utils:YesNoQuestion(string.format([[
Since the editor requires an edit to the physics settings of the game, and such edit can lead to crashing other players (or cause unwanted bugs), the editor also disables online play.

Do note however, the editor will not work properly without said fixes. So once you're done playing and wish to continue using the editor, please turn on this option.

Clicking 'Yes' will %s the physics settings fix and close the game. After opening the game again, online play will be %s.
]], disabled and "enable" or "disable", disabled and "disabled" or "enabled")
, function()
		if disabled then
			FileIO:Delete(file)
		else
			FileIO:WriteTo(file, "", "w")
		end
		setup:quit()
	end)
end

function Options:build_color_groups()
	local icons =  BLE.Utils.EditorIcons

	local item = self:GetItem("ElementColors")
	item:ClearItems("colors")
	if self._elem_colors then
		local h = item:TextHeight() * 0.8
		for name, data in pairs(self._elem_colors) do
			local text = string.format("%s (%d)", name, #data.elements)
			local group = item:colorbox(name, ClassClbk(self, "set_color_group"), data.color, {text = text, use_alpha = false, return_hex = true, label = "colors", textbox_offset = h*3})
			group:tb_imgbtn("RemoveGroup", ClassClbk(self, "remove_color_group", name), nil, icons.cross, {img_scale = 0.8, help = "Remove color group"})
			group:tb_imgbtn("RenameGroup", ClassClbk(self, "rename_color_group", name), nil, icons.pen, {img_scale = 0.8, help = "Rename color group"})
			group:tb_imgbtn("EditGroup", ClassClbk(self, "edit_color_group", name), nil, icons.settings_gear, {img_scale = 0.8, help = "Set what elements use this color group"})
		end
	end
	item:AlignItems(true)
end

function Options:add_color_group()
	BLE.InputDialog:Show({title = "Color group name", text = "", callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = function()
                self:add_color_group()
            end})
            return
        elseif name == "Default" or string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:add_color_group()
            end})
            return
        elseif self._elem_colors and self._elem_colors[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Name already taken!", callback = function()
                self:add_color_group()
            end})
            return
        end

		self._elem_colors[name] = {color = Color.white, elements = {}}
		self:build_color_groups()
		BLE.Options:SetValue("Map/ElementColorGroups", self._elem_colors)
		BLE.Options:Save()
    end})
end

function Options:remove_color_group(name)
	BLE.Utils:YesNoQuestion("This will remove the element color group!", function()
		self._elem_colors[name] = nil
		self:build_color_groups()
		BLE.Options:SetValue("Map/ElementColorGroups", self._elem_colors)
		BLE.Options:Save()
	end)
end

function Options:set_color_group(item)
	local name = item:Name()
	if name and self._elem_colors[name] then
		self._elem_colors[name].color = item:Value()
		BLE.Options:SetValue("Map/ElementColorGroups", self._elem_colors)
		BLE.Options:Save()
	end
end

function Options:edit_color_group(name)
	local list = {}  
	for _, element in pairs(BLE._config.MissionElements) do
        local elem_name = element:gsub("Element", "")
		local available = true
		for i, group in pairs(self._elem_colors) do
			if i ~= name and table.contains(group.elements, elem_name) then
				available = false
			end
		end
		if available then
			table.insert(list, elem_name)
		end
    end

	BLE.SelectDialog:Show({
        selected_list = self._elem_colors[name].elements,
        list = list,
        callback = function(list) 
			self._elem_colors[name].elements = list
			self:build_color_groups()
			BLE.Options:SetValue("Map/ElementColorGroups", self._elem_colors)
			BLE.Options:Save()
        end
    })
end

function Options:rename_color_group(old_name)
    local mission = managers.mission
    BLE.InputDialog:Show({title = "Rename Color group to", text = script, callback = function(name)
        if name == "" then
            BLE.Dialog:Show({title = "ERROR!", message = "Name cannot be empty!", callback = function()
                self:rename_color_group(name)
            end})
            return
        elseif name == "Default" or string.begins(name, " ") then
            BLE.Dialog:Show({title = "ERROR!", message = "Invalid name", callback = function()
                self:rename_color_group(name)
            end})
            return
        elseif self._elem_colors and self._elem_colors[name] then
            BLE.Dialog:Show({title = "ERROR!", message = "Name already taken", callback = function()
                self:rename_color_group(name)
            end})
            return
        end

		self._elem_colors[name] = deep_clone(self._elem_colors[old_name])
        self._elem_colors[old_name] = nil
		self:build_color_groups()
		BLE.Options:SetValue("Map/ElementColorGroups", self._elem_colors)
		BLE.Options:Save()
    end})
end

function Options:get_element_color(name)
	for _, group in pairs(self._elem_colors) do
		if table.contains(group.elements, name) then
			return group.color
		end
	end
end

function Options:show_reset_dialog(menu)
	BLE.Utils:YesNoQuestion("Do you want to reset the selected options?", ClassClbk(self, "reset_options", menu))
end

function Options:Load(data)
    
end

function Options:Destroy()
    return {}
end

function Options:set_item_value(name, value)
	self:GetItem(name):SetValue(value, true)
end

function Options:set_theme(item)
	local theme = item.name
	if theme == "Dark" then
		self:set_item_value("AccentColor", Color('4272d9'))
		self:set_item_value("BackgroundColor", Color(0.6, 0.2, 0.2, 0.2))
	else
		self:set_item_value("AccentColor", Color('4272d9'))
		self:set_item_value("BackgroundColor", Color(0.6, 0.62, 0.62, 0.62))
	end
    BLE.Utils:Notify("Theme has been set, please restart")
end

function Options:reset_options(menu)
	for _, item in pairs(menu:Items()) do
		if item.menu_type then
			self:reset_options(item)
		else
			local opt = BLE.Options:GetOption(item.name)
			if opt then
				local value = BLE.Options:GetOptionDefaultValue(opt)
				if value then
					self:set(item.name, value)
					item:SetValue(value)
				end
			end
		end
	end
end

function Options:set_clbk(item)
	self:set(item.name, NotNil(item:Value(), ""))
end

function Options:set_map_clbk(item)
	local name = item.name
	local value = item:Value()
	self:set("Map/"..item.name, NotNil(value, ""))
	if name == "QuickAccessToolbar" then
        managers.editor:set_use_quick_access(value)
	elseif name == "AutoSave" or name == "AutoSaveMinutes" then
        managers.editor.parts.opt:toggle_autosaving()
	elseif name == "RandomizedElementsColor" then
		self:GetItem("ElementColors"):SetEnabled(not value)
	end
end

function Options:set(option, value)
	BLE.Options:SetValue(option, value)
	BLE.Options:Save()
end

function Options:reload()
	BeardLib:AddDelayedCall("SettingsReloadBLE", 0.1, function()
		BLE:MapEditorCodeReload()
	end)
end