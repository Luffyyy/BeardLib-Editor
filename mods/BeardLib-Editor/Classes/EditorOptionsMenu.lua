EditorOptionsMenu = EditorOptionsMenu or class()
local Options = EditorOptionsMenu
function Options:init()
	local O = BeardLibEditor.Options
	local EMenu = BeardLibEditor.managers.Menu
	MenuUtils:new(self, EMenu:make_page("Options"))
	local main = self:DivGroup("Main")
	self:TextBox("ExtractDirectory", callback(self, self, "set_clbk"), O:GetValue("ExtractDirectory"), {
		help = "The extract directory will be used to load units from extract and be able to edit lights", group = main
	})

	local visual = self:DivGroup("Visual")
	self:Button("ResetVisualOptions", callback(self, self, "reset_options", visual), {group = visual})
	self:Button("AccentColor", callback(self, self, "open_set_color_dialog"), {group = visual})
	self:Button("BackgroundColor", callback(self, self, "open_set_color_dialog"), {group = visual})
	self:NumberBox("LevelsColumns", callback(self, self, "set_clbk"), O:GetValue("LevelsColumns"), {min = 1, floats = 0, group = visual})

	local themes = self:DivGroup("Themes", {group = visual, last_y_offset = 0})
	self:Button("Dark", callback(self, self, "set_theme"), {group = themes, text = "Dark[Default]"})
	self:Button("Light", callback(self, self, "set_theme"), {group = themes})
	local input = self:DivGroup("Input")
	function keybind(setting, supports_mouse, text)
		return self:KeyBind("Input/"..setting, callback(self, self, "set_clbk"), O:GetValue("Input/"..setting), {text = text or string.pretty2(setting), group = input, supports_mouse = supports_mouse})
	end
	self:Button("ResetInputOptions", callback(self, self, "reset_options", input), {group = input})
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
	
	self:Button("ResetOptions", callback(self, self, "reset_options"))
end

function Options:set_theme(menu, item)
	local theme = item.name
	if theme == "Dark" then
		self:set("AccentColor", Color(0.26, 0.45, 0.80))
		self:set("BackgroundColor", Color(0.5, 0.19, 0.19, 0.19))
	else
		self:set("AccentColor", Color(0.40, 0.38, 1))
		self:set("BackgroundColor", Color(0.64, 0.70, 0.70, 0.70))
	end
    BeardLibEditor.Utils:Notify("Theme has been set, please restart")
end

function Options:reset_options(menu)
	for _, item in pairs(menu._my_items) do
		if item.menu_type then
			self:reset_options(item)
		else
			local opt = BeardLibEditor.Options:GetOption(item.name)
			if opt then
				local value = opt.default_value
				self:set(item.name, value)
				item:SetValue(value)
			end
		end
	end
end

function Options:set_clbk(menu, item)
	self:set(item.name, item:Value())
	if item.name == "LevelsColumns" then
		BeardLibEditor.managers.LoadLevel:load_levels()
	end
end

function Options:set(option, value)
	BeardLibEditor.Options:SetValue(option, value)
	BeardLibEditor.Options:Save()
end

function Options:open_set_color_dialog(menu, item)
	option = item.name
    BeardLibEditor.managers.ColorDialog:Show({color = BeardLibEditor.Options:GetValue(option), callback = function(color)
    	self:set(option, color)
    end})
end