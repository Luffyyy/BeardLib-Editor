AboutMenu = AboutMenu or class()
function AboutMenu:init()
	local EMenu = BeardLibEditor.managers.Menu
	MenuUtils:new(self, EMenu:make_page("About", nil, {scrollbar = false}))
	self:GetMenu():Image({
		name = "Logo",
		icon_w = 256,
		icon_h = 256,
		offset = 0,
		texture = "textures/editor_logo",
	})
    local info = self:Menu("Info", {w = 512, border_color = BeardLibEditor.Options:GetValue("AccentColor"), position = "center_x"})
    local function link_button(name, url) return self:Button(name, callback(nil, os, "execute", 'start "" "'..url..'"'), {text_align = "center", group = info, text = name}) end
    local function center_text(text, opt) return self:Divider(text, table.merge({color = false, group = info, text_align = "center", text = text}, opt or {})) end
    local div = {color = false, border_bottom = true, group = info, border_width = 512, border_center_as_title = true}
    self:Divider("About", div)
    center_text("Created by Luffy and GreatBigBushyBeard")
    center_text("Version " .. BeardLibEditor.Version)
    self:Divider("Credits", div)
    center_text("Walrus - for helping developing the editor from the start and giving information on pd2 mapping")
    center_text("Rex - for helping on testing the dev branch and giving a lot of feedback")
    center_text("Matthelzor - for helping on testing the dev branch")
    center_text("Quackertree - for helping on testing the dev branch")
    center_text("TheRealDannyyy - for helping on testing the dev branch")
    center_text("Nepgearsy - for pushing quick bug fixes in github")
    center_text("And anyone else who helped!")
    self:Divider("Links", div)
    link_button("GitHub", "https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor")
    link_button("ModWorkshop", "https://modworkshop.net/mydownloads.php?action=view_down&did=16837")
    link_button("Guides", "https://modworkshop.net/wiki.php?action=view&id=27")
    link_button("Feedback", "https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues")
end