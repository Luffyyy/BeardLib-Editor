EditorOptionsMenu = EditorOptionsMenu or class()
local Options = EditorOptionsMenu
function Options:init()
	local O = BLE.Options
	local EMenu = BLE.Menu
	local icons =  BLE.Utils.EditorIcons
	local page = EMenu:make_page("Options", nil, {scrollbar = false})
	ItemExt:add_funcs(self, page)
	local w = page:ItemsWidth(2, 0)
	local h = page:ItemsHeight(2, 6)

	local main = self:divgroup("Main", {w = w / 2, auto_height = false, h = h * 1/2})
	main:GetToolbar():tb_imgbtn("ResetMainOptions", ClassClbk(self, "reset_options", main), nil, icons.reset_settings, {img_scale = 0.7, help = "Reset main settings"})
	main:button("ResetAllOptions", ClassClbk(self, "reset_options", page))
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
	main:separator()
    main:tickbox("KeepMouseActiveWhileFlying", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/KeepMouseActiveWhileFlying"))
    main:tickbox("QuickAccessToolbar", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/QuickAccessToolbar"))
	main:tickbox("RemoveOldLinks", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/RemoveOldLinks"), {
        text = "Remove Old Links Of Copied Elements",
        help = "Should the editor remove old links(ex: elements inside the copied element's on_executed list that are not part of the copy) when copy pasting elements"
    })
	main:separator()

	main:numberbox("UndoHistorySize", ClassClbk(self, "set_clbk"), O:GetValue("UndoHistorySize"), {min = 1, max = 100000})
	main:numberbox("InstanceIndexSize", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/InstanceIndexSize"), {max = 100000, floats = 0, min = 1, help = "Sets the default index size for instances."})

	local visual = self:divgroup("Visual", {w = w / 2, auto_height = false, h = h * 1/2})
	visual:GetToolbar():tb_imgbtn("ResetVisualOptions", ClassClbk(self, "reset_options", visual), nil, icons.reset_settings, {img_scale = 0.7, help = "Reset visual settings"})
	visual:tickbox("GUIOnRight", ClassClbk(self, "set_clbk"), O:GetValue("GUIOnRight"), {text = "Place Editor GUI on the right side"})
	visual:slider("MapEditorPanelWidth", ClassClbk(self, "set_clbk"), O:GetValue("MapEditorPanelWidth"), {min = 100, max = 1600})
	visual:slider("MapEditorFontSize", ClassClbk(self, "set_clbk"), O:GetValue("MapEditorFontSize"), {min = 8, max = 42})
	visual:slider("ParticleEditorPanelWidth", ClassClbk(self, "set_clbk"), O:GetValue("ParticleEditorPanelWidth"), {min = 100, max = 1600})
	visual:slider("QuickAccessToolbarSize", ClassClbk(self, "set_clbk"), O:GetValue("QuickAccessToolbarSize"), {min = 18, max = 38})
	visual:colorbox("AccentColor", ClassClbk(self, "set_clbk"), O:GetValue("AccentColor"))
	visual:colorbox("BackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("BackgroundColor"))
	visual:colorbox("ItemsHighlight", ClassClbk(self, "set_clbk"), O:GetValue("ItemsHighlight"))
	visual:colorbox("ContextMenusBackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("ContextMenusBackgroundColor"))
	visual:colorbox("BoxesBackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("BoxesBackgroundColor"))
	visual:colorbox("ToolbarBackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("ToolbarBackgroundColor"))
	visual:colorbox("ToolbarButtonsColor", ClassClbk(self, "set_clbk"), O:GetValue("ToolbarButtonsColor"))
	visual:separator()
    visual:colorbox("ElementsColor", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/ElementsColor"))
	visual:tickbox("UniqueElementIcons", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/UniqueElementIcons"))
    visual:tickbox("RandomizedElementsColor", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/RandomizedElementsColor"))
    visual:slider("ElementsSize", ClassClbk(self, "set_map_clbk"), O:GetValue("Map/ElementsSize"), {max = 64, min = 16, floats = 0})

	local input = self:divgroup("Input", {w = w / 2, h = page:ItemsHeight(1, 6), auto_height = false, position = function(item)
		if alive(main) then
			local panel = main:Panel()
			item:Panel():set_position(panel:right() + 12, panel:y())
		end
	end})
	local function keybind(setting, supports_mouse, text)
		return input:keybind("Input/"..setting, ClassClbk(self, "set_clbk"), O:GetValue("Input/"..setting), {text = text or string.pretty2(setting), supports_mouse = supports_mouse, supports_additional = true})
	end
	input:GetToolbar():tb_imgbtn("ResetInputOptions", ClassClbk(self, "reset_options", input), nil, icons.reset_settings, {img_scale = 0.7, help = "Reset input settings"})

	keybind("TeleportToSelection")
	keybind("CopyUnit")
	keybind("PasteUnit")
	keybind("SaveMap")
	keybind("ToggleMoveWidget")
	keybind("ToggleRotationWidget")
	keybind("ToggleTransformOrientation")
	keybind("DeleteSelection")
	keybind("ToggleMapEditor", nil, "Toggle Playtesting")
	keybind("IncreaseCameraSpeed")
	keybind("DecreaseCameraSpeed")
	keybind("ToggleGUI")
	keybind("ToggleRuler")
	keybind("SpawnUnit")
	keybind("SpawnElement")
	keybind("SelectUnit")
	keybind("SelectElement")
	keybind("SpawnInstance")
	keybind("SpawnPrefab")
	keybind("SelectInstance")
	keybind("RotateSpawnDummyYaw")
	keybind("RotateSpawnDummyPitch")
	keybind("RotateSpawnDummyRoll")
	keybind("SettleUnits")
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
	end
end

function Options:set(option, value)
	BLE.Options:SetValue(option, value)
	BLE.Options:Save()
end