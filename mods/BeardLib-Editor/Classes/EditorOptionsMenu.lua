EditorOptionsMenu = EditorOptionsMenu or class()
function EditorOptionsMenu:init()
	local O = BeardLibEditor.Options
	local EMenu = BeardLibEditor.managers.Menu
	MenuUtils:new(self, EMenu:make_page("Options"))
	local visual = self:DivGroup("Visual")
	self:Button("ResetVisualOptions", callback(self, self, "reset_options", visual), {group = visual})
	self:Button("AccentColor", callback(self, self, "open_set_color_dialog"), {group = visual})
	self:Button("BackgroundColor", callback(self, self, "open_set_color_dialog"), {group = visual})
	self:NumberBox("LevelsColumns", callback(self, self, "set_clbk"), O:GetValue("LevelsColumns"), {min = 1, floats = 0, group = visual})
	--self:Toggle("UseEditorMenu", callback(self, self, "set_clbk"), BeardLibEditor.Options:GetValue("UseEditorMenu"), {text = "Use BeardLib-Editor menu instead of pause menu(editor mode)"})
	local themes = self:DivGroup("Themes", {group = visual})
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
	self:Button("ResetOptions", callback(self, self, "reset_options"))
end

function EditorOptionsMenu:set_theme(menu, item)
	local theme = item.name
	if theme == "Dark" then
		self:set("AccentColor", Color(0.26, 0.52, 0.93))
		self:set("BackgroundColor", Color(0.4, 0.2, 0.2, 0.2))
	else
		self:set("AccentColor", Color("3b4ffb"))
		self:set("BackgroundColor", Color(0.4, 0.86, 0.86, 0.86))
	end
    QuickMenuPlus:new("Theme has been set, please restart.")
end

function EditorOptionsMenu:reset_options(menu)
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

function EditorOptionsMenu:set_clbk(menu, item)
	self:set(item.name, item:Value())
	if item.name == "LevelsColumns" then
		BeardLibEditor.managers.LoadLevel:load_levels()
	end
end

function EditorOptionsMenu:set(option, value)
	BeardLibEditor.Options:SetValue(option, value)
	BeardLibEditor.Options:Save()
end

function EditorOptionsMenu:open_set_color_dialog(menu, item)
	option = item.name
    BeardLibEditor.managers.ColorDialog:Show({color = BeardLibEditor.Options:GetValue(option), callback = function(color)
    	self:set(option, color)
    end})
end