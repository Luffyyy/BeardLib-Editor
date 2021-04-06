EditorOptionsMenu = EditorOptionsMenu or class()
local Options = EditorOptionsMenu
function Options:init()
	local O = BLE.Options
	local EMenu = BLE.Menu
	local page = EMenu:make_page("Options")
	ItemExt:add_funcs(self, page)
	local main = self:divgroup("Main")
	main:textbox("ExtractDirectory", ClassClbk(self, "set_clbk"), O:GetValue("ExtractDirectory"), {
		help = "The extract directory will be used to load units from extract and be able to edit lights"
	})
	main:slider("UndoHistorySize", ClassClbk(self, "set_clbk"), O:GetValue("UndoHistorySize"), {min = 1, max = 100000})
	main:slider("MapEditorPanelWidth", ClassClbk(self, "set_clbk"), O:GetValue("MapEditorPanelWidth"), {min = 100, max = 1600})
	main:slider("MapEditorFontSize", ClassClbk(self, "set_clbk"), O:GetValue("MapEditorFontSize"), {min = 8, max = 42})
	main:slider("ParticleEditorPanelWidth", ClassClbk(self, "set_clbk"), O:GetValue("ParticleEditorPanelWidth"), {min = 100, max = 1600})

	local visual = self:divgroup("Visual")
	visual:button("ResetVisualOptions", ClassClbk(self, "reset_options", visual))
	visual:colorbox("AccentColor", ClassClbk(self, "set_clbk"), O:GetValue("AccentColor"))
	visual:colorbox("BackgroundColor", ClassClbk(self, "set_clbk"), O:GetValue("BackgroundColor"))

	local themes = visual:divgroup("Themes", {last_y_offset = 0})
	themes:button("Dark", ClassClbk(self, "set_theme"), {text = "Dark[Default]"})
	themes:button("Light", ClassClbk(self, "set_theme"))
	local input = self:divgroup("Input")
	local function keybind(setting, supports_mouse, text)
		return input:keybind("Input/"..setting, ClassClbk(self, "set_clbk"), O:GetValue("Input/"..setting), {text = text or string.pretty2(setting), supports_mouse = supports_mouse, supports_additional = true})
	end
	input:button("ResetInputOptions", ClassClbk(self, "reset_options", input))
	keybind("TeleportToSelection")
	keybind("CopyUnit")
	keybind("PasteUnit")
	keybind("SaveMap")
	keybind("ToggleMoveWidget")
	keybind("ToggleRotationWidget")
	keybind("DeleteSelection")
	keybind("ToggleMapEditor")
	keybind("IncreaseCameraSpeed")
	keybind("DecreaseCameraSpeed")
	keybind("ToggleGUI")
	keybind("ToggleRuler")
	keybind("SpawnUnit")
	keybind("SpawnElement")
	keybind("SelectUnit")
	keybind("SelectElement")
	keybind("LoadUnit")
	keybind("LoadUnitFromExtract")
	keybind("RotateSpawnDummyYaw")
	keybind("RotateSpawnDummyPitch")
	keybind("RotateSpawnDummyRoll")

	self:button("ResetOptions", ClassClbk(self, "reset_options", page))
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
		self:set_item_value("AccentColor", Color(0.40, 0.38, 1))
		self:set_item_value("BackgroundColor", Color(0.64, 0.70, 0.70, 0.70))
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
				local value = opt.default_value
				self:set(item.name, value)
				item:SetValue(value)
			end
		end
	end
end

function Options:set_clbk(item)
	self:set(item.name, item:Value())
	if item.name == "LevelsColumns" then
		BLE.LoadLevel:load_levels()
	end
end

function Options:set(option, value)
	BLE.Options:SetValue(option, value)
	BLE.Options:Save()
end