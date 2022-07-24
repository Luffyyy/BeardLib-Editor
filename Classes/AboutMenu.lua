AboutMenu = AboutMenu or class()
function AboutMenu:init()
	local EMenu = BLE.Menu
	ItemExt:add_funcs(self, EMenu:make_page("About", nil, {align_method = "centered_grid", items_size = 16, scrollbar = false}))
	self:getmenu():Image({
		name = "Logo",
		icon_w = 128,
		icon_h = 128,
		offset = 0,
		texture = "textures/editor_logo",
	})
    local info = self:pan("Info", {w = 700, border_color = BLE.Options:GetValue("AccentColor"), align_method ="centered_grid", offset = 2})
    local function link_button(name, url) return info:button(name, SimpleClbk(os.execute, 'start "" "'..url..'"'), {text = name, size_by_text = true}) end
    local function center_text(text, opt) return info:divider(text, table.merge({color = false, text = text}, opt)) end
    center_text("Created by Luffy and Simon W")
    info:divider("Thanks:", {size = 32, border_left = false, border_bottom = true})
    center_text("Ontrigger and Xeletron for developing the editor further")
    center_text("Soosh for making the icons of the editor and helping developing the editor")
    center_text("Walrus for helping developing the editor from the start and giving information on PD2 mapping")
    center_text("Rex for helping developing the editor, huge help with wiki and making the spawn element model.")
    center_text("Cupcake for helping beginners by making video guides.")
    center_text("Quackertree giving feedback and helping beginners.")
    center_text("TheRealDannyyy, Matthelzor, Sora, Whurrhurr, MiamiCenterPL and more for helping developing the editor")
    info:divider("Links:", {size = 32, border_left = false, border_bottom = true})
    link_button("GitHub", "https://github.com/Luffyyy/BeardLib-Editor")
    link_button("MWS Discord", "https://discord.gg/Eear4JW")
    link_button("PD2Maps Discord", "https://discord.gg/fn62qaq")
    link_button("ModWorkshop", "https://modworkshop.net/mod/16837")
    link_button("Beardlib Wiki", "https://luffyyy.gitbook.io/beardlib/")
    link_button("Editor Wiki", "https://wiki.modworkshop.net/books/beardlib-editor-tutorials")
    link_button("PD2M Guides", "https://payday2maps.net/guides/")
    link_button("Feedback", "https://github.com/Luffyyy/BeardLib-Editor/issues")
end

function AboutMenu:Load(data)

end

function AboutMenu:Destroy()
    return {}
end