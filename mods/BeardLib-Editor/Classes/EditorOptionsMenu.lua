EditorOptionsMenu = EditorOptionsMenu or class()
function EditorOptionsMenu:init()
	local EMenu = BeardLibEditor.managers.Menu
	MenuUtils:new(self, EMenu:make_page("Options"))
	self:Button("AccentColor", callback(self, self, "open_set_color_dialog", "AccentColor"))
end

function EditorOptionsMenu:open_set_color_dialog(option)
    BeardLibEditor.managers.ColorDialog:Show({color = BeardLibEditor.Options:GetValue(option), callback = function(color)
    	BeardLibEditor.Options:SetValue(option, color)
    	BeardLibEditor.Options:Save()
    end})
end