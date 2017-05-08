EditorOptionsMenu = EditorOptionsMenu or class()
function EditorOptionsMenu:init()
	local EMenu = BeardLibEditor.managers.Menu
	MenuUtils:new(self, EMenu:make_page("Options"))
	self:Button("AccentColor", callback(self, self, "open_set_color_dialog"))
	self:NumberBox("LevelsColumns", callback(self, self, "set_clbk"), BeardLibEditor.Options:GetValue("LevelsColumns"), {min = 1, floats = 0})
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